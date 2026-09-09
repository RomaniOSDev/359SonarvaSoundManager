import SwiftUI

struct CassetteCard: View {
    let moment: Moment

    var body: some View {
        HStack(spacing: 0) {
            LinearGradient(
                colors: [Color("AppPrimary"), Color("AppAccent")],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 11)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    reel
                    Spacer()
                    if moment.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundColor(Color("AppAccent"))
                    }
                    reel
                }
                .padding(.horizontal, 6)

                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(Color("AppAccent").opacity(0.55), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .frame(height: 56)
                    .overlay {
                        VStack(spacing: 3) {
                            Text(moment.songTitle)
                                .font(.caption.weight(.bold))
                                .foregroundColor(Color("AppTextPrimary"))
                                .lineLimit(1)
                            Text(moment.artistName.isEmpty ? "Unknown artist" : moment.artistName)
                                .font(.caption2)
                                .foregroundColor(Color("AppTextSecondary"))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                    }

                HStack(spacing: 6) {
                    Text(moment.emoji)
                    MoodChip(mood: moment.mood, compact: true)
                    Spacer(minLength: 0)
                    Text("\(moment.listenCount)×")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(Color("AppAccent"))
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color("AppPrimary").opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Color("AppPrimary").opacity(0.22), radius: 8, y: 4)
    }

    private var reel: some View {
        ZStack {
            Circle()
                .fill(Color("AppBackground"))
                .frame(width: 20, height: 20)
            Circle()
                .stroke(Color("AppTextSecondary").opacity(0.7), lineWidth: 1.5)
                .frame(width: 20, height: 20)
            Circle()
                .fill(Color("AppPrimary"))
                .frame(width: 5, height: 5)
        }
    }
}
