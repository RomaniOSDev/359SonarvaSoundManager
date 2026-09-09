import SwiftUI

struct VisualsView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var viewModel = VisualsViewModel()
    @State private var pane = 0

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 168)
                    .background {
                        Image("banner_concert")
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color("AppPrimary").opacity(0.4), lineWidth: 1)
                    )
                    .overlay(alignment: .bottomLeading) {
                        Text("MUSIC VISUALS")
                            .font(.caption.weight(.bold))
                            .tracking(1.5)
                            .foregroundColor(Color("AppTextPrimary"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color("AppBackground").opacity(0.72))
                            .clipShape(Capsule())
                            .padding(12)
                    }
                    .allowsHitTesting(false)

                Picker("Pane", selection: $pane) {
                    Text("Collections").tag(0)
                    Text("Favourites").tag(1)
                }
                .pickerStyle(.segmented)
                .colorScheme(.dark)

                if pane == 0 {
                    collectionGrid(viewModel.collections)
                } else if store.favouriteCollections.isEmpty {
                    EmptyStateView(
                        systemImage: "sparkles",
                        message: "Discover musical moments — tap to explore curated visuals!"
                    )
                } else {
                    collectionGrid(store.favouriteCollections)
                }
            }
            .padding(18)
        }
        .vinylCanvas()
        .navigationTitle("Music Visuals")
        .studioNavChrome()
    }

    private func collectionGrid(_ items: [VisualCollection]) -> some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(items) { collection in
                NavigationLink {
                    VisualDetailView(collection: collection)
                } label: {
                    collectionCard(collection)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func collectionCard(_ collection: VisualCollection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(collection.imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 110)
                .clipped()
            Text(collection.title)
                .font(.subheadline.weight(.bold))
                .foregroundColor(Color("AppTextPrimary"))
                .padding(.horizontal, 10)
            Text(collection.subtitle)
                .font(.caption)
                .foregroundColor(Color("AppTextSecondary"))
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color("AppPrimary").opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Color("AppPrimary").opacity(0.22), radius: 8, y: 4)
    }
}
