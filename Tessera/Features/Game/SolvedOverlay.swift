import SwiftUI
import TesseraCore

/// The celebratory panel shown after a board is solved: result stats, a share
/// action (on-device card), and replay / done.
struct SolvedOverlay: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme

    let puzzle: Puzzle
    let timeText: String
    let moves: Int
    let hintsUsed: Int
    let streak: Int
    var onDone: () -> Void
    var onReplay: () -> Void

    @State private var shareImage: UIImage?
    @State private var showShare = false

    var body: some View {
        let colors = theme.colors(for: scheme)
        ZStack {
            colors.background.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { }

            VStack(spacing: Spacing.lg) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(colors.success)
                    .accessibilityHidden(true)

                VStack(spacing: Spacing.xxs) {
                    Text("Solved")
                        .font(AppFont.title())
                        .foregroundStyle(colors.ink)
                    Text(subtitle)
                        .font(AppFont.callout())
                        .foregroundStyle(colors.inkSecondary)
                }

                HStack(spacing: Spacing.sm) {
                    StatTile(value: timeText, label: "Time", systemImage: "clock")
                    StatTile(value: "\(moves)", label: "Moves", systemImage: "hand.tap")
                    if puzzle.mode == .daily {
                        StatTile(value: "\(streak)", label: "Streak", systemImage: "flame")
                    } else {
                        StatTile(value: hintsUsed == 0 ? "None" : "\(hintsUsed)", label: "Hints", systemImage: "lightbulb")
                    }
                }

                VStack(spacing: Spacing.sm) {
                    PrimaryButton("Share", systemImage: "square.and.arrow.up") { prepareShare() }
                    HStack(spacing: Spacing.sm) {
                        SecondaryButton("Replay", systemImage: "arrow.counterclockwise") { onReplay() }
                        SecondaryButton("Done", systemImage: "checkmark") { onDone() }
                    }
                }
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .fill(colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .strokeBorder(colors.separator, lineWidth: 1)
            )
            .shadow(color: colors.shadow, radius: 24, x: 0, y: 12)
            .padding(.horizontal, Spacing.lg)
        }
        .sheet(isPresented: $showShare) {
            if let shareImage {
                ActivityShareSheet(items: [shareImage, shareText])
            }
        }
    }

    private var subtitle: String {
        switch puzzle.mode {
        case .daily: return "You completed today's daily."
        case .endless: return "\(puzzle.difficulty.displayName) puzzle complete."
        case .tutorial: return "Nicely done — you've got it."
        }
    }

    private var shareText: String {
        switch puzzle.mode {
        case .daily:
            return "Tessera \(puzzle.dateKey ?? "") — solved in \(timeText), \(moves) moves."
        default:
            return "Tessera — solved in \(timeText), \(moves) moves."
        }
    }

    private func prepareShare() {
        shareImage = ShareCardRenderer.render(
            puzzle: puzzle,
            theme: theme,
            colorScheme: scheme,
            timeText: timeText,
            moves: moves,
            streak: streak
        )
        showShare = shareImage != nil
    }
}
