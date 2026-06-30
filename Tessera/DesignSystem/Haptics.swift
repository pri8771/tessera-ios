import UIKit

/// Centralised, respectful haptics. Every call is gated by the user's "Haptics"
/// setting via `Haptics.isEnabled`.
enum Haptics {
    /// Toggled by Settings; defaults on. Stored here so leaf views can fire haptics
    /// without threading the setting through every layer.
    static var isEnabled: Bool = true

    static func pickUp() { impact(.light) }
    static func rotate() { impact(.rigid, intensity: 0.7) }
    static func place() { impact(.soft) }
    static func invalid() { notification(.warning) }
    static func solved() { notification(.success) }
    static func selection() {
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }

    private static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
