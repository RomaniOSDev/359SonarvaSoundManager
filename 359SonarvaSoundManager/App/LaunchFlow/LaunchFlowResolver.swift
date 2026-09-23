//
//  LaunchFlowResolver.swift
//

import SwiftUI
import UIKit

/// Orchestrates launch destination: native shell, web document, or staging + probe.
@MainActor
final class LaunchFlowResolver {

    /// Debug hold: stay on loading, show AF dump + probe URL, never pivot to native from staging.
    private static let debugHoldOnStaging = true

    private let sessionStore: LaunchSessionStore
    private let gateEvaluator: CalendarGateEvaluator
    private let urlComposer: RemoteEntryURLComposer
    private let windowPresenter: RootWindowPresenter
    private var activeProbe: RemoteEntryProbe?
    private var stagingProbeCancelled = false

    init(window: UIWindow?) {
        self.sessionStore = LaunchSessionStore.shared
        self.sessionStore.resetIfFreshInstall()
        if sessionStore.savedLastURL == nil {
            sessionStore.hasShownNativeShell = false
        }
        self.gateEvaluator = CalendarGateEvaluator()
        self.urlComposer = RemoteEntryURLComposer()
        self.windowPresenter = RootWindowPresenter(window: window)
    }

    func resolveEntryViewController() -> UIViewController {
        let destination = resolveDestination()
        return viewController(for: destination)
    }

    func cancelPendingOperations() {
        stagingProbeCancelled = true
        activeProbe?.cancel()
        activeProbe = nil
    }

    // MARK: - Destination resolution

    func resolveDestination() -> LaunchDestination {
        guard isRemoteFlowAllowed else {
            return .native
        }

        // Debug: always run staging so we can inspect AF + probe on device.
        if Self.debugHoldOnStaging {
            return .staging
        }

        if sessionStore.hasShownNativeShell {
            return .native
        }

        if sessionStore.savedLastURL != nil {
            // Prefer rebuilt entry so WKWebView owns cookies/redirects again.
            if let entry = AppsFlyerConversionWaiter.resolvedEntryURL() ?? urlComposer.composedURL() {
                return .web(entry)
            }
            if let saved = sessionStore.savedLastURL {
                return .web(saved)
            }
        }

        return .staging
    }

    func viewController(for destination: LaunchDestination) -> UIViewController {
        switch destination {
        case .native:
            return makeNativeHost()
        case .web(let url):
            return makeWebHost(url: url)
        case .staging:
            return makeStagingHost()
        }
    }

    private var isRemoteFlowAllowed: Bool {
        gateEvaluator.isGateOpen()
    }

    // MARK: - Hosts

    private func makeNativeHost() -> UIViewController {
        let host = UIHostingController(rootView: ContentView())
        host.modalPresentationStyle = .fullScreen
        return host
    }

    private func makeWebHost(url: URL) -> UIViewController {
        guard isRemoteFlowAllowed else {
            return makeNativeHost()
        }
        let surface = WebDocumentSurfaceView(url: url) { [weak self] in
            self?.pivotToNative()
        }
        let host = UIHostingController(rootView: surface)
        host.modalPresentationStyle = .fullScreen
        return host
    }

    private func makeStagingHost() -> UIViewController {
        guard isRemoteFlowAllowed else {
            return makeNativeHost()
        }

        let state = LaunchStagingState()
        state.showDebugPanel = Self.debugHoldOnStaging
        let host = UIHostingController(rootView: DeferredLaunchCanvas(state: state))
        host.modalPresentationStyle = .fullScreen

        stagingProbeCancelled = false
        DispatchQueue.main.async { [weak self] in
            self?.runStagingFlow(state: state)
        }
        return host
    }

    // MARK: - Staging: ATT → AppsFlyer (retry) → probe(entry) → WebView(entry)

    private func runStagingFlow(state: LaunchStagingState) {
        guard !stagingProbeCancelled else { return }
        guard isRemoteFlowAllowed else {
            finishStaging(success: false, webURL: nil, state: state)
            return
        }

        AppTrackingPrompt.requestIfNeeded { [weak self] in
            guard let self, !self.stagingProbeCancelled else { return }
            state.statusMessage = "Waiting for AppsFlyer..."
            AppsFlyerConversionWaiter.waitForConversionWithRetry(
                onAttempt: { attempt, maxAttempts in
                    Task { @MainActor in
                        state.debugAttemptLabel = "AF attempt \(attempt)/\(maxAttempts) (timeout \(Int(AppsFlyerConversionWaiter.timeout))s)"
                        state.statusMessage = "AppsFlyer attempt \(attempt)/\(maxAttempts)..."
                    }
                },
                completion: { received in
                    Task { @MainActor in
                        guard !self.stagingProbeCancelled else { return }
                        state.debugConversionDump = AppsFlyerConversionWaiter.formattedConversionDump()
                        if !received {
                            state.debugEntryURL = "(no URL — conversion empty after retries)"
                            state.debugProbeStatus = "skipped"
                            state.statusMessage = "No AF conversion — holding (debug)"
                            state.progress = 1
                            if Self.debugHoldOnStaging { return }
                        }
                        self.startRemoteProbe(state: state)
                    }
                }
            )
        }
    }

    private func startRemoteProbe(state: LaunchStagingState) {
        guard !stagingProbeCancelled else { return }
        guard isRemoteFlowAllowed else {
            finishStaging(success: false, webURL: nil, state: state)
            return
        }

        state.debugConversionDump = AppsFlyerConversionWaiter.formattedConversionDump()

        guard let entryURL = AppsFlyerConversionWaiter.resolvedEntryURL() else {
            state.debugEntryURL = "(nil — builder + composer failed)"
            state.debugProbeStatus = "no URL"
            state.statusMessage = "No entry URL — holding (debug)"
            state.progress = 1
            if Self.debugHoldOnStaging { return }
            finishStaging(success: false, webURL: nil, state: state)
            return
        }

        state.debugEntryURL = entryURL.absoluteString
        state.statusMessage = "Probing entry URL..."
        state.debugProbeStatus = "probing…"

        let probe = RemoteEntryProbe()
        activeProbe = probe
        probe.probe(entryURL: entryURL, onProgress: { value in
            Task { @MainActor in
                state.progress = value
            }
        }, completion: { [weak self] result in
            Task { @MainActor in
                self?.activeProbe = nil
                guard let self, !self.stagingProbeCancelled else { return }

                if let code = result.statusCode {
                    state.debugProbeStatus = "HTTP \(code)" + (result.success ? " OK" : " FAIL")
                } else if let err = result.errorDescription {
                    state.debugProbeStatus = "error: \(err)"
                } else {
                    state.debugProbeStatus = result.success ? "OK" : "FAIL"
                }

                if Self.debugHoldOnStaging {
                    state.statusMessage = result.success
                        ? "Probe OK — holding (debug, no auto WebView)"
                        : "Probe failed — holding (debug, no native)"
                    state.progress = 1
                    // Debug: do not pivot to native or web automatically.
                    return
                }

                self.finishStaging(success: result.success, webURL: entryURL, state: state)
            }
        })
    }

    private func finishStaging(success: Bool, webURL: URL?, state: LaunchStagingState?) {
        guard isRemoteFlowAllowed else {
            if !Self.debugHoldOnStaging {
                pivotToNative()
            }
            return
        }
        guard success, let webURL else {
            if Self.debugHoldOnStaging {
                state?.statusMessage = "Would go native — holding (debug)"
                return
            }
            pivotToNative()
            return
        }
        pivotToWeb(url: webURL)
    }

    // MARK: - Pivot (after staging)

    func pivotToNative() {
        windowPresenter.slide(to: makeNativeHost())
    }

    func pivotToWeb(url: URL) {
        guard isRemoteFlowAllowed else {
            if !Self.debugHoldOnStaging {
                pivotToNative()
            }
            return
        }
        windowPresenter.slide(to: makeWebHost(url: url))
    }
}
