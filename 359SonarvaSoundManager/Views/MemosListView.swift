import SwiftUI

struct MemosListView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var viewModel = MemosViewModel()
    @State private var memoPendingDelete: AudioMemo?
    @State private var query = ""

    private var visibleMemos: [AudioMemo] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return viewModel.memos }
        return viewModel.memos.filter { memo in
            memo.caption.lowercased().contains(needle)
                || viewModel.relatedTitle(for: memo).lowercased().contains(needle)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if store.memos.isEmpty {
                    EmptyStateView(
                        systemImage: "pencil.circle",
                        message: "Add your first audio memo and capture the moment."
                    )
                } else if visibleMemos.isEmpty {
                    EmptyStateView(
                        systemImage: "magnifyingglass",
                        message: "No memos match that search."
                    )
                } else {
                    ForEach(visibleMemos) { memo in
                        NavigationLink {
                            MemoEditorView(existing: memo)
                        } label: {
                            memoRow(memo)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                memoPendingDelete = memo
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
        .vinylCanvas()
        .navigationTitle("Audio Memos")
        .studioNavChrome()
        .searchable(text: $query, prompt: "Search memos")
        .keyboardDoneButton()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    MemoEditorView()
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
            "Delete this memo?",
            isPresented: Binding(
                get: { memoPendingDelete != nil },
                set: { if !$0 { memoPendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let memo = memoPendingDelete {
                    viewModel.delete(memo)
                }
                memoPendingDelete = nil
            }
            Button("Cancel", role: .cancel) {
                memoPendingDelete = nil
            }
        }
    }

    private func memoRow(_ memo: AudioMemo) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color("AppSurface"))
                    .frame(width: 44, height: 44)
                Text(viewModel.relatedEmoji(for: memo))
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.relatedTitle(for: memo))
                    .font(.headline)
                    .foregroundColor(Color("AppTextPrimary"))
                Text(memo.caption)
                    .font(.subheadline)
                    .foregroundColor(Color("AppTextSecondary"))
                    .lineLimit(3)
                Text(memo.date, style: .date)
                    .font(.caption)
                    .foregroundColor(Color("AppAccent"))
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color("AppPrimary").opacity(0.3), lineWidth: 1)
        )
    }
}
