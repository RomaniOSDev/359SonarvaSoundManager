import UIKit
import StoreKit

enum AppLinks {
    static let privacy = URL(string: "https://sonarvasound359manager.site/privacy/456")
    static let terms = URL(string: "https://sonarvasound359manager.site/terms/456")

    static func open(_ url: URL?) {
        guard let url else { return }
        UIApplication.shared.open(url)
    }

    static func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}
