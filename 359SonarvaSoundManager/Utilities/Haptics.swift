import UIKit

enum Haptics {
    static func save() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func favourite() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func play() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
}
