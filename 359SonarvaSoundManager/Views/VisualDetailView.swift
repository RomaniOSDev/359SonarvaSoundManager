import SwiftUI

struct VisualDetailView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var viewModel = VisualsViewModel()
    let collection: VisualCollection

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Image(collection.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color("AppPrimary").opacity(0.4), lineWidth: 1)
                    )
                    .allowsHitTesting(false)

                Text(collection.title)
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color("AppTextPrimary"))

                Text(collection.subtitle)
                    .font(.subheadline)
                    .foregroundColor(Color("AppTextSecondary"))

                NeonButton(
                    title: store.isFavourite(collection.id) ? "Remove favourite" : "Favourite this set",
                    systemImage: store.isFavourite(collection.id) ? "heart.fill" : "heart"
                ) {
                    viewModel.toggleFavourite(collection)
                }

                NavigationLink {
                    MomentEditorView(existing: nil, prefillMood: collection.suggestedMood)
                } label: {
                    Label("Capture in this mood", systemImage: "plus")
                        .font(.headline)
                        .foregroundColor(Color("AppTextPrimary"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color("AppAccent"), Color("AppPrimary")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 10) {
                    Text("CUE NOTES")
                        .font(.caption2.weight(.bold))
                        .tracking(1.3)
                        .foregroundColor(Color("AppAccent"))
                    ForEach(collection.cueNotes, id: \.self) { note in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(Color("AppPrimary"))
                                .frame(width: 7, height: 7)
                                .padding(.top, 6)
                            Text(note)
                                .foregroundColor(Color("AppTextPrimary"))
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("AppSurface"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(18)
        }
        .vinylCanvas()
        .navigationTitle("Collection")
        .studioNavChrome()
    }
}
