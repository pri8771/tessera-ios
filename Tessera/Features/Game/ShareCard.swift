import SwiftUI
import TesseraCore

/// The shareable solve card. Rendered on-device with `ImageRenderer`; contains no
/// copyrighted assets — just the solved pattern, the day, and the player's result.
struct ShareCardView: View {
    let puzzle: Puzzle
    let theme: Theme
    let colorScheme: ColorScheme
    let timeText: String
    let moves: Int
    let streak: Int

    var body: some View {
        let colors = theme.colors(for: colorScheme)
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.xxs) {
                Text("TESSERA")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(colors.accent)
                Text(headline)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(colors.ink)
            }

            SolvedBoardThumbnail(puzzle: puzzle)
                .frame(width: 220, height: 220)
                .environment(\.theme, theme)
                .environment(\.colorScheme, colorScheme)

            HStack(spacing: Spacing.xl) {
                metric(value: timeText, label: "Time", colors: colors)
                metric(value: "\(moves)", label: "Moves", colors: colors)
                if streak > 0 {
                    metric(value: "\(streak)🔥", label: "Streak", colors: colors)
                }
            }

            Text("A living jigsaw that breathes.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(colors.inkSecondary)
        }
        .padding(Spacing.xl)
        .frame(width: 360)
        .background(
            LinearGradient(colors: [colors.surface, colors.background], startPoint: .top, endPoint: .bottom)
        )
    }

    private var headline: String {
        switch puzzle.mode {
        case .daily:
            return puzzle.dateKey.map { "Daily · \($0)" } ?? "Daily"
        case .endless:
            return "Endless · \(puzzle.difficulty.displayName)"
        case .tutorial:
            return "Tutorial"
        }
    }

    private func metric(value: String, label: String, colors: ThemeColors) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(colors.ink)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(colors.inkSecondary)
        }
    }
}

enum ShareCardRenderer {
    /// Renders the card to a `UIImage` at a crisp scale for sharing.
    @MainActor
    static func render(
        puzzle: Puzzle,
        theme: Theme,
        colorScheme: ColorScheme,
        timeText: String,
        moves: Int,
        streak: Int
    ) -> UIImage? {
        let card = ShareCardView(
            puzzle: puzzle,
            theme: theme,
            colorScheme: colorScheme,
            timeText: timeText,
            moves: moves,
            streak: streak
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        return renderer.uiImage
    }
}

/// Minimal share sheet wrapper for an image.
struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
