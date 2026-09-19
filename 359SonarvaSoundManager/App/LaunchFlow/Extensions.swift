//
//  Extensions.swift
//

import Foundation
import AppsFlyerLib
import AdSupport
import AppTrackingTransparency

extension AppDelegate: AppsFlyerLibDelegate {
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        let flat = Self.flattenConversionData(data)
        UserDefaults.standard.set(flat, forKey: AppsFlyerConversionWaiter.conversionDataKey)
        // Full entry URL is built later (after ATT) so IDFA is available.
        NotificationCenter.default.post(name: Notification.Name("AppsFlyerDataReceived"), object: nil)
    }

    func onConversionDataFail(_ error: Error) {
        UserDefaults.standard.set(
            ["error": error.localizedDescription, "af_status": "Organic"],
            forKey: AppsFlyerConversionWaiter.conversionDataKey
        )
        NotificationCenter.default.post(name: Notification.Name("AppsFlyerDataReceived"), object: nil)
    }
}

// MARK: - Conversion flatten

extension AppDelegate {
    static func flattenConversionData(_ dictionary: [AnyHashable: Any], prefix: String? = nil) -> [String: String] {
        var result: [String: String] = [:]

        for (key, value) in dictionary {
            guard let keyString = key as? String else { continue }
            let newKey = prefix != nil ? "\(prefix!).\(keyString)" : keyString

            switch value {
            case let dict as [String: Any]:
                result.merge(flattenConversionData(dict, prefix: newKey)) { current, _ in current }
            case let dict as [AnyHashable: Any]:
                result.merge(flattenConversionData(dict, prefix: newKey)) { current, _ in current }
            case let array as [Any]:
                for (index, element) in array.enumerated() {
                    let arrayKey = "\(newKey)[\(index)]"
                    if let elementDict = element as? [String: Any] {
                        result.merge(flattenConversionData(elementDict, prefix: arrayKey)) { current, _ in current }
                    } else {
                        result[arrayKey] = "\(element)"
                    }
                }
            case let num as NSNumber:
                if CFGetTypeID(num) == CFBooleanGetTypeID() {
                    result[newKey] = num.boolValue ? "true" : "false"
                } else {
                    result[newKey] = num.stringValue
                }
            case let string as String:
                result[newKey] = string
            default:
                result[newKey] = "\(value)"
            }
        }
        return result
    }
}

// MARK: - Entry URL from AppsFlyer conversion

enum AppsFlyerEntryURLBuilder {

    /// Builds `https://host/{sub7}?…` when sub7 exists, otherwise `https://host/?…` from AF data.
    static func makeEntryURL(
        conversion: [String: String]? = nil,
        baseTemplate: String = LaunchFlowSecrets.remoteFlowEntryTemplate
    ) -> URL? {
        let data = conversion ?? (UserDefaults.standard.dictionary(forKey: AppsFlyerConversionWaiter.conversionDataKey) as? [String: String]) ?? [:]

        guard var components = URLComponents(string: baseTemplate) else { return nil }

        let pathToken = firstValue(in: data, keys: ["sub7", "af_sub7"])
        if let pathToken, !pathToken.isEmpty {
            let trimmedPath = pathToken.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let existing = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if existing.isEmpty {
                components.path = "/\(trimmedPath)"
            } else {
                components.path = "/\(existing)/\(trimmedPath)"
            }
        }

        let afUID = AppsFlyerLib.shared().getAppsFlyerUID()
        let appleAppID = AppsFlyerLib.shared().appleAppID
        let bundleID = Bundle.main.bundleIdentifier ?? ""

        // Query names match the tracker offer URL; values come from AF conversion / device.
        let pairs: [(String, String?)] = [
            ("sub1", firstValue(in: data, keys: ["sub1", "af_sub1"])),
            ("sub2", firstValue(in: data, keys: ["sub2", "af_sub2"])),
            ("sub3", firstValue(in: data, keys: ["sub3", "af_sub3"])),
            ("channel", firstValue(in: data, keys: ["channel", "af_channel", "media_source"])),
            ("sub5", firstValue(in: data, keys: ["sub5", "af_sub5"])),
            // sub_id_6 = {af_siteid}
            ("sub6", firstValue(in: data, keys: ["af_siteid", "siteid", "sub6", "af_sub6"])),
            ("sub7", pathToken),
            // sub_id_8 = {af_ad}
            ("sub8", firstValue(in: data, keys: ["af_ad", "afad", "ad", "sub8"])),
            ("idfa", currentIDFA()),
            ("d", firstValue(in: data, keys: ["d"])),
            ("campid", firstValue(in: data, keys: ["campid", "campaign_id", "af_c_id", "campaignid"])),
            ("adsetid", firstValue(in: data, keys: ["adsetid", "adset_id", "af_adset_id"])),
            ("adset", firstValue(in: data, keys: ["adset", "af_adset"])),
            ("app_id", firstValue(in: data, keys: ["app_id"]) ?? (appleAppID.isEmpty ? nil : appleAppID)),
            ("sub20", firstValue(in: data, keys: ["sub20", "sub_20", "af_sub20"])),
            // sub_id_11 = {af_id}
            ("sub11", afUID.isEmpty ? nil : afUID),
            // sub_id_15 = bundle
            ("sub15", bundleID.isEmpty ? nil : bundleID),
        ]

        components.queryItems = pairs.compactMap { name, value in
            guard let value, !value.isEmpty else { return nil }
            return URLQueryItem(name: name, value: value)
        }

        return components.url
    }

    private static func firstValue(in data: [String: String], keys: [String]) -> String? {
        for key in keys {
            if let value = data[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private static func currentIDFA() -> String? {
        guard ATTrackingManager.trackingAuthorizationStatus == .authorized else { return nil }
        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        if idfa == "00000000-0000-0000-0000-000000000000" { return nil }
        return idfa
    }
}
