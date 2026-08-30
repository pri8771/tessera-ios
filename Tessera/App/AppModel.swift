import Foundation
import Observation
import TesseraCore

/// Top-level composition root. Owns the services and wires StoreKit entitlement
/// changes into the local cache. Injected into the environment at the app root.
@MainActor
@Observable
final class AppModel {
    let store: GameStore
    let storeManager: StoreManager
    let puzzleService: PuzzleService

    init() {
        let store = GameStore()
        self.store = store
        self.storeManager = StoreManager()
        self.puzzleService = PuzzleService()

        // StoreKit is the source of truth; mirror it into the offline cache.
        storeManager.onEntitlementsChanged = { [weak store] isPro, unlockedThemeIDs in
            store?.applyEntitlements(isPro: isPro, unlockedThemeIDs: unlockedThemeIDs)
        }
    }

    /// Run once at launch: lapse stale streaks and load StoreKit products.
    func start() async {
        store.refreshStreakLapse(today: Date())
        await storeManager.loadProducts()
    }
}
