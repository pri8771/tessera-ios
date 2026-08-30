import SwiftUI
import TesseraCore

/// Difficulty picker for Endless mode.
struct EndlessView: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(GameStore.self) private var store

    var onSelect: (Difficulty) -> Void

    var body: some View {
        let colors = theme.colors(for: scheme)
        NavigationStack {
            ZStack {
                ThemedBackground()
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        Text("Choose a difficulty")
                            .font(AppFont.headline())
                            .foregroundStyle(colors.inkSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(Difficulty.allCases, id: \.self) { difficulty in
                            Button { onSelect(difficulty) } label: {
                                difficultyCard(difficulty, colors: colors)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                    .padding(Spacing.md)
                }
            }
            .navigationTitle("Endless")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.tint(colors.accent)
                }
            }
        }
    }

    private func difficultyCard(_ difficulty: Difficulty, colors: ThemeColors) -> some View {
        let best = store.progress.bestMovesByDifficulty[difficulty.rawValue]
        return HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .fill(colors.accentSoft)
                    .frame(width: 52, height: 52)
                Image(systemName: icon(for: difficulty))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(colors.accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(difficulty.displayName)
                    .font(AppFont.headline(18))
                    .foregroundStyle(colors.ink)
                Text(description(for: difficulty))
                    .font(AppFont.caption())
                    .foregroundStyle(colors.inkSecondary)
                if let best {
                    Text("Best: \(best) moves")
                        .font(AppFont.caption())
                        .foregroundStyle(colors.inkSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(colors.inkTertiary)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .strokeBorder(colors.separator, lineWidth: 1)
        )
    }

    private func icon(for difficulty: Difficulty) -> String {
        switch difficulty {
        case .gentle: return "leaf"
        case .calm: return "water.waves"
        case .deep: return "mountain.2"
        }
    }

    private func description(for difficulty: Difficulty) -> String {
        switch difficulty {
        case .gentle: return "A small surface, a few pieces"
        case .calm: return "A balanced, mid-size board"
        case .deep: return "A larger surface, more pieces"
        }
    }
}
