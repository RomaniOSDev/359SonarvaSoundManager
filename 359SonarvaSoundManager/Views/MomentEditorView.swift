import SwiftUI

struct MomentEditorView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MomentsViewModel()

    @State private var workingId: UUID
    @State private var songTitle: String
    @State private var artistName: String
    @State private var emoji: String
    @State private var description: String
    @State private var mood: ListeningMood
    @State private var isPinned: Bool
    @State private var listenCount: Int
    @State private var createdAt: Date
    @State private var lastPlayedAt: Date?
    @State private var showDuplicateAlert = false
    @State private var duplicateMoment: Moment?
    @State private var showValidationAlert = false
    @State private var showDeleteConfirm = false

    private let emojiPalette = ["🎵", "🎶", "🎤", "🎧", "🎸", "🎹", "🥁", "🎷", "🎺", "💿", "📻", "🌙"]

    init(existing: Moment?, prefillMood: ListeningMood? = nil) {
        _workingId = State(initialValue: existing?.id ?? UUID())
        _songTitle = State(initialValue: existing?.songTitle ?? "")
        _artistName = State(initialValue: existing?.artistName ?? "")
        _emoji = State(initialValue: existing?.emoji ?? "🎵")
        _description = State(initialValue: existing?.description ?? "")
        _mood = State(initialValue: existing?.mood ?? prefillMood ?? .chill)
        _isPinned = State(initialValue: existing?.isPinned ?? false)
        _listenCount = State(initialValue: existing?.listenCount ?? 0)
        _createdAt = State(initialValue: existing?.createdAt ?? Date())
        _lastPlayedAt = State(initialValue: existing?.lastPlayedAt)
    }

    private var isSavedMoment: Bool {
        store.moment(id: workingId) != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                NeonField(title: "Song title", text: $songTitle)
                NeonField(title: "Artist", text: $artistName)

                VStack(alignment: .leading, spacing: 8) {
                    Text("MOOD")
                        .font(.caption2.weight(.bold))
                        .tracking(1.3)
                        .foregroundColor(Color("AppAccent"))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ListeningMood.allCases) { item in
                                MoodChip(mood: item, selected: mood == item) {
                                    mood = item
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("EMOJI")
                        .font(.caption2.weight(.bold))
                        .tracking(1.3)
                        .foregroundColor(Color("AppAccent"))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(emojiPalette, id: \.self) { item in
                                Button {
                                    emoji = item
                                } label: {
                                    Text(item)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(emoji == item ? Color("AppPrimary") : Color("AppSurface"))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(Color("AppAccent").opacity(emoji == item ? 0.9 : 0.25), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("SLEEVE NOTES")
                        .font(.caption2.weight(.bold))
                        .tracking(1.3)
                        .foregroundColor(Color("AppAccent"))
                    TextEditor(text: $description)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(Color("AppTextPrimary"))
                        .frame(minHeight: 110)
                        .padding(8)
                        .background(Color("AppSurface"))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color("AppPrimary").opacity(0.4), lineWidth: 1)
                        )
                }

                if isSavedMoment {
                    HStack {
                        Text("\(listenCount) spins")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color("AppTextPrimary"))
                        Spacer()
                        Toggle("Pin in crate", isOn: $isPinned)
                            .tint(Color("AppPrimary"))
                            .foregroundColor(Color("AppTextPrimary"))
                    }
                    .padding(12)
                    .background(Color("AppSurface"))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                NeonButton(title: "Save cassette", systemImage: "opticaldisc.fill", action: saveTapped)

                if isSavedMoment {
                    NeonButton(title: "Spin this now", systemImage: "play.fill") {
                        saveWorking()
                        viewModel.logListen(id: workingId)
                        listenCount += 1
                        lastPlayedAt = Date()
                    }

                    NavigationLink {
                        MemoEditorView(preselectedTrackId: workingId)
                    } label: {
                        Label("Add memo", systemImage: "mic.fill")
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
                            .shadow(color: Color("AppPrimary").opacity(0.45), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete moment", systemImage: "trash")
                            .font(.headline)
                            .foregroundColor(Color("AppTextPrimary"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color("AppSurface"))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color("AppPrimary").opacity(0.5), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
        }
        .vinylCanvas()
        .navigationTitle(isSavedMoment ? "Edit Moment" : "New Moment")
        .studioNavChrome()
        .scrollDismissesKeyboard(.immediately)
        .keyboardDoneButton()
        .alert("Song title needed", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Give this cassette a song title before it can hit the crate.")
        }
        .alert("Moment already exists", isPresented: $showDuplicateAlert) {
            Button("Edit existing") {
                if let duplicateMoment {
                    apply(duplicateMoment)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("A cassette for this song is already in the crate. Open it to edit instead of duplicating.")
        }
        .confirmationDialog(
            "Delete this musical moment?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.delete(currentMoment())
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Linked audio memos for this track will be removed too.")
        }
    }

    private func apply(_ moment: Moment) {
        workingId = moment.id
        songTitle = moment.songTitle
        artistName = moment.artistName
        emoji = moment.emoji
        description = moment.description
        mood = moment.mood
        isPinned = moment.isPinned
        listenCount = moment.listenCount
        createdAt = moment.createdAt
        lastPlayedAt = moment.lastPlayedAt
    }

    private func currentMoment() -> Moment {
        Moment(
            id: workingId,
            songTitle: songTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            artistName: artistName.trimmingCharacters(in: .whitespacesAndNewlines),
            emoji: emoji,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            mood: mood,
            createdAt: createdAt,
            listenCount: listenCount,
            lastPlayedAt: lastPlayedAt,
            isPinned: isPinned
        )
    }

    private func saveWorking() {
        viewModel.save(currentMoment())
    }

    private func saveTapped() {
        let trimmedTitle = songTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            showValidationAlert = true
            return
        }
        if let existing = viewModel.duplicate(ofTitle: trimmedTitle, excluding: workingId) {
            duplicateMoment = existing
            showDuplicateAlert = true
            return
        }
        saveWorking()
        dismiss()
    }
}
