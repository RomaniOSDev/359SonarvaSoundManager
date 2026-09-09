import Foundation

@MainActor
final class MomentsViewModel: ObservableObject {
    private let store: DataStore

    init() {
        self.store = DataStore.shared
    }

    var moments: [Moment] { store.moments }

    func duplicate(ofTitle title: String, excluding id: UUID?) -> Moment? {
        store.moment(matchingTitle: title, excluding: id)
    }

    func save(_ moment: Moment) {
        store.upsertMoment(moment)
    }

    func delete(_ moment: Moment) {
        store.deleteMoment(id: moment.id)
    }

    func logListen(id: UUID) {
        store.logListen(momentId: id)
    }

    func togglePin(id: UUID) {
        store.togglePin(id: id)
    }
}
