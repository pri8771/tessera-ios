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
    /// When this snapshot was written. Used to evict old abandoned Endless
    /// attempts, which otherwise accumulate forever (Endless never resumes a
    /// specific past save — every session gets a fresh puzzle id). Optional/
    /// tolerant-decoded so saves written before this field existed still load;
    /// they just sort as oldest and are the first evicted.
    var savedAt: Date

    init(puzzleID: String, mode: PuzzleMode, placements: [Placement], elapsedSeconds: Int, moves: Int, hintsUsed: Int, savedAt: Date) {
        self.puzzleID = puzzleID
        self.mode = mode
        self.placements = placements
        self.elapsedSeconds = elapsedSeconds
        self.moves = moves
        self.hintsUsed = hintsUsed
        self.savedAt = savedAt
    }

    private enum CodingKeys: String, CodingKey {
        case puzzleID, mode, placements, elapsedSeconds, moves, hintsUsed, savedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            puzzleID: try c.decode(String.self, forKey: .puzzleID),
            mode: try c.decode(PuzzleMode.self, forKey: .mode),
            placements: try c.decode([Placement].self, forKey: .placements),
            elapsedSeconds: try c.decode(Int.self, forKey: .elapsedSeconds),
            moves: try c.decode(Int.self, forKey: .moves),
            hintsUsed: try c.decode(Int.self, forKey: .hintsUsed),
            savedAt: try c.decodeIfPresent(Date.self, forKey: .savedAt) ?? .distantPast
        )
    }
}

/// All durable player progress. Local-only; no backend — there is no server copy
/// to fall back on, so losing this to a decode failure is unrecoverable.
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

    init(
        completedDaily: [String: DailyResult] = [:],
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastCompletedDateKey: String? = nil,
        totalSolved: Int = 0,
        endlessSolved: Int = 0,
        tutorialCompleted: Bool = false,
        bestMovesByDifficulty: [String: Int] = [:]
    ) {
        self.completedDaily = completedDaily
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastCompletedDateKey = lastCompletedDateKey
        self.totalSolved = totalSolved
        self.endlessSolved = endlessSolved
        self.tutorialCompleted = tutorialCompleted
        self.bestMovesByDifficulty = bestMovesByDifficulty
    }

    func hasCompleted(dateKey: String) -> Bool {
        completedDaily[dateKey] != nil
    }

    // Tolerant decoding: a field added in a future version must not fail the
    // WHOLE decode (which would wipe streak/history with no way to recover it —
    // unlike Entitlements, there is no external source of truth to re-derive
    // this from). Every property falls back to its declared default when absent.
    private enum CodingKeys: String, CodingKey {
        case completedDaily, currentStreak, longestStreak, lastCompletedDateKey
        case totalSolved, endlessSolved, tutorialCompleted, bestMovesByDifficulty
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            completedDaily: try c.decodeIfPresent([String: DailyResult].self, forKey: .completedDaily) ?? [:],
            currentStreak: try c.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0,
            longestStreak: try c.decodeIfPresent(Int.self, forKey: .longestStreak) ?? 0,
            lastCompletedDateKey: try c.decodeIfPresent(String.self, forKey: .lastCompletedDateKey),
            totalSolved: try c.decodeIfPresent(Int.self, forKey: .totalSolved) ?? 0,
            endlessSolved: try c.decodeIfPresent(Int.self, forKey: .endlessSolved) ?? 0,
            tutorialCompleted: try c.decodeIfPresent(Bool.self, forKey: .tutorialCompleted) ?? false,
            bestMovesByDifficulty: try c.decodeIfPresent([String: Int].self, forKey: .bestMovesByDifficulty) ?? [:]
        )
    }
}

/// User-facing settings (local-only).
struct Settings: Codable, Equatable {
    var themeID: String = ThemeCatalog.freeThemeID
    var hapticsEnabled: Bool = true
    var breathingEnabled: Bool = true
    var showGridGuides: Bool = true
    var hasSeenOnboarding: Bool = false

    init(
        themeID: String = ThemeCatalog.freeThemeID,
        hapticsEnabled: Bool = true,
        breathingEnabled: Bool = true,
        showGridGuides: Bool = true,
        hasSeenOnboarding: Bool = false
    ) {
        self.themeID = themeID
        self.hapticsEnabled = hapticsEnabled
        self.breathingEnabled = breathingEnabled
        self.showGridGuides = showGridGuides
        self.hasSeenOnboarding = hasSeenOnboarding
    }

    private enum CodingKeys: String, CodingKey {
        case themeID, hapticsEnabled, breathingEnabled, showGridGuides, hasSeenOnboarding
    }

    // Tolerant decoding, matching PlayerProgress: a future setting added here
    // should degrade to its default, not reset the whole preferences file (and
    // silently re-show onboarding, reset the chosen theme, etc.) the first time
    // someone updates.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            themeID: try c.decodeIfPresent(String.self, forKey: .themeID) ?? ThemeCatalog.freeThemeID,
            hapticsEnabled: try c.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true,
            breathingEnabled: try c.decodeIfPresent(Bool.self, forKey: .breathingEnabled) ?? true,
            showGridGuides: try c.decodeIfPresent(Bool.self, forKey: .showGridGuides) ?? true,
            hasSeenOnboarding: try c.decodeIfPresent(Bool.self, forKey: .hasSeenOnboarding) ?? false
        )
    }
}

/// Cached StoreKit entitlements. Source of truth is StoreKit; this is an offline
/// cache that self-heals from `Transaction.currentEntitlements` on next launch,
/// so it's lower-risk than PlayerProgress/Settings, but tolerant decoding is
/// still cheap insurance against a launch-time crash-loop from a corrupt file.
struct Entitlements: Codable, Equatable {
    var isPro: Bool = false
    var unlockedThemeIDs: Set<String> = []

    init(isPro: Bool = false, unlockedThemeIDs: Set<String> = []) {
        self.isPro = isPro
        self.unlockedThemeIDs = unlockedThemeIDs
    }

    func ownsTheme(_ theme: Theme) -> Bool {
        !theme.isPremium || isPro || unlockedThemeIDs.contains(theme.id)
    }

    private enum CodingKeys: String, CodingKey {
        case isPro, unlockedThemeIDs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            isPro: try c.decodeIfPresent(Bool.self, forKey: .isPro) ?? false,
            unlockedThemeIDs: try c.decodeIfPresent(Set<String>.self, forKey: .unlockedThemeIDs) ?? []
        )
    }
}
