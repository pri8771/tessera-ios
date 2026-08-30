import Foundation
import Observation
import StoreKit

/// StoreKit 2 wrapper. Tessera's daily puzzle is free; **Tessera Pro** (a single
/// non-consumable) unlocks Endless mode, the daily Archive, and all premium themes.
///
/// The manager owns the StoreKit relationship and reports entitlement changes via
/// `onEntitlementsChanged`; `GameStore` caches the result for offline launches.
@MainActor
@Observable
final class StoreManager {

    enum ProductID {
        static let pro = "com.priyanshchordia.tessera.pro"
        static let all: [String] = [pro]
    }

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var loadState: LoadState = .idle
    private(set) var purchaseInFlight = false
    /// Result of the most recent purchase attempt, for the Store screen to
    /// surface. `nil` once acknowledged/cleared by the view.
    private(set) var lastPurchaseResult: PurchaseResult?
    private(set) var restoreState: RestoreState = .idle

    enum LoadState: Equatable {
        case idle, loading, loaded, failed(String)
    }

    enum PurchaseResult: Equatable {
        case succeeded
        case cancelled
        /// Awaiting approval (e.g. Ask to Buy) — not a failure, but not yet owned.
        case pending
        case failed(String)
    }

    enum RestoreState: Equatable {
        case idle, restoring, succeeded, failed(String)
    }

    /// Called whenever entitlements change so the rest of the app can cache them.
    var onEntitlementsChanged: ((_ isPro: Bool, _ unlockedThemeIDs: Set<String>) -> Void)?

    private var updatesTask: Task<Void, Never>?

    init() {
        // Listen for transactions that arrive outside an explicit purchase
        // (Ask to Buy approvals, restores on other devices, refunds).
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                if let transaction = try? self.checkVerified(update) {
                    await self.refreshPurchased()
                    await transaction.finish()
                }
            }
        }
    }

    var proProduct: Product? { products.first { $0.id == ProductID.pro } }
    var isPro: Bool { purchasedProductIDs.contains(ProductID.pro) }

    // MARK: - Loading

    func loadProducts() async {
        loadState = .loading
        do {
            let loaded = try await Product.products(for: ProductID.all)
            products = loaded.sorted { $0.price < $1.price }
            loadState = .loaded
            await refreshPurchased()
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Purchase / restore

    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        purchaseInFlight = true
        defer { purchaseInFlight = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await refreshPurchased()
                await transaction.finish()
                Haptics.solved()
                lastPurchaseResult = .succeeded
                return true
            case .userCancelled:
                lastPurchaseResult = .cancelled
                return false
            case .pending:
                lastPurchaseResult = .pending
                return false
            @unknown default:
                lastPurchaseResult = .failed("Something unexpected happened. Please try again.")
                return false
            }
        } catch {
            lastPurchaseResult = .failed(error.localizedDescription)
            return false
        }
    }

    func clearPurchaseResult() { lastPurchaseResult = nil }
    func clearRestoreResult() { restoreState = .idle }

    func restore() async {
        restoreState = .restoring
        do {
            try await AppStore.sync()
            await refreshPurchased()
            restoreState = .succeeded
        } catch {
            restoreState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Entitlements

    func refreshPurchased() async {
        var owned = Set<String>()
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                owned.insert(transaction.productID)
            }
        }
        purchasedProductIDs = owned
        emitEntitlements()
    }

    private func emitEntitlements() {
        // Theme-specific product ids would map to unlocked themes here; v1 ships only Pro.
        onEntitlementsChanged?(isPro, [])
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe): return safe
        case .unverified(_, let error): throw error
        }
    }
}
