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
    private let debugHorizontalInset: CGFloat = 24

    var body: some View {
        ZStack {
            backgroundLayer
                .ignoresSafeArea()
                .allowsHitTesting(false)

            GeometryReader { geo in
                VStack(spacing: 16) {
                    Spacer(minLength: 8)

                    progressCluster
                        .frame(height: state.showDebugPanel ? 140 : 170)

                    if !state.showDebugPanel {
                        equalizerBars
                    }

                    Text(state.statusMessage)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color("AppTextPrimary"))
                        .multilineTextAlignment(.center)
                        .opacity(pulse ? 1 : 0.72)
                        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)

                    if state.showDebugPanel {
                        debugPanel
                            .frame(maxHeight: max(160, geo.size.height * 0.48))
                    }

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, debugHorizontalInset)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
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

    private var progressCluster: some View {
        ZStack {
            Circle()
                .fill(Color("AppPrimary").opacity(glowBreath ? 0.28 : 0.12))
                .frame(width: 160, height: 160)
                .blur(radius: 28)
                .scaleEffect(pulse ? 1.08 : 0.92)

            Circle()
                .stroke(Color("AppPrimary").opacity(0.22), lineWidth: 3)
                .frame(width: 120, height: 120)

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
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: clampedProgress)
                .shadow(color: Color("AppPrimary").opacity(0.65), radius: 10)

            stagingVinylDisc
                .rotationEffect(.degrees(spinDegrees))

            Text("\(Int(clampedProgress * 100))%")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(Color("AppTextPrimary"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color("AppBackground").opacity(0.72))
                .clipShape(Capsule())
                .offset(y: 58)
        }
    }

    private var stagingVinylDisc: some View {
        let diameter: CGFloat = 96
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

            Image("bg_vinyl")
                .resizable()
                .scaledToFill()
                .opacity(0.28)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()

            LinearGradient(
                colors: [
                    Color("AppPrimary").opacity(0.22),
                    Color.clear,
                    Color("AppAccent").opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color("AppPrimary").opacity(0.35), Color.clear],
                center: .center,
                startRadius: 20,
                endRadius: 320
            )
            .scaleEffect(glowBreath ? 1.15 : 0.9)
            .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: glowBreath)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
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

    private var debugPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("DEBUG LaunchFlow")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color("AppAccent"))

                if !state.debugAttemptLabel.isEmpty {
                    debugBlock(title: "Attempt", body: state.debugAttemptLabel)
                }
                debugBlock(
                    title: "AppsFlyer conversion",
                    body: state.debugConversionDump.isEmpty ? "(waiting…)" : state.debugConversionDump
                )
                debugBlock(
                    title: "Final entry URL (probe)",
                    body: state.debugEntryURL.isEmpty ? "(waiting…)" : state.debugEntryURL
                )
                debugBlock(
                    title: "Probe result",
                    body: state.debugProbeStatus.isEmpty ? "(waiting…)" : state.debugProbeStatus
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func debugBlock(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Color("AppPrimary"))
            Text(Self.softWrap(body))
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.92))
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }

    /// Inserts zero-width spaces so long URLs wrap inside the padded panel.
    private static func softWrap(_ text: String) -> String {
        text
            .replacingOccurrences(of: "/", with: "/\u{200B}")
            .replacingOccurrences(of: "?", with: "?\u{200B}")
            .replacingOccurrences(of: "&", with: "&\u{200B}")
            .replacingOccurrences(of: "=", with: "=\u{200B}")
            .replacingOccurrences(of: "_", with: "_\u{200B}")
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

#Preview("Staging — debug") {
    DeferredLaunchCanvas(state: {
        let state = LaunchStagingState()
        state.progress = 1
        state.showDebugPanel = true
        state.statusMessage = "Probe failed — holding (debug)"
        state.debugAttemptLabel = "AF attempt 2/2 (timeout 20s)"
        state.debugConversionDump = "af_status = Organic\naf_message = organic install"
        state.debugEntryURL = "https://appnewpanel.com/?app_id=6809480132&sub11=1790086480021-6024502&sub15=com.stf.s0n4rvs0ndm"
        state.debugProbeStatus = "HTTP 404 FAIL"
        return state
    }())
}
