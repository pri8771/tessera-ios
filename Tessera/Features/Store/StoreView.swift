import SwiftUI
import StoreKit

struct StoreView: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(GameStore.self) private var store
    @Environment(StoreManager.self) private var storeManager

    private let features: [(String, String)] = [
        ("infinity", "Endless mode — fresh boards in any difficulty"),
        ("calendar", "Daily Archive — replay the last 30 days"),
        ("paintpalette", "Every premium theme, now and future"),
        ("heart", "Support a tiny, ad-free, offline studio")
    ]

    private let columns = [GridItem(.adaptive(minimum: 92), spacing: Spacing.sm)]

    var body: some View {
        let colors = theme.colors(for: scheme)
        NavigationStack {
            ZStack {
                ThemedBackground()
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        header(colors)
                        featureList(colors)
                        purchaseSection(colors)
                        themeGallery(colors)
                        legal(colors)
                    }
                    .padding(Spacing.md)
                }
            }
            .navigationTitle("Tessera Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.tint(colors.accent)
                }
            }
            .task {
                if storeManager.products.isEmpty { await storeManager.loadProducts() }
            }
        }
    }

    private func header(_ colors: ThemeColors) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(colors.accent)
            Text(store.isPro ? "You have Tessera Pro" : "Unlock everything, once")
                .font(AppFont.title())
                .foregroundStyle(colors.ink)
                .multilineTextAlignment(.center)
            Text("A single purchase. No subscription.")
                .font(AppFont.callout())
                .foregroundStyle(colors.inkSecondary)
        }
        .padding(.top, Spacing.md)
    }

    private func featureList(_ colors: ThemeColors) -> some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(Array(features.enumerated()), id: \.offset) { _, feature in
                    HStack(spacing: Spacing.md) {
                        Image(systemName: feature.0)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(colors.accent)
                            .frame(width: 28)
                        Text(feature.1)
                            .font(AppFont.body())
                            .foregroundStyle(colors.ink)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func purchaseSection(_ colors: ThemeColors) -> some View {
        if store.isPro {
            Label("Unlocked — thank you", systemImage: "checkmark.seal.fill")
                .font(AppFont.headline())
                .foregroundStyle(colors.success)
                .padding(.vertical, Spacing.sm)
        } else if let product = storeManager.proProduct {
            VStack(spacing: Spacing.sm) {
                PrimaryButton(storeManager.purchaseInFlight ? "Purchasing…" : "Unlock for \(product.displayPrice)") {
                    Task { await storeManager.purchase(product) }
                }
                .disabled(storeManager.purchaseInFlight)
                Button("Restore purchases") {
                    Task { await storeManager.restore() }
                }
                .font(AppFont.callout())
                .foregroundStyle(colors.accent)
            }
        } else {
            VStack(spacing: Spacing.xs) {
                ProgressView()
                Text(unavailableMessage)
                    .font(AppFont.caption())
                    .foregroundStyle(colors.inkSecondary)
                Button("Restore purchases") { Task { await storeManager.restore() } }
                    .font(AppFont.callout())
                    .foregroundStyle(colors.accent)
            }
            .padding(.vertical, Spacing.sm)
        }
    }

    private func themeGallery(_ colors: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Themes")
            LazyVGrid(columns: columns, spacing: Spacing.md) {
                ForEach(ThemeCatalog.all) { item in
                    ThemeSwatch(
                        theme: item,
                        isSelected: store.settings.themeID == item.id,
                        owned: store.ownsTheme(item)
                    ) {
                        if store.ownsTheme(item) { store.selectTheme(item) }
                    }
                }
            }
        }
    }

    private func legal(_ colors: ThemeColors) -> some View {
        Text("Payment is charged to your Apple ID. Purchases restore on your devices via the App Store.")
            .font(AppFont.caption())
            .foregroundStyle(colors.inkTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.lg)
    }

    private var unavailableMessage: String {
        switch storeManager.loadState {
        case .failed:
            return "The store is unavailable right now. Check your connection and try again."
        default:
            return "Loading store…"
        }
    }
}
