//
//  AppsFlyerConversionWaiter.swift
//

import Foundation
import AppsFlyerLib

/// Waits for AppsFlyer conversion processing (or times out), with optional retry.
enum AppsFlyerConversionWaiter {
    static let conversionDataKey = "appsFlyerConversionData"
    /// Legacy key still written with the fully built entry URL when staging starts.
    static let userDefaultsKey = "finalAppsflyerURL"
    static let dataReceivedNotification = Notification.Name("AppsFlyerDataReceived")

    /// Debug staging: 20s per attempt, up to 2 attempts.
    static let timeout: TimeInterval = 20
    static let maxAttempts = 2

    /// True when a non-empty conversion dictionary was stored (success or fail callback).
    static func hasConversionPayload() -> Bool {
        !storedConversion().isEmpty
    }

    /// Reads conversion as `[String: String]` without failing the whole cast on NSString values.
    static func storedConversion() -> [String: String] {
        guard let raw = UserDefaults.standard.dictionary(forKey: conversionDataKey) else { return [:] }
        var result: [String: String] = [:]
        for (key, value) in raw {
            result[key] = "\(value)"
        }
        return result
    }

    static func formattedConversionDump() -> String {
        let conversion = storedConversion()
        if conversion.isEmpty { return "(empty — no conversion yet)" }
        return conversion
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key) = \($0.value)" }
            .joined(separator: "\n")
    }

    static func clearStoredConversion() {
        UserDefaults.standard.removeObject(forKey: conversionDataKey)
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    /// Waits up to `timeout`, then retries AppsFlyer `start()` once more if still empty (max 2 attempts).
    static func waitForConversionWithRetry(
        attempt: Int = 1,
        onAttempt: ((Int, Int) -> Void)? = nil,
        completion: @escaping (_ received: Bool) -> Void
    ) {
        onAttempt?(attempt, maxAttempts)

        if attempt > 1 {
            clearStoredConversion()
            print("[LaunchFlow] AppsFlyer conversion retry #\(attempt) — clearing cache + start()")
            AppsFlyerLib.shared().start()
        }

        waitOnce {
            let received = hasConversionPayload()
            if received {
                print("[LaunchFlow] AppsFlyer conversion received on attempt \(attempt)")
                completion(true)
                return
            }
            if attempt >= maxAttempts {
                print("[LaunchFlow] AppsFlyer conversion missing after \(maxAttempts) attempts")
                completion(false)
                return
            }
            waitForConversionWithRetry(
                attempt: attempt + 1,
                onAttempt: onAttempt,
                completion: completion
            )
        }
    }

    /// Calls `completion` on the main queue when conversion data is ready or after `timeout`.
    static func waitForConversion(completion: @escaping () -> Void) {
        waitOnce(completion: completion)
    }

    private static func waitOnce(completion: @escaping () -> Void) {
        if hasConversionPayload() {
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
        let conversion = storedConversion()
        print("[LaunchFlow] AppsFlyer conversion (at URL build):")
        if conversion.isEmpty {
            print("  (empty)")
        } else {
            print(conversion.sorted(by: { $0.key < $1.key }).map { "  \($0.key) = \($0.value)" }.joined(separator: "\n"))
        }

        let url = AppsFlyerEntryURLBuilder.makeEntryURL(conversion: conversion)
            ?? RemoteEntryURLComposer().composedURL()
        if let url {
            UserDefaults.standard.set(url.absoluteString, forKey: userDefaultsKey)
            print("[LaunchFlow] Final entry URL: \(url.absoluteString)")
        } else {
            print("[LaunchFlow] Final entry URL: nil (builder + composer failed)")
        }
        return url
    }
}
