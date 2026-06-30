import Foundation
import Observation
import TesseraCore

/// The app's durable local state: progress, settings, entitlements cache, and the
/// resumable saved game. `@Observable` so SwiftUI views update automatically.
@MainActor
@Observable
final class GameStore {
    private(set) var progress: PlayerProgress
    var settings: Settings {
        didSet {
            Haptics.isEnabled = settings.hapticsEnabled
            persistSettings()
        }
    }
    private(set) var entitlements: Entitlements
    private(set) var savedGames: [String: SavedGame]

    private let store: CodableFileStore

    private static let progressKey = "progress"
    private static let settingsKey = "settings"
    private static let entitlementsKey = "entitlements"
    private static let savedGamesKey = "savedGames"

    init(store: CodableFileStore = CodableFileStore()) {
        self.store = store
        self.progress = store.load(PlayerProgress.self, from: Self.progressKey) ?? PlayerProgress()
        self.settings = store.load(Settings.self, from: Self.settingsKey) ?? Settings()
        self.entitlements = store.load(Entitlements.self, from: Self.entitlementsKey) ?? Entitlements()
        self.savedGames = store.load([String: SavedGame].self, from: Self.savedGamesKey) ?? [:]
        Haptics.isEnabled = settings.hapticsEnabled
    }

    // MARK: - Theme resolution

    /// The selected theme if owned, otherwise the free fallback. Keeps a paid theme
    /// from rendering after a refund/expiry without losing the user's choice.
    var activeTheme: Theme {
        let selected = ThemeCatalog.theme(withID: settings.themeID)
        return entitlements.ownsTheme(selected) ? selected : ThemeCatalog.daybreak
    }

    func ownsTheme(_ theme: Theme) -> Bool { entitlements.ownsTheme(theme) }

    var isPro: Bool { entitlements.isPro }

    // MARK: - Daily completion & streaks

    /// Records a solved puzzle. `isTodaysDaily` drives the streak; archive replays
    /// count toward totals but never change the current streak.
    func recordCompletion(
        puzzle: Puzzle,
        moves: Int,
        durationSeconds: Int,
        hintsUsed: Int,
        completedAt: Date,
        isTodaysDaily: Bool
    ) {
        progress.totalSolved += 1
        if puzzle.mode == .endless { progress.endlessSolved += 1 }

        let diffKey = puzzle.difficulty.rawValue
        if let best = progress.bestMovesByDifficulty[diffKey] {
            progress.bestMovesByDifficulty[diffKey] = min(best, moves)
        } else {
            progress.bestMovesByDifficulty[diffKey] = moves
        }

        if let dateKey = puzzle.dateKey, puzzle.mode == .daily {
            let alreadyDone = progress.hasCompleted(dateKey: dateKey)
            let result = DailyResult(
                dateKey: dateKey,
                difficulty: puzzle.difficulty,
                moves: moves,
                durationSeconds: durationSeconds,
                completedAt: completedAt
            )
            if let existing = progress.completedDaily[dateKey] {
                if moves < existing.moves { progress.completedDaily[dateKey] = result }
            } else {
                progress.completedDaily[dateKey] = result
            }

            if isTodaysDaily && !alreadyDone {
                updateStreak(forCompletedDateKey: dateKey)
            }
        }

        clearSavedGame(puzzleID: puzzle.id)
        persistProgress()
    }

    private func updateStreak(forCompletedDateKey dateKey: String) {
        if let last = progress.lastCompletedDateKey {
            let diff = Self.dayDifference(from: last, to: dateKey)
            if diff == 1 {
                progress.currentStreak += 1
            } else if diff == 0 {
                // Same day — leave streak as-is.
            } else {
                progress.currentStreak = 1
            }
        } else {
            progress.currentStreak = 1
        }
        progress.longestStreak = max(progress.longestStreak, progress.currentStreak)
        progress.lastCompletedDateKey = dateKey
    }

    /// Whole-day difference between two `YYYY-MM-DD` keys (UTC).
    static func dayDifference(from: String, to: String) -> Int {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        guard let a = formatter.date(from: from), let b = formatter.date(from: to) else { return Int.max }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar.dateComponents([.day], from: a, to: b).day ?? Int.max
    }

    /// Recomputes whether today still continues the streak (call on launch). If the
    /// last completion is older than yesterday, the current streak has lapsed.
    func refreshStreakLapse(today: Date) {
        guard let last = progress.lastCompletedDateKey else { return }
        let todayKey = DailySeed(date: today).dateKey
        let diff = Self.dayDifference(from: last, to: todayKey)
        if diff > 1 {
            progress.currentStreak = 0
            persistProgress()
        }
    }

    func tutorialCompleted() {
        guard !progress.tutorialCompleted else { return }
        progress.tutorialCompleted = true
        persistProgress()
    }

    // MARK: - Saved games (resume)

    func savedGame(forPuzzleID id: String) -> SavedGame? { savedGames[id] }

    func saveGame(_ game: SavedGame) {
        savedGames[game.puzzleID] = game
        store.save(savedGames, to: Self.savedGamesKey)
    }

    func clearSavedGame(puzzleID: String) {
        guard savedGames[puzzleID] != nil else { return }
        savedGames.removeValue(forKey: puzzleID)
        store.save(savedGames, to: Self.savedGamesKey)
    }

    // MARK: - Entitlements

    func applyEntitlements(isPro: Bool, unlockedThemeIDs: Set<String>) {
        entitlements.isPro = isPro
        entitlements.unlockedThemeIDs = unlockedThemeIDs
        store.save(entitlements, to: Self.entitlementsKey)
    }

    func selectTheme(_ theme: Theme) {
        guard ownsTheme(theme) else { return }
        settings.themeID = theme.id
    }

    // MARK: - Persistence helpers

    private func persistProgress() { store.save(progress, to: Self.progressKey) }
    private func persistSettings() { store.save(settings, to: Self.settingsKey) }

    // MARK: - Reset

    func resetAllProgress() {
        progress = PlayerProgress()
        savedGames = [:]
        store.save(progress, to: Self.progressKey)
        store.save(savedGames, to: Self.savedGamesKey)
    }
}
