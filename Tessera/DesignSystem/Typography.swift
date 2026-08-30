import SwiftUI

/// Type scale. Tessera uses SF Rounded for a soft, calm voice and leans on Dynamic
/// Type so the whole app scales with the user's accessibility text size.
enum AppFont {
    static func display(_ size: CGFloat = 34) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func title(_ size: CGFloat = 26) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func headline(_ size: CGFloat = 19) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func body(_ size: CGFloat = 16) -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func callout(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .medium, design: .rounded) }
    static func caption(_ size: CGFloat = 13) -> Font { .system(size: size, weight: .medium, design: .rounded) }
    static func mono(_ size: CGFloat = 28) -> Font { .system(size: size, weight: .semibold, design: .monospaced) }
}
