import SwiftUI

struct MomentsListView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var viewModel = MomentsViewModel()
    @State private var momentPendingDelete: Moment?
    @State private var query = ""
    @State private var selectedMood: ListeningMood?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var filtered: [Moment] {
        store.filteredMoments(query: query, mood: selectedMood)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button {
                            selectedMood = nil
                        } label: {
                            Text("All")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(Color("AppTextPrimary"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    selectedMood == nil
                                        ? LinearGradient(colors: [Color("AppPrimary"), Color("AppAccent")], startPoint: .leading, endPoint: .trailing)
                                        : LinearGradient(colors: [Color("AppSurface"), Color("AppSurface")], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        ForEach(ListeningMood.allCases) { mood in
                            MoodChip(mood: mood, compact: true, selected: selectedMood == mood) {
                                selectedMood = selectedMood == mood ? nil : mood
                            }
                        }
                    }
                }

                if store.moments.isEmpty {
                    EmptyStateView(systemImage: "music.note", message: "No musical moments yet")
                    NavigationLink {
                        MomentEditorView(existing: nil)
                    } label: {
                        Label("Capture first cassette", systemImage: "plus")
                            .font(.headline)
                            .foregroundColor(Color("AppTextPrimary"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color("AppPrimary"), Color("AppAccent")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                } else if filtered.isEmpty {
                    EmptyStateView(systemImage: "magnifyingglass", message: "Nothing in the crate matches that filter.")
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filtered) { moment in
                            NavigationLink {
                                MomentEditorView(existing: moment)
                            } label: {
                                CassetteCard(moment: moment)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    viewModel.logListen(id: moment.id)
                                } label: {
                                    Label("Spin now", systemImage: "play.fill")
                                }
                                Button {
                                    viewModel.togglePin(id: moment.id)
                                } label: {
                                    Label(moment.isPinned ? "Unpin" : "Pin", systemImage: moment.isPinned ? "pin.slash" : "pin.fill")
                                }
                                Button(role: .destructive) {
                                    momentPendingDelete = moment
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
        .vinylCanvas()
        .navigationTitle("Musical Moments")
        .studioNavChrome()
        .searchable(text: $query, prompt: "Search the crate")
        .keyboardDoneButton()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    MomentEditorView(existing: nil)
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundColor(Color("AppTextPrimary"))
                        .padding(8)
                        .background(
                            LinearGradient(
                                colors: [Color("AppPrimary"), Color("AppAccent")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .confirmationDialog(
            "Delete this musical moment?",
            isPresented: Binding(
                get: { momentPendingDelete != nil },
                set: { if !$0 { momentPendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let moment = momentPendingDelete {
                    viewModel.delete(moment)
                }
                momentPendingDelete = nil
            }
            Button("Cancel", role: .cancel) {
                momentPendingDelete = nil
            }
        } message: {
            Text("The cassette and any linked memos will be cleared from the booth.")
        }
    }
}
