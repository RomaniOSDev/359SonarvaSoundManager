import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: DataStore
    @State private var showResetConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                settingsRow(title: "Load sample crate", systemImage: "opticaldisc.fill") {
                    store.loadSampleCrate()
                }
                settingsRow(title: "Rate Us", systemImage: "star.fill") {
                    AppLinks.requestReview()
                }
                settingsRow(title: "Privacy", systemImage: "hand.raised.fill") {
                    AppLinks.open(AppLinks.privacy)
                }
                settingsRow(title: "Terms", systemImage: "doc.text.fill") {
                    AppLinks.open(AppLinks.terms)
                }
                settingsRow(title: "Reset", systemImage: "arrow.counterclockwise") {
                    showResetConfirm = true
                }
            }
            .padding(18)
        }
        .vinylCanvas()
        .navigationTitle("Settings")
        .studioNavChrome()
        .confirmationDialog("Reset all local data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Reset", role: .destructive) {
                store.resetAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Moments, memos, and favourite collections will be cleared from this device.")
        }
    }

    private func settingsRow(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundColor(Color("AppTextPrimary"))
                    .frame(width: 36, height: 36)
                    .background(
                        LinearGradient(
                            colors: [Color("AppPrimary"), Color("AppAccent")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color("AppTextPrimary"))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color("AppTextSecondary"))
            }
            .padding(14)
            .background(Color("AppSurface"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color("AppPrimary").opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
