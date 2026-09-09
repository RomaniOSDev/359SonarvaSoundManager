import SwiftUI

struct NowPlayingBar: View {
    let moment: Moment?

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(Color("AppPrimary"))
                .frame(width: 10, height: 10)
                .shadow(color: Color("AppPrimary"), radius: 6)

            VStack(alignment: .leading, spacing: 3) {
                Text("NOW PLAYING")
                    .font(.caption2.weight(.bold))
                    .tracking(1.6)
                    .foregroundColor(Color("AppAccent"))
                if let moment {
                    NavigationLink {
                        MomentEditorView(existing: moment)
                    } label: {
                        Text("\(moment.emoji)  \(moment.songTitle) — \(moment.artistName.isEmpty ? "Unknown" : moment.artistName)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color("AppTextPrimary"))
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Needle up — cue a musical moment")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color("AppTextSecondary"))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            NavigationLink {
                SettingsView()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color("AppTextPrimary"))
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(
                            colors: [Color("AppPrimary"), Color("AppAccent")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: Color("AppPrimary").opacity(0.6), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color("AppPrimary").opacity(0.45), lineWidth: 1)
        )
        .shadow(color: Color("AppPrimary").opacity(0.28), radius: 10, y: 4)
    }
}
