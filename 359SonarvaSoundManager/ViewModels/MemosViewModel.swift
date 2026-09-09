import Foundation

@MainActor
final class MemosViewModel: ObservableObject {
    private let store: DataStore

    init() {
        self.store = DataStore.shared
    }

    var memos: [AudioMemo] {
        store.memos.sorted { $0.date > $1.date }
    }

    func relatedTitle(for memo: AudioMemo) -> String {
        store.moment(id: memo.relatedTrackId)?.songTitle ?? "Unlinked track"
    }

    func relatedEmoji(for memo: AudioMemo) -> String {
        store.moment(id: memo.relatedTrackId)?.emoji ?? "🎵"
    }

    func save(_ memo: AudioMemo) {
        store.upsertMemo(memo)
    }

    func delete(_ memo: AudioMemo) {
        store.deleteMemo(id: memo.id)
    }
}
