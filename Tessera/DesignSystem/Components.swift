import SwiftUI

// MARK: - Background

/// The app's base background. A soft vertical wash gives the "gallery" depth
/// without distracting from the board.
struct ThemedBackground: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let colors = theme.colors(for: scheme)
        LinearGradient(
            colors: [colors.background, colors.background.opacity(0.92), colors.surface.opacity(0.6)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Card

struct Card<Content: View>: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme

    var padding: CGFloat = Spacing.md
    @ViewBuilder var content: () -> Content

    var body: some View {
        let colors = theme.colors(for: scheme)
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(colors.separator, lineWidth: 1)
            )
            .shadow(color: colors.shadow, radius: 10, x: 0, y: 6)
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled

    let title: String
    var systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        let colors = theme.colors(for: scheme)
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(AppFont.headline())
            .foregroundStyle(onAccent(colors))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(colors.accent)
                    .opacity(isEnabled ? 1 : 0.4)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func onAccent(_ colors: ThemeColors) -> Color {
        scheme == .dark ? colors.background : Color.white
    }
}

struct SecondaryButton: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme

    let title: String
    var systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        let colors = theme.colors(for: scheme)
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(AppFont.headline())
            .foregroundStyle(colors.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(colors.separator, lineWidth: 1.5)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// A subtle press animation used across all buttons for a tactile, calm feel.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Pills & chips

struct Pill: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme

    let text: String
    var systemImage: String?
    var tint: KeyPath<ThemeColors, Color> = \.accent

    var body: some View {
        let colors = theme.colors(for: scheme)
        HStack(spacing: Spacing.xxs) {
            if let systemImage { Image(systemName: systemImage) }
            Text(text)
        }
        .font(AppFont.caption())
        .foregroundStyle(colors[keyPath: tint])
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs + 2)
        .background(
            Capsule().fill(colors[keyPath: tint].opacity(0.14))
        )
    }
}

struct StatTile: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme

    let value: String
    let label: String
    var systemImage: String?

    var body: some View {
        let colors = theme.colors(for: scheme)
        VStack(spacing: Spacing.xxs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(colors.accent)
            }
            Text(value)
                .font(AppFont.title(22))
                .foregroundStyle(colors.ink)
                .contentTransition(.numericText())
            Text(label)
                .font(AppFont.caption())
                .foregroundStyle(colors.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .strokeBorder(colors.separator, lineWidth: 1)
        )
    }
}

// MARK: - Section header

struct SectionHeader: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme
    let title: String
    var action: (() -> Void)?
    var actionTitle: String?

    var body: some View {
        let colors = theme.colors(for: scheme)
        HStack {
            Text(title)
                .font(AppFont.headline())
                .foregroundStyle(colors.ink)
            Spacer()
            if let action, let actionTitle {
                Button(actionTitle, action: action)
                    .font(AppFont.callout())
                    .foregroundStyle(colors.accent)
            }
        }
    }
}
