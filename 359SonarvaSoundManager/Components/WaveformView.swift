import SwiftUI

struct WaveformView: View {
    var isLive: Bool = false

    private let heights: [CGFloat] = [10, 18, 28, 14, 32, 20, 12, 26, 16, 30, 11, 22, 17, 34, 13, 24, 29, 15, 21, 19]
    @State private var pulse = false

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(Array(heights.enumerated()), id: \.offset) { index, height in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color("AppPrimary"), Color("AppAccent")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 5, height: barHeight(index: index, base: height))
            }
        }
        .onAppear {
            guard isLive else { return }
            withAnimation(.easeInOut(duration: 0.42).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .allowsHitTesting(false)
    }

    private func barHeight(index: Int, base: CGFloat) -> CGFloat {
        guard isLive else { return base }
        let offset = index.isMultiple(of: 2) ? 0.72 : 1.18
        return pulse ? base * offset : base
    }
}
