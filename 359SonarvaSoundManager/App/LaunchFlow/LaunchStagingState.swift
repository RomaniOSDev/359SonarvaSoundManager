//
//  LaunchStagingState.swift
//

import Combine
import Foundation

@MainActor
final class LaunchStagingState: ObservableObject {
    /// Text shown under the staging progress indicator.
    static let defaultStatusMessage = "Preparing your experience..."

    @Published var progress: Double = 0
    @Published var statusMessage: String = LaunchStagingState.defaultStatusMessage

    // MARK: - Debug overlay (hold on loading; no native pivot)

    @Published var showDebugPanel = false
    @Published var debugAttemptLabel = ""
    @Published var debugConversionDump = ""
    @Published var debugEntryURL = ""
    @Published var debugProbeStatus = ""
}