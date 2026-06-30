import SwiftUI
import TesseraCore

struct HomeView: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme
    @Environment(AppModel.self) private var model
    @Environment(GameStore.self) private var store

    @State private var activeGame: GameConfig?
    @State private var route: HomeRoute?
    @State private var showOnboarding = false
    @State private var endlessNonce: UInt64 = 0

    enum HomeRoute: Identifiable {
        case endless, archive, settings, store, stats
        var id: Int { hashValue }
    }

    var body: some View {
        let colors = theme.colors(for: scheme)
        NavigationStack {
            ZStack {
                ThemedBackground()
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        masthead(colors)
                        streakRow(colors)
                        dailyCard(colors)
                        modesSection(colors)
                        footer(colors)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { route = .settings } label: {
                        Image(systemName: "gearshape")
                    }
                    .tint(colors.ink)
                    .accessibilityLabel("Settings")
                }
            }
        }
        .fullScreenCover(item: $activeGame) { config in
            NavigationStack {
                GameView(config: config) { activeGame = nil }
            }
        }
        .sheet(item: $route) { route in
            sheet(for: route)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                store.settings.hasSeenOnboarding = true
                showOnboarding = false
                startTutorial()
            } onSkip: {
                store.settings.hasSeenOnboarding = true
                showOnboarding = false
            }
        }
        .onAppear {
            if handleAutoplayHook() { return }
            if !store.settings.hasSeenOnboarding { showOnboarding = true }
        }
    }

    // MARK: - Sections

    private func masthead(_ colors: ThemeColors) -> some View {
        VStack(spacing: Spacing.xs) {
            Text("Tessera")
                .font(AppFont.display(40))
                .foregroundStyle(colors.ink)
            Text("A living jigsaw that breathes.")
                .font(AppFont.callout())
                .foregroundStyle(colors.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.md)
    }

    private func streakRow(_ colors: ThemeColors) -> some View {
        HStack(spacing: Spacing.sm) {
            StatTile(value: "\(store.progress.currentStreak)", label: "Day streak", systemImage: "flame")
            StatTile(value: "\(store.progress.totalSolved)", label: "Solved", systemImage: "checkmark.seal")
            StatTile(value: "\(store.progress.longestStreak)", label: "Best streak", systemImage: "trophy")
        }
        .onTapGesture { route = .stats }
    }

    @ViewBuilder
    private func dailyCard(_ colors: ThemeColors) -> some View {
        let puzzle = model.puzzleService.todaysPuzzle()
        let dateKey = puzzle.dateKey ?? model.puzzleService.todaysDateKey()
        let solved = store.progress.hasCompleted(dateKey: dateKey)
        let saved = store.savedGame(forPuzzleID: puzzle.id)

        Card {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today's Daily")
                            .font(AppFont.headline())
                            .foregroundStyle(colors.ink)
                        Text(prettyDate(dateKey))
                            .font(AppFont.caption())
                            .foregroundStyle(colors.inkSecondary)
                    }
                    Spacer()
                    Pill(text: puzzle.difficulty.displayName, systemImage: "circle.grid.2x2")
                }

                if solved {
                    HStack(spacing: Spacing.md) {
                        SolvedBoardThumbnail(puzzle: puzzle)
                            .frame(width: 96, height: 96)
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Label("Completed", systemImage: "checkmark.seal.fill")
                                .font(AppFont.callout())
                                .foregroundStyle(colors.success)
                            if let result = store.progress.completedDaily[dateKey] {
                                Text("\(result.moves) moves · \(formatTime(result.durationSeconds))")
                                    .font(AppFont.caption())
                                    .foregroundStyle(colors.inkSecondary)
                            }
                            Text("Come back tomorrow for a new board.")
                                .font(AppFont.caption())
                                .foregroundStyle(colors.inkTertiary)
                        }
                        Spacer()
                    }
                    SecondaryButton("Replay today", systemImage: "arrow.counterclockwise") {
                        play(puzzle: puzzle, isToday: true)
                    }
                } else {
                    PrimaryButton(saved == nil ? "Play" : "Continue", systemImage: "play.fill") {
                        play(puzzle: puzzle, isToday: true)
                    }
                }
            }
        }
    }

    private func modesSection(_ colors: ThemeColors) -> some View {
        VStack(spacing: Spacing.sm) {
            SectionHeader(title: "More to play")
            ModeRow(
                title: "Endless",
                subtitle: store.isPro ? "Fresh boards, any difficulty" : "Unlock with Tessera Pro",
                systemImage: "infinity",
                locked: !store.isPro
            ) {
                if store.isPro { route = .endless } else { route = .store }
            }
            ModeRow(
                title: "Archive",
                subtitle: store.isPro ? "Replay recent dailies" : "Unlock with Tessera Pro",
                systemImage: "calendar",
                locked: !store.isPro
            ) {
                if store.isPro { route = .archive } else { route = .store }
            }
            ModeRow(
                title: "How to play",
                subtitle: store.progress.tutorialCompleted ? "Revisit the basics" : "Learn place, rotate, complete",
                systemImage: "graduationcap",
                locked: false
            ) {
                startTutorial()
            }
        }
    }

    private func footer(_ colors: ThemeColors) -> some View {
        VStack(spacing: Spacing.sm) {
            if !store.isPro {
                Button { route = .store } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Unlock Tessera Pro")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(AppFont.callout())
                    .foregroundStyle(colors.accent)
                    .padding(Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .fill(colors.accentSoft.opacity(0.5))
                    )
                }
            }
            Button { route = .store } label: {
                Text("Themes")
                    .font(AppFont.callout())
                    .foregroundStyle(colors.inkSecondary)
            }
        }
    }

    @ViewBuilder
    private func sheet(for route: HomeRoute) -> some View {
        switch route {
        case .endless:
            EndlessView { difficulty in
                endlessNonce &+= 1
                let puzzle = model.puzzleService.newEndlessPuzzle(difficulty: difficulty, nonce: endlessNonce)
                self.route = nil
                play(puzzle: puzzle, isToday: false)
            }
        case .archive:
            ArchiveView { puzzle in
                self.route = nil
                play(puzzle: puzzle, isToday: false)
            }
        case .settings:
            SettingsView()
        case .store:
            StoreView()
        case .stats:
            StatsView()
        }
    }

    // MARK: - Actions

    private func play(puzzle: Puzzle, isToday: Bool) {
        let config: GameConfig
        switch puzzle.mode {
        case .daily:
            config = GameConfig(
                puzzle: puzzle,
                isTodaysDaily: isToday,
                allowResume: true,
                title: "Daily",
                subtitle: prettyDate(puzzle.dateKey ?? "")
            )
        case .endless:
            config = GameConfig(
                puzzle: puzzle,
                isTodaysDaily: false,
                allowResume: true,
                title: "Endless",
                subtitle: puzzle.difficulty.displayName
            )
        case .tutorial:
            config = GameConfig(
                puzzle: puzzle,
                isTodaysDaily: false,
                allowResume: false,
                title: "How to play",
                subtitle: "Tutorial"
            )
        }
        activeGame = config
    }

    private func startTutorial() {
        let puzzle = CuratedPuzzles.tutorialRotate()
        play(puzzle: puzzle, isToday: false)
    }

    /// DEBUG-only hook: `TESSERA_AUTOPLAY=daily|tutorial|endless` in the launch
    /// environment opens a board immediately. Used for screenshots and UI tests;
    /// has no effect in release builds.
    private func handleAutoplayHook() -> Bool {
        #if DEBUG
        guard let mode = ProcessInfo.processInfo.environment["TESSERA_AUTOPLAY"] else { return false }
        switch mode {
        case "daily":
            play(puzzle: model.puzzleService.todaysPuzzle(), isToday: true)
        case "endless":
            play(puzzle: model.puzzleService.newEndlessPuzzle(difficulty: .calm, nonce: 1), isToday: false)
        default:
            play(puzzle: CuratedPuzzles.tutorialRotate(), isToday: false)
        }
        return true
        #else
        return false
        #endif
    }

    // MARK: - Formatting

    private func prettyDate(_ key: String) -> String {
        let inFormatter = DateFormatter()
        inFormatter.calendar = Calendar(identifier: .gregorian)
        inFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        inFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = inFormatter.date(from: key) else { return key }
        let out = DateFormatter()
        out.dateStyle = .medium
        out.timeZone = TimeZone(secondsFromGMT: 0)
        return out.string(from: date)
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

/// A tappable row for secondary modes.
struct ModeRow: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme

    let title: String
    let subtitle: String
    let systemImage: String
    let locked: Bool
    let action: () -> Void

    var body: some View {
        let colors = theme.colors(for: scheme)
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(colors.accent)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.headline(17))
                        .foregroundStyle(colors.ink)
                    Text(subtitle)
                        .font(AppFont.caption())
                        .foregroundStyle(colors.inkSecondary)
                }
                Spacer()
                Image(systemName: locked ? "lock.fill" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(locked ? colors.accent : colors.inkTertiary)
            }
            .padding(Spacing.md)
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
}
