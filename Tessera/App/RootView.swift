import SwiftUI

/// Root container. Shows onboarding the first time, then the home screen.
struct RootView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        HomeView()
            .preferredColorScheme(nil) // follow system; themes adapt to both
    }
}
