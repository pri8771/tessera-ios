import SwiftUI

@main
struct TesseraApp: App {
    @State private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(model.store)
                .environment(model.storeManager)
                .environment(\.theme, model.store.activeTheme)
                .tint(model.store.activeTheme.colors(for: .light).accent)
                .task { await model.start() }
                .onChange(of: scenePhase) { _, phase in
                    // A streak lapse (last completion older than yesterday) was only
                    // ever checked once at cold launch. Someone who opens the app,
                    // backgrounds it without force-quitting, and returns days later
                    // would see a stale, still-intact streak until their next full
                    // relaunch — recheck every time the app becomes active instead.
                    if phase == .active { model.store.refreshStreakLapse(today: Date()) }
                }
        }
    }
}
