import SwiftUI

@main
struct TesseraApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(model.store)
                .environment(model.storeManager)
                .environment(\.theme, model.store.activeTheme)
                .tint(model.store.activeTheme.colors(for: .light).accent)
                .task { await model.start() }
        }
    }
}
