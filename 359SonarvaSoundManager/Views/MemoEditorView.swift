import SwiftUI

struct MemoEditorView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MemosViewModel()

    @State private var editingId: UUID
    @State private var relatedTrackId: UUID?
    @State private var caption: String
    @State private var date: Date
    @State private var showValidationAlert = false
    @State private var showDeleteConfirm = false
    @State private var isExisting: Bool

    init(existing: AudioMemo? = nil, preselectedTrackId: UUID? = nil) {
        _editingId = State(initialValue: existing?.id ?? UUID())
        _relatedTrackId = State(initialValue: existing?.relatedTrackId ?? preselectedTrackId)
        _caption = State(initialValue: existing?.caption ?? "")
        _date = State(initialValue: existing?.date ?? Date())
        _isExisting = State(initialValue: existing != nil)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if store.moments.isEmpty {
                    EmptyStateView(
                        systemImage: "music.note",
                        message: "Cue a musical moment first, then attach a memo to the track."
                    )
                    NavigationLink {
                        MomentEditorView(existing: nil)
                    } label: {
                        Label("Create moment", systemImage: "plus")
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
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("RELATED TRACK")
                            .font(.caption2.weight(.bold))
                            .tracking(1.3)
                            .foregroundColor(Color("AppAccent"))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(store.moments) { moment in
                                    Button {
                                        relatedTrackId = moment.id
                                    } label: {
                                        Text("\(moment.emoji)  \(moment.songTitle)")
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(Color("AppTextPrimary"))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                            .background(
                                                relatedTrackId == moment.id
                                                    ? LinearGradient(
                                                        colors: [Color("AppPrimary"), Color("AppAccent")],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                    : LinearGradient(
                                                        colors: [Color("AppSurface"), Color("AppSurface")],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                            )
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color("AppPrimary").opacity(0.45), lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("CAPTION")
                            .font(.caption2.weight(.bold))
                            .tracking(1.3)
                            .foregroundColor(Color("AppAccent"))
                        TextEditor(text: $caption)
                            .scrollContentBackground(.hidden)
                            .foregroundColor(Color("AppTextPrimary"))
                            .frame(minHeight: 140)
                            .padding(8)
                            .background(Color("AppSurface"))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color("AppPrimary").opacity(0.4), lineWidth: 1)
                            )
                    }

                    DatePicker("Captured", selection: $date)
                        .datePickerStyle(.compact)
                        .tint(Color("AppPrimary"))
                        .foregroundColor(Color("AppTextPrimary"))
                        .padding(12)
                        .background(Color("AppSurface"))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .colorScheme(.dark)

                    NeonButton(title: "Save memo", systemImage: "square.and.pencil", action: saveTapped)

                    if isExisting {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete memo", systemImage: "trash")
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
            }
            .padding(18)
        }
        .vinylCanvas()
        .navigationTitle(isExisting ? "Edit Memo" : "New Memo")
        .studioNavChrome()
        .scrollDismissesKeyboard(.immediately)
        .keyboardDoneButton()
        .onAppear {
            if relatedTrackId == nil {
                relatedTrackId = store.moments.first?.id
            }
        }
        .alert("Memo incomplete", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Pick a related track and write a caption before saving.")
        }
        .confirmationDialog("Delete this memo?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                viewModel.delete(
                    AudioMemo(
                        id: editingId,
                        relatedTrackId: relatedTrackId ?? UUID(),
                        caption: caption,
                        date: date
                    )
                )
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func saveTapped() {
        let trimmed = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let relatedTrackId, !trimmed.isEmpty else {
            showValidationAlert = true
            return
        }
        viewModel.save(
            AudioMemo(
                id: editingId,
                relatedTrackId: relatedTrackId,
                caption: trimmed,
                date: date
            )
        )
        dismiss()
    }
}
