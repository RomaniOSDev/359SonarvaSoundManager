import SwiftUI

struct NeonButton: View {
    let title: String
    let systemImage: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundColor(Color("AppTextPrimary"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: enabled
                            ? [Color("AppPrimary"), Color("AppAccent")]
                            : [Color("AppSurface"), Color("AppSurface")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: enabled ? Color("AppPrimary").opacity(0.55) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.55)
    }
}

struct NeonField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1.3)
                .foregroundColor(Color("AppAccent"))
            TextField("", text: $text)
                .foregroundColor(Color("AppTextPrimary"))
                .padding(12)
                .background(Color("AppSurface"))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color("AppPrimary").opacity(0.4), lineWidth: 1)
                )
        }
    }
}

struct MoodChip: View {
    let mood: ListeningMood
    var compact: Bool = false
    var selected: Bool = true
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let action {
                Button(action: action) { chip }.buttonStyle(.plain)
            } else {
                chip
            }
        }
    }

    private var chip: some View {
        HStack(spacing: 4) {
            Image(systemName: mood.symbol)
            Text(mood.title)
        }
        .font(compact ? .caption2.weight(.bold) : .caption.weight(.semibold))
        .foregroundColor(Color("AppTextPrimary"))
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 4 : 8)
        .background(
            selected
                ? LinearGradient(colors: [Color("AppPrimary"), Color("AppAccent")], startPoint: .leading, endPoint: .trailing)
                : LinearGradient(colors: [Color("AppSurface"), Color("AppSurface")], startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color("AppPrimary").opacity(selected ? 0.9 : 0.35), lineWidth: 1)
        )
    }
}

struct StudioCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("AppSurface"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color("AppPrimary").opacity(0.3), lineWidth: 1)
            )
    }
}

