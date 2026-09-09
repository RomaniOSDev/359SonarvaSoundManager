import Foundation

@MainActor
final class VisualsViewModel: ObservableObject {
    private let store: DataStore

    init() {
        self.store = DataStore.shared
    }

    var collections: [VisualCollection] { VisualCollection.catalog }

    var favourites: [VisualCollection] { store.favouriteCollections }

    func isFavourite(_ collection: VisualCollection) -> Bool {
        store.isFavourite(collection.id)
    }

    func toggleFavourite(_ collection: VisualCollection) {
        store.toggleFavourite(collection.id)
    }
}
