import SwiftUI

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = ThemeCatalog.daybreak
}

extension EnvironmentValues {
    /// The active visual theme. Injected at the root from the user's setting and
    /// read by leaf views, which resolve light/dark via `\.colorScheme`.
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
