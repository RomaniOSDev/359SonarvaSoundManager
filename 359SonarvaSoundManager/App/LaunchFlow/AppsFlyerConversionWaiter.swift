//
//  AppsFlyerConversionWaiter.swift
//

import Foundation

/// Waits for AppsFlyer conversion processing (or times out).
enum AppsFlyerConversionWaiter {
    static let conversionDataKey = "appsFlyerConversionData"
    /// Legacy key still written with the fully built entry URL when staging starts.
    static let userDefaultsKey = "finalAppsflyerURL"
    static let dataReceivedNotification = Notification.Name("AppsFlyerDataReceived")
    static let timeout: TimeInterval = 10

    /// Calls `completion` on the main queue when conversion data is ready or after `timeout`.
    static func waitForConversion(completion: @escaping () -> Void) {
        if UserDefaults.standard.dictionary(forKey: conversionDataKey) != nil
            || UserDefaults.standard.string(forKey: userDefaultsKey) != nil {
            DispatchQueue.main.async { completion() }
            return
        }

        var finished = false
        var observer: NSObjectProtocol?

        let finish: () -> Void = {
            guard !finished else { return }
            finished = true
            if let observer {
                NotificationCenter.default.removeObserver(observer)
            }
            completion()
        }

        observer = NotificationCenter.default.addObserver(
            forName: dataReceivedNotification,
            object: nil,
            queue: .main
        ) { _ in
            finish()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            finish()
        }
    }

    /// AF URL (`base/{sub7}?…` or `base/?…`) with composer fallback. Probe decides 404 → native.
    static func resolvedEntryURL() -> URL? {
        let url = AppsFlyerEntryURLBuilder.makeEntryURL()
            ?? RemoteEntryURLComposer().composedURL()
        if let url {
            UserDefaults.standard.set(url.absoluteString, forKey: userDefaultsKey)
        }
        return url
    }
}
