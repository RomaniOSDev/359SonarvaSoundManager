import SwiftUI

struct VinylDiscView: View {
    var diameter: CGFloat = 196
    var isSpinning: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0.95),
                            Color("AppBackground")
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: diameter / 1.8
                    )
                )
            ForEach([0.12, 0.22, 0.32, 0.42, 0.52], id: \.self) { ratio in
                Circle()
                    .stroke(Color.white.opacity(0.07), lineWidth: 1.2)
                    .padding(diameter * ratio)
            }
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color("AppPrimary"), Color("AppAccent")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: diameter * 0.26, height: diameter * 0.26)
                .shadow(color: Color("AppPrimary").opacity(0.7), radius: 10)
            Circle()
                .fill(Color("AppBackground"))
                .frame(width: diameter * 0.07, height: diameter * 0.07)
        }
        .frame(width: diameter, height: diameter)
        .rotationEffect(.degrees(isSpinning ? 360 : 0))
        .animation(isSpinning ? .linear(duration: 8).repeatForever(autoreverses: false) : .default, value: isSpinning)
        .shadow(color: Color("AppPrimary").opacity(0.45), radius: 24)
        .allowsHitTesting(false)
    }
}
