import SwiftUI
import TesseraCore

struct StatsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(GameStore.self) private var store

    var body: some View {
        let colors = theme.colors(for: scheme)
        let progress = store.progress
        NavigationStack {
            ZStack {
                ThemedBackground()
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        HStack(spacing: Spacing.sm) {
                            StatTile(value: "\(progress.currentStreak)", label: "Current streak", systemImage: "flame")
                            StatTile(value: "\(progress.longestStreak)", label: "Longest streak", systemImage: "trophy")
                        }
                        HStack(spacing: Spacing.sm) {
                            StatTile(value: "\(progress.totalSolved)", label: "Total solved", systemImage: "checkmark.seal")
                            StatTile(value: "\(progress.completedDaily.count)", label: "Dailies", systemImage: "calendar")
                        }

                        Card {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Best moves by difficulty")
                                    .font(AppFont.headline())
                                    .foregroundStyle(colors.ink)
                                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                                    HStack {
                                        Text(difficulty.displayName)
                                            .foregroundStyle(colors.inkSecondary)
                                        Spacer()
                                        if let best = progress.bestMovesByDifficulty[difficulty.rawValue] {
                                            Text("\(best) moves")
                                                .foregroundStyle(colors.ink)
                                        } else {
                                            Text("—").foregroundStyle(colors.inkSecondary)
                                        }
                                    }
                                    .font(AppFont.body())
                                }
                            }
                        }

                        if progress.endlessSolved > 0 {
                            Card {
                                HStack {
                                    Label("Endless solved", systemImage: "infinity")
                                        .foregroundStyle(colors.inkSecondary)
                                    Spacer()
                                    Text("\(progress.endlessSolved)").foregroundStyle(colors.ink)
                                }
                                .font(AppFont.body())
                            }
                        }
                    }
                    .padding(Spacing.md)
                }
            }
            .navigationTitle("Your Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.tint(colors.accent)
                }
            }
        }
    }
}
