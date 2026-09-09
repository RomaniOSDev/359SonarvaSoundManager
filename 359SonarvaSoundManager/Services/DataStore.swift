import Foundation

@MainActor
final class DataStore: ObservableObject {
    static let shared = DataStore()

    @Published private(set) var moments: [Moment] = []
    @Published private(set) var memos: [AudioMemo] = []
    @Published private(set) var favouriteCollectionIDs: [UUID] = []
    @Published private(set) var listenLogs: [ListenLog] = []

    private let defaultsKey = "sonarva.journal.v2"
    private let legacyKey = "sonarva.journal.v1"
    private let clearedKey = "sonarva.userCleared"

    private init() {
        load()
    }

    var latestMoment: Moment? {
        if let last = listenLogs.max(by: { $0.playedAt < $1.playedAt }) {
            return moment(id: last.momentId) ?? moments.first
        }
        return moments.first
    }

    var sortedMoments: [Moment] {
        moments.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            let left = lhs.lastPlayedAt ?? lhs.createdAt
            let right = rhs.lastPlayedAt ?? rhs.createdAt
            return left > right
        }
    }

    var listensToday: Int {
        listenLogs.filter { Calendar.current.isDateInToday($0.playedAt) }.count
    }

    var currentStreak: Int {
        let days = Set(listenLogs.map { Calendar.current.startOfDay(for: $0.playedAt) })
        guard !days.isEmpty else { return 0 }
        var streak = 0
        var cursor = Calendar.current.startOfDay(for: Date())
        if !days.contains(cursor) {
            guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        while days.contains(cursor) {
            streak += 1
            guard let previous = Calendar.current.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    var tonightCue: Moment? {
        guard !moments.isEmpty else { return nil }
        return moments.min { lhs, rhs in
            let left = lhs.lastPlayedAt ?? .distantPast
            let right = rhs.lastPlayedAt ?? .distantPast
            if left == right { return lhs.listenCount < rhs.listenCount }
            return left < right
        }
    }

    func moment(id: UUID) -> Moment? {
        moments.first { $0.id == id }
    }

    func moment(matchingTitle title: String, excluding id: UUID?) -> Moment? {
        let needle = Self.normalizedTitle(title)
        guard !needle.isEmpty else { return nil }
        return moments.first { candidate in
            if let id, candidate.id == id { return false }
            return Self.normalizedTitle(candidate.songTitle) == needle
        }
    }

    func filteredMoments(query: String, mood: ListeningMood?) -> [Moment] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return sortedMoments.filter { moment in
            if let mood, moment.mood != mood { return false }
            if needle.isEmpty { return true }
            return moment.songTitle.lowercased().contains(needle)
                || moment.artistName.lowercased().contains(needle)
                || moment.description.lowercased().contains(needle)
        }
    }

    func upsertMoment(_ moment: Moment) {
        if let index = moments.firstIndex(where: { $0.id == moment.id }) {
            moments[index] = moment
        } else {
            moments.insert(moment, at: 0)
        }
        persist()
        Haptics.save()
    }

    func deleteMoment(id: UUID) {
        moments.removeAll { $0.id == id }
        memos.removeAll { $0.relatedTrackId == id }
        listenLogs.removeAll { $0.momentId == id }
        persist()
    }

    func togglePin(id: UUID) {
        guard let index = moments.firstIndex(where: { $0.id == id }) else { return }
        moments[index].isPinned.toggle()
        persist()
        Haptics.favourite()
    }

    func logListen(momentId: UUID, at date: Date = Date()) {
        guard let index = moments.firstIndex(where: { $0.id == momentId }) else { return }
        moments[index].listenCount += 1
        moments[index].lastPlayedAt = date
        listenLogs.insert(ListenLog(momentId: momentId, playedAt: date), at: 0)
        persist()
        Haptics.play()
    }

    func memos(forTrackId trackId: UUID) -> [AudioMemo] {
        memos.filter { $0.relatedTrackId == trackId }.sorted { $0.date > $1.date }
    }

    func upsertMemo(_ memo: AudioMemo) {
        if let index = memos.firstIndex(where: { $0.id == memo.id }) {
            memos[index] = memo
        } else {
            memos.insert(memo, at: 0)
        }
        persist()
        Haptics.save()
    }

    func deleteMemo(id: UUID) {
        memos.removeAll { $0.id == id }
        persist()
    }

    func isFavourite(_ collectionID: UUID) -> Bool {
        favouriteCollectionIDs.contains(collectionID)
    }

    func toggleFavourite(_ collectionID: UUID) {
        if let index = favouriteCollectionIDs.firstIndex(of: collectionID) {
            favouriteCollectionIDs.remove(at: index)
        } else {
            favouriteCollectionIDs.insert(collectionID, at: 0)
        }
        persist()
        Haptics.favourite()
    }

    var favouriteCollections: [VisualCollection] {
        favouriteCollectionIDs.compactMap { VisualCollection.collection(id: $0) }
    }

    func listens(inLastDays days: Int) -> [ListenLog] {
        guard let start = Calendar.current.date(byAdding: .day, value: -(days - 1), to: Calendar.current.startOfDay(for: Date())) else {
            return listenLogs
        }
        return listenLogs.filter { $0.playedAt >= start }
    }

    func dailyListenCounts(days: Int) -> [(day: Date, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let logs = listens(inLastDays: days)
        return (0..<days).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let count = logs.filter { calendar.isDate($0.playedAt, inSameDayAs: day) }.count
            return (day, count)
        }
    }

    func moodCounts() -> [(mood: ListeningMood, count: Int)] {
        ListeningMood.allCases.map { mood in
            (mood, moments.filter { $0.mood == mood }.count)
        }
    }

    func memoDailyCounts(days: Int) -> [(day: Date, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<days).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let count = memos.filter { calendar.isDate($0.date, inSameDayAs: day) }.count
            return (day, count)
        }
    }

    var topArtists: [(name: String, count: Int)] {
        var bucket: [String: Int] = [:]
        for moment in moments {
            let name = moment.artistName.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = name.isEmpty ? "Unknown" : name
            bucket[key, default: 0] += max(moment.listenCount, 1)
        }
        return bucket.map { ($0.key, $0.value) }.sorted { $0.count > $1.count }
    }

    var mostSpun: Moment? {
        moments.max { $0.listenCount < $1.listenCount }
    }

    func resetAll() {
        moments = []
        memos = []
        favouriteCollectionIDs = []
        listenLogs = []
        UserDefaults.standard.set(true, forKey: clearedKey)
        persist()
    }

    func loadSampleCrate() {
        UserDefaults.standard.set(false, forKey: clearedKey)
        let sample = Self.makeSampleCrate()
        for item in sample.moments where self.moment(matchingTitle: item.songTitle, excluding: nil) == nil {
            moments.insert(item, at: 0)
        }
        let knownIDs = Set(moments.map(\.id))
        for memo in sample.memos where knownIDs.contains(memo.relatedTrackId) && !memos.contains(where: { $0.id == memo.id }) {
            memos.insert(memo, at: 0)
        }
        for log in sample.logs where knownIDs.contains(log.momentId) && !listenLogs.contains(where: { $0.id == log.id }) {
            listenLogs.insert(log, at: 0)
        }
        persist()
        Haptics.save()
    }

    private struct Snapshot: Codable {
        var moments: [Moment]
        var memos: [AudioMemo]
        var favouriteCollectionIDs: [UUID]
        var listenLogs: [ListenLog]

        init(
            moments: [Moment],
            memos: [AudioMemo],
            favouriteCollectionIDs: [UUID],
            listenLogs: [ListenLog]
        ) {
            self.moments = moments
            self.memos = memos
            self.favouriteCollectionIDs = favouriteCollectionIDs
            self.listenLogs = listenLogs
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            moments = try container.decodeIfPresent([Moment].self, forKey: .moments) ?? []
            memos = try container.decodeIfPresent([AudioMemo].self, forKey: .memos) ?? []
            favouriteCollectionIDs = try container.decodeIfPresent([UUID].self, forKey: .favouriteCollectionIDs) ?? []
            listenLogs = try container.decodeIfPresent([ListenLog].self, forKey: .listenLogs) ?? []
        }
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        if let data = UserDefaults.standard.data(forKey: defaultsKey) ?? UserDefaults.standard.data(forKey: legacyKey),
           let snapshot = try? decoder.decode(Snapshot.self, from: data) {
            moments = snapshot.moments
            memos = snapshot.memos
            favouriteCollectionIDs = snapshot.favouriteCollectionIDs
            listenLogs = snapshot.listenLogs
        }
        seedIfNeeded()
    }

    private func seedIfNeeded() {
        guard moments.isEmpty, memos.isEmpty, listenLogs.isEmpty else { return }
        guard !UserDefaults.standard.bool(forKey: clearedKey) else { return }
        let sample = Self.makeSampleCrate()
        moments = sample.moments
        memos = sample.memos
        listenLogs = sample.logs
        persist()
    }

    private func persist() {
        let snapshot = Snapshot(
            moments: moments,
            memos: memos,
            favouriteCollectionIDs: favouriteCollectionIDs,
            listenLogs: listenLogs
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        if let data = try? encoder.encode(snapshot) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    static func normalizedTitle(_ title: String) -> String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private struct SamplePayload {
        var moments: [Moment]
        var memos: [AudioMemo]
        var logs: [ListenLog]
    }

    private static func makeSampleCrate() -> SamplePayload {
        let calendar = Calendar.current
        func stamp(_ daysAgo: Int, hour: Int, minute: Int = 12) -> Date {
            let base = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }

        let nightDrive = UUID(uuidString: "B21C0001-0000-4000-8000-000000000001")!
        let glassHouse = UUID(uuidString: "B21C0001-0000-4000-8000-000000000002")!
        let magenta = UUID(uuidString: "B21C0001-0000-4000-8000-000000000003")!
        let lowTide = UUID(uuidString: "B21C0001-0000-4000-8000-000000000004")!
        let wireframe = UUID(uuidString: "B21C0001-0000-4000-8000-000000000005")!
        let afterglow = UUID(uuidString: "B21C0001-0000-4000-8000-000000000006")!
        let staticRoom = UUID(uuidString: "B21C0001-0000-4000-8000-000000000007")!
        let lastCall = UUID(uuidString: "B21C0001-0000-4000-8000-000000000008")!

        let moments: [Moment] = [
            Moment(id: nightDrive, songTitle: "Night Drive Loop", artistName: "Kite District", emoji: "🌙", description: "Bass stays under the engine noise. City lights smear on the windshield.", mood: .night, createdAt: stamp(12, hour: 23), listenCount: 5, lastPlayedAt: stamp(0, hour: 22), isPinned: true),
            Moment(id: glassHouse, songTitle: "Glasshouse", artistName: "Vera Lin", emoji: "🎧", description: "Clean guitar, lots of air. Good for writing.", mood: .focus, createdAt: stamp(10, hour: 9), listenCount: 4, lastPlayedAt: stamp(1, hour: 8)),
            Moment(id: magenta, songTitle: "Magenta Floor", artistName: "Pulse Room", emoji: "🎤", description: "The drop still knocks. Crowd tape in the last chorus.", mood: .hype, createdAt: stamp(9, hour: 21), listenCount: 6, lastPlayedAt: stamp(0, hour: 19), isPinned: true),
            Moment(id: lowTide, songTitle: "Low Tide", artistName: "Harbour Pale", emoji: "💿", description: "Slow reverb, rain on the booth window.", mood: .blue, createdAt: stamp(8, hour: 18), listenCount: 3, lastPlayedAt: stamp(2, hour: 21)),
            Moment(id: wireframe, songTitle: "Wireframe", artistName: "Nucleus", emoji: "🎹", description: "Arp that refuses to resolve. Keep it looping.", mood: .focus, createdAt: stamp(7, hour: 11), listenCount: 4, lastPlayedAt: stamp(1, hour: 14)),
            Moment(id: afterglow, songTitle: "Afterglow Waltz", artistName: "June Static", emoji: "🎷", description: "Late set closer. Leave the needle in.", mood: .chill, createdAt: stamp(6, hour: 20), listenCount: 3, lastPlayedAt: stamp(3, hour: 22)),
            Moment(id: staticRoom, songTitle: "Static Room", artistName: "Cobalt Echo", emoji: "📻", description: "Tape hiss is part of the arrangement.", mood: .night, createdAt: stamp(4, hour: 1), listenCount: 2, lastPlayedAt: stamp(4, hour: 1)),
            Moment(id: lastCall, songTitle: "Last Call Lights", artistName: "Neon Harbour", emoji: "🎺", description: "Brass over a packed floor, then the house lights.", mood: .live, createdAt: stamp(3, hour: 23), listenCount: 3, lastPlayedAt: stamp(0, hour: 23))
        ]

        let memos: [AudioMemo] = [
            AudioMemo(id: UUID(uuidString: "C31C0001-0000-4000-8000-000000000001")!, relatedTrackId: nightDrive, caption: "Second verse hits harder with the window cracked. Keep this as the booth closer.", date: stamp(0, hour: 22, minute: 40)),
            AudioMemo(id: UUID(uuidString: "C31C0001-0000-4000-8000-000000000002")!, relatedTrackId: magenta, caption: "Crowd clap on the four. Do not clean it up.", date: stamp(0, hour: 19, minute: 18)),
            AudioMemo(id: UUID(uuidString: "C31C0001-0000-4000-8000-000000000003")!, relatedTrackId: glassHouse, caption: "Wrote the first page of notes under this. Leave the metronome off next time.", date: stamp(1, hour: 8, minute: 44)),
            AudioMemo(id: UUID(uuidString: "C31C0001-0000-4000-8000-000000000004")!, relatedTrackId: lowTide, caption: "Rain against the glass lined up with the snare. Accidental, keep it.", date: stamp(2, hour: 21, minute: 5)),
            AudioMemo(id: UUID(uuidString: "C31C0001-0000-4000-8000-000000000005")!, relatedTrackId: lastCall, caption: "Brass smear at 2:14 is the whole night.", date: stamp(3, hour: 23, minute: 50))
        ]

        let logs: [ListenLog] = [
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-000000000001")!, momentId: nightDrive, playedAt: stamp(0, hour: 22)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-000000000002")!, momentId: magenta, playedAt: stamp(0, hour: 19)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-000000000003")!, momentId: lastCall, playedAt: stamp(0, hour: 23)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-000000000004")!, momentId: glassHouse, playedAt: stamp(1, hour: 8)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-000000000005")!, momentId: wireframe, playedAt: stamp(1, hour: 14)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-000000000006")!, momentId: nightDrive, playedAt: stamp(1, hour: 23)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-000000000007")!, momentId: lowTide, playedAt: stamp(2, hour: 21)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-000000000008")!, momentId: magenta, playedAt: stamp(2, hour: 20)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-000000000009")!, momentId: afterglow, playedAt: stamp(3, hour: 22)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-00000000000A")!, momentId: lastCall, playedAt: stamp(3, hour: 23)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-00000000000B")!, momentId: staticRoom, playedAt: stamp(4, hour: 1)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-00000000000C")!, momentId: nightDrive, playedAt: stamp(4, hour: 23, minute: 40)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-00000000000D")!, momentId: glassHouse, playedAt: stamp(5, hour: 9)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-00000000000E")!, momentId: magenta, playedAt: stamp(5, hour: 21)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-00000000000F")!, momentId: wireframe, playedAt: stamp(6, hour: 11)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-000000000010")!, momentId: afterglow, playedAt: stamp(6, hour: 20)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-000000000011")!, momentId: lowTide, playedAt: stamp(7, hour: 18)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-000000000012")!, momentId: magenta, playedAt: stamp(7, hour: 22)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-000000000013")!, momentId: nightDrive, playedAt: stamp(8, hour: 0)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-000000000014")!, momentId: lastCall, playedAt: stamp(8, hour: 23)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-000000000015")!, momentId: glassHouse, playedAt: stamp(9, hour: 10)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-000000000016")!, momentId: wireframe, playedAt: stamp(9, hour: 16)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-000000000017")!, momentId: magenta, playedAt: stamp(10, hour: 21)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-000000000018")!, momentId: nightDrive, playedAt: stamp(11, hour: 23)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-000000000019")!, momentId: afterglow, playedAt: stamp(12, hour: 20)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-00000000001A")!, momentId: glassHouse, playedAt: stamp(12, hour: 9)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-00000000001B")!, momentId: wireframe, playedAt: stamp(7, hour: 15)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-00000000001C")!, momentId: lowTide, playedAt: stamp(8, hour: 19)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-00000000001D")!, momentId: staticRoom, playedAt: stamp(10, hour: 2)),
            ListenLog(id: UUID(uuidString: "D41C0001-0000-4000-8000-00000000001E")!, momentId: magenta, playedAt: stamp(9, hour: 21))
        ]

        return SamplePayload(moments: moments, memos: memos, logs: logs)
    }
}
