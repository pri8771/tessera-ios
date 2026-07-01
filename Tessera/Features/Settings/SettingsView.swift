import SwiftUI

struct SettingsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(GameStore.self) private var store
    @Environment(StoreManager.self) private var storeManager

    @State private var showStore = false
    @State private var confirmReset = false

    var body: some View {
        @Bindable var store = store
        let colors = theme.colors(for: scheme)
        NavigationStack {
            ZStack {
                ThemedBackground()
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        themeSection(colors)

                        Card {
                            VStack(spacing: Spacing.xs) {
                                Toggle("Haptics", isOn: $store.settings.hapticsEnabled)
                                Divider().background(colors.separator)
                                Toggle("Breathing motion", isOn: $store.settings.breathingEnabled)
                                Divider().background(colors.separator)
                                Toggle("Grid guides", isOn: $store.settings.showGridGuides)
                            }
                            .tint(colors.accent)
                            .foregroundStyle(colors.ink)
                            .font(AppFont.body())
                        }

                        Card {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Button {
                                    Task { await storeManager.restore() }
                                } label: {
                                    settingsRow(restoreRowTitle, system: restoreRowIcon, colors: colors)
                                }
                                .disabled(storeManager.restoreState == .restoring)
                                Divider().background(colors.separator)
                                Button { showStore = true } label: {
                                    settingsRow(store.isPro ? "Tessera Pro · Unlocked" : "Unlock Tessera Pro",
                                                system: "sparkles", colors: colors)
                                }
                            }
                        }

                        Card {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                aboutRow("Version", value: appVersion, colors: colors)
                                Divider().background(colors.separator)
                                aboutRow("Privacy", value: "Offline · no tracking", colors: colors)
                                Divider().background(colors.separator)
                                Button {
                                    store.settings.hasSeenOnboarding = false
                                    dismiss()
                                } label: {
                                    settingsRow("Replay onboarding", system: "sparkles.rectangle.stack", colors: colors)
                                }
                                Divider().background(colors.separator)
                                Button(role: .destructive) { confirmReset = true } label: {
                                    settingsRow("Reset progress", system: "trash", colors: colors, destructive: true)
                                }
                            }
                        }

                        Text("Tessera stores everything on your device. No account, no analytics, no ads.")
                            .font(AppFont.caption())
                            .foregroundStyle(colors.inkSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                    }
                    .padding(Spacing.md)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.tint(colors.accent)
                }
            }
            .sheet(isPresented: $showStore) { StoreView() }
            .alert("Reset all progress?", isPresented: $confirmReset) {
                Button("Reset", role: .destructive) { store.resetAllProgress() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears your streak, history, and saved boards. It can't be undone.")
            }
            .alert("Restore failed", isPresented: restoreFailedBinding, presenting: restoreFailureMessage) { _ in
                Button("OK") {}
            } message: { Text($0) }
        }
    }

    private var restoreRowTitle: String {
        switch storeManager.restoreState {
        case .restoring: return "Restoring…"
        case .succeeded: return "Restored"
        case .idle, .failed: return "Restore purchases"
        }
    }

    private var restoreRowIcon: String {
        switch storeManager.restoreState {
        case .restoring: return "arrow.triangle.2.circlepath"
        case .succeeded: return "checkmark.circle.fill"
        case .idle, .failed: return "arrow.clockwise"
        }
    }

    private var restoreFailureMessage: String? {
        if case .failed(let message) = storeManager.restoreState { return message }
        return nil
    }

    private var restoreFailedBinding: Binding<Bool> {
        Binding(
            get: { restoreFailureMessage != nil },
            set: { if !$0 { storeManager.clearRestoreResult() } }
        )
    }

    private func themeSection(_ colors: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Theme")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(ThemeCatalog.all) { item in
                        ThemeSwatch(
                            theme: item,
                            isSelected: store.settings.themeID == item.id,
                            owned: store.ownsTheme(item)
                        ) {
                            if store.ownsTheme(item) {
                                store.selectTheme(item)
                            } else {
                                showStore = true
                            }
                        }
                    }
                }
                .padding(.vertical, Spacing.xxs)
            }
        }
    }

    private func settingsRow(_ title: String, system: String, colors: ThemeColors, destructive: Bool = false) -> some View {
        HStack {
            Image(systemName: system)
                .foregroundStyle(destructive ? Color.red : colors.accent)
                .frame(width: 26)
            Text(title)
                .foregroundStyle(destructive ? Color.red : colors.ink)
            Spacer()
            if !destructive { Image(systemName: "chevron.right").foregroundStyle(colors.inkTertiary).font(.caption) }
        }
        .font(AppFont.body())
    }

    private func aboutRow(_ title: String, value: String, colors: ThemeColors) -> some View {
        HStack {
            Text(title).foregroundStyle(colors.ink)
            Spacer()
            Text(value).foregroundStyle(colors.inkSecondary)
        }
        .font(AppFont.body())
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

/// A theme preview chip used in Settings and the Store.
struct ThemeSwatch: View {
    @Environment(\.colorScheme) private var scheme
    let theme: Theme
    let isSelected: Bool
    let owned: Bool
    let action: () -> Void

    var body: some View {
        let colors = theme.colors(for: scheme)
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .fill(colors.background)
                        .frame(width: 84, height: 84)
                        .overlay(
                            HStack(spacing: 3) {
                                ForEach(Array(theme.previewSwatches.enumerated()), id: \.offset) { _, color in
                                    Circle().fill(color).frame(width: 12, height: 12)
                                }
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                .strokeBorder(isSelected ? colors.accent : colors.separator,
                                              lineWidth: isSelected ? 2.5 : 1)
                        )
                    if !owned {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(Circle().fill(colors.accent))
                            .padding(5)
                    }
                }
                Text(theme.name)
                    .font(AppFont.caption())
                    .foregroundStyle(colors.ink)
            }
        }
        .buttonStyle(PressableButtonStyle())
    }
}
