//
//  DeferredLaunchCanvas.swift
//

import SwiftUI

struct DeferredLaunchCanvas: View {
    @ObservedObject var state: LaunchStagingState

    @State private var spinDegrees: Double = 0
    @State private var pulse = false
    @State private var barPhase = false
    @State private var glowBreath = false

    private var clampedProgress: Double { min(1.0, max(0.05, state.progress)) }

    private let barHeights: [CGFloat] = [18, 32, 24, 40, 28, 36, 22, 30]

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color("AppPrimary").opacity(glowBreath ? 0.28 : 0.12))
                        .frame(width: 220, height: 220)
                        .blur(radius: 28)
                        .scaleEffect(pulse ? 1.08 : 0.92)

                    Circle()
                        .stroke(Color("AppPrimary").opacity(0.22), lineWidth: 3)
                        .frame(width: 168, height: 168)

                    Circle()
                        .trim(from: 0, to: CGFloat(clampedProgress))
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color("AppPrimary"),
                                    Color("AppAccent"),
                                    Color("AppPrimary")
                                ],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 168, height: 168)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.35), value: clampedProgress)
                        .shadow(color: Color("AppPrimary").opacity(0.65), radius: 10)

                    stagingVinylDisc
                        .rotationEffect(.degrees(spinDegrees))

                    Text("\(Int(clampedProgress * 100))%")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Color("AppTextPrimary"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color("AppBackground").opacity(0.72))
                        .clipShape(Capsule())
                        .offset(y: 78)
                }
                .frame(height: 210)

                equalizerBars

                Text(state.statusMessage)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color("AppTextPrimary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .opacity(pulse ? 1 : 0.72)
                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)

                Spacer()
                    .frame(height: 88)
            }
        }
        .onAppear {
            pulse = true
            glowBreath = true
            barPhase = true
            withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) {
                spinDegrees = 360
            }
        }
    }

    private var stagingVinylDisc: some View {
        let diameter: CGFloat = 132
        return ZStack {
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
        .shadow(color: Color("AppPrimary").opacity(0.45), radius: 24)
        .allowsHitTesting(false)
    }

    private var backgroundLayer: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            Image("bg_vinyl")
                .resizable()
                .scaledToFill()
                .opacity(0.28)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color("AppPrimary").opacity(0.22),
                    Color.clear,
                    Color("AppAccent").opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color("AppPrimary").opacity(0.35), Color.clear],
                center: .center,
                startRadius: 20,
                endRadius: 320
            )
            .ignoresSafeArea()
            .scaleEffect(glowBreath ? 1.15 : 0.9)
            .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: glowBreath)
        }
    }

    private var equalizerBars: some View {
        HStack(alignment: .bottom, spacing: 7) {
            ForEach(Array(barHeights.enumerated()), id: \.offset) { index, base in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color("AppPrimary"), Color("AppAccent")],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 7, height: barPhase ? base : base * 0.35)
                    .shadow(color: Color("AppPrimary").opacity(0.45), radius: 4, y: 1)
                    .animation(
                        .easeInOut(duration: 0.45 + Double(index) * 0.07)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.05),
                        value: barPhase
                    )
            }
        }
        .frame(height: 44)
    }
}

#Preview("Staging — idle") {
    DeferredLaunchCanvas(state: {
        let state = LaunchStagingState()
        state.progress = 0.12
        state.statusMessage = LaunchStagingState.defaultStatusMessage
        return state
    }())
}

#Preview("Staging — mid") {
    DeferredLaunchCanvas(state: {
        let state = LaunchStagingState()
        state.progress = 0.58
        state.statusMessage = "Tuning the signal..."
        return state
    }())
}

#Preview("Staging — almost done") {
    DeferredLaunchCanvas(state: {
        let state = LaunchStagingState()
        state.progress = 0.92
        state.statusMessage = "Almost ready..."
        return state
    }())
}
