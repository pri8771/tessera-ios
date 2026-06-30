import Foundation
import TesseraCore

/// Result recorded when a daily puzzle is solved.
struct DailyResult: Codable, Equatable, Identifiable {
    var dateKey: String
    var difficulty: Difficulty
    var moves: Int
    var durationSeconds: Int
    var completedAt: Date

    var id: String { dateKey }
}

/// A persisted, resumable in-progress board.
struct SavedGame: Codable, Equatable {
    var puzzleID: String
    var mode: PuzzleMode
    var placements: [Placement]
    var elapsedSeconds: Int
    var moves: Int
    var hintsUsed: Int
}

/// All durable player progress. Local-only; no backend.
struct PlayerProgress: Codable, Equatable {
    var completedDaily: [String: DailyResult] = [:]
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastCompletedDateKey: String?
    var totalSolved: Int = 0
    var endlessSolved: Int = 0
    var tutorialCompleted: Bool = false
    /// Best (lowest) move count per difficulty, for the stats screen.
    var bestMovesByDifficulty: [String: Int] = [:]

    func hasCompleted(dateKey: String) -> Bool {
        completedDaily[dateKey] != nil
    }
}

/// User-facing settings (local-only).
struct Settings: Codable, Equatable {
    var themeID: String = ThemeCatalog.freeThemeID
    var hapticsEnabled: Bool = true
    var breathingEnabled: Bool = true
    var showGridGuides: Bool = true
    var hasSeenOnboarding: Bool = false
}

/// Cached StoreKit entitlements. Source of truth is StoreKit; this is an offline cache.
struct Entitlements: Codable, Equatable {
    var isPro: Bool = false
    var unlockedThemeIDs: Set<String> = []

    func ownsTheme(_ theme: Theme) -> Bool {
        !theme.isPremium || isPro || unlockedThemeIDs.contains(theme.id)
    }
}
