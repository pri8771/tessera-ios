import SwiftUI
import TesseraCore

/// Replay recent daily puzzles. Pro-gated (entry is gated in Home).
struct ArchiveView: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var model
    @Environment(GameStore.self) private var store

    var onPlay: (Puzzle) -> Void

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: Spacing.md)]

    var body: some View {
        let colors = theme.colors(for: scheme)
        NavigationStack {
            ZStack {
                ThemedBackground()
                ScrollView {
                    LazyVGrid(columns: columns, spacing: Spacing.md) {
                        ForEach(model.puzzleService.recentDailyKeys(count: 30), id: \.self) { key in
                            archiveCell(key: key, colors: colors)
                        }
                    }
                    .padding(Spacing.md)
                }
            }
            .navigationTitle("Archive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.tint(colors.accent)
                }
            }
        }
    }

    private func archiveCell(key: String, colors: ThemeColors) -> some View {
        let puzzle = model.puzzleService.dailyPuzzle(forKey: key)
        let solved = store.progress.hasCompleted(dateKey: key)
        return Button { onPlay(puzzle) } label: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ZStack(alignment: .topTrailing) {
                    if solved {
                        SolvedBoardThumbnail(puzzle: puzzle)
                    } else {
                        SolvedBoardThumbnail(puzzle: puzzle, placements: [])
                            .opacity(0.85)
                    }
                    if solved {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(colors.success)
                            .padding(Spacing.xs)
                    }
                }
                .frame(height: 130)

                HStack {
                    Text(shortDate(key))
                        .font(AppFont.caption())
                        .foregroundStyle(colors.ink)
                    Spacer()
                    Text(puzzle.difficulty.displayName)
                        .font(AppFont.caption())
                        .foregroundStyle(colors.inkSecondary)
                }
            }
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(colors.separator, lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func shortDate(_ key: String) -> String {
        let inFormatter = DateFormatter()
        inFormatter.calendar = Calendar(identifier: .gregorian)
        inFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        inFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = inFormatter.date(from: key) else { return key }
        let out = DateFormatter()
        out.dateFormat = "MMM d"
        out.timeZone = TimeZone(secondsFromGMT: 0)
        return out.string(from: date)
    }
}
