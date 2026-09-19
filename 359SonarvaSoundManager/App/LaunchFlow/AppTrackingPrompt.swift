//
//  AppTrackingPrompt.swift
//

import AppTrackingTransparency
import UIKit

/// Requests App Tracking Transparency on any launch path (native / web / staging).
enum AppTrackingPrompt {
    private static var isRequesting = false
    private static var pendingCompletions: [() -> Void] = []

    /// Asks for ATT when status is `.notDetermined`. Safe to call multiple times.
    static func requestIfNeeded(completion: (() -> Void)? = nil) {
        if let completion {
            pendingCompletions.append(completion)
        }

        let status = ATTrackingManager.trackingAuthorizationStatus
        guard status == .notDetermined else {
            flushPending()
            return
        }

        guard !isRequesting else { return }
        isRequesting = true
        waitUntilActiveThenRequest(attempt: 0)
    }

    private static func waitUntilActiveThenRequest(attempt: Int) {
        guard UIApplication.shared.applicationState == .active else {
            guard attempt < 50 else {
                isRequesting = false
                flushPending()
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                waitUntilActiveThenRequest(attempt: attempt + 1)
            }
            return
        }

        // Delay so the first screen is visible before the system dialog.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
                isRequesting = false
                flushPending()
                return
            }

            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    isRequesting = false
                    flushPending()
                }
            }
        }
    }

    private static func flushPending() {
        let completions = pendingCompletions
        pendingCompletions.removeAll()
        completions.forEach { $0() }
    }
}
