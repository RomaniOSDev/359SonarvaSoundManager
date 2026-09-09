import Foundation

struct Moment: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var songTitle: String
    var artistName: String
    var emoji: String
    var description: String
    var mood: ListeningMood
    var createdAt: Date
    var listenCount: Int
    var lastPlayedAt: Date?
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        songTitle: String,
        artistName: String,
        emoji: String,
        description: String,
        mood: ListeningMood = .chill,
        createdAt: Date = Date(),
        listenCount: Int = 0,
        lastPlayedAt: Date? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.songTitle = songTitle
        self.artistName = artistName
        self.emoji = emoji
        self.description = description
        self.mood = mood
        self.createdAt = createdAt
        self.listenCount = listenCount
        self.lastPlayedAt = lastPlayedAt
        self.isPinned = isPinned
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        songTitle = try container.decode(String.self, forKey: .songTitle)
        artistName = try container.decode(String.self, forKey: .artistName)
        emoji = try container.decode(String.self, forKey: .emoji)
        description = try container.decode(String.self, forKey: .description)
        mood = try container.decodeIfPresent(ListeningMood.self, forKey: .mood) ?? .chill
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        listenCount = try container.decodeIfPresent(Int.self, forKey: .listenCount) ?? 0
        lastPlayedAt = try container.decodeIfPresent(Date.self, forKey: .lastPlayedAt)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }
}
