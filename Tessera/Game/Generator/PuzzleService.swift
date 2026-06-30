import Foundation
import TesseraCore

/// App-facing orchestration around `TesseraCore`'s generator. Caches generated
/// puzzles so re-entering a screen is instant, and centralises "today".
@MainActor
final class PuzzleService {
    private let generator = PuzzleGenerator()
    private var dailyCache: [String: Puzzle] = [:]
    private var endlessCache: [String: Puzzle] = [:]

    /// Overridable clock so previews/tests can pin a date.
    var now: () -> Date = { Date() }

    static let shared = PuzzleService()

    // MARK: - Daily

    func todaysDateKey() -> String {
        DailySeed(date: now()).dateKey
    }

    func dailyPuzzle(for date: Date) -> Puzzle {
        let key = DailySeed(date: date).dateKey
        if let cached = dailyCache[key] { return cached }
        let puzzle = generator.dailyPuzzle(for: date)
        dailyCache[key] = puzzle
        return puzzle
    }

    func todaysPuzzle() -> Puzzle {
        dailyPuzzle(for: now())
    }

    func dailyPuzzle(forKey dateKey: String) -> Puzzle {
        if let cached = dailyCache[dateKey] { return cached }
        let puzzle = generator.dailyPuzzle(for: DailySeed(dateKey: dateKey))
        dailyCache[dateKey] = puzzle
        return puzzle
    }

    func difficulty(forDailyKey dateKey: String) -> Difficulty {
        PuzzleGenerator.dailyDifficulty(for: DailySeed(dateKey: dateKey).value)
    }

    // MARK: - Endless

    /// A fresh endless puzzle. The seed is derived from a counter + difficulty so
    /// each tap gives a new board, while still being reproducible from its id.
    func newEndlessPuzzle(difficulty: Difficulty, nonce: UInt64) -> Puzzle {
        let seed = DailySeed.fnv1a64("endless-\(difficulty.rawValue)-\(nonce)")
        let puzzle = generator.endlessPuzzle(seed: seed, difficulty: difficulty)
        endlessCache[puzzle.id] = puzzle
        return puzzle
    }

    func endlessPuzzle(id: String) -> Puzzle? {
        endlessCache[id]
    }

    // MARK: - Archive

    /// The most recent `count` daily date keys up to (and including) today, newest first.
    func recentDailyKeys(count: Int) -> [String] {
        var keys: [String] = []
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let today = now()
        for offset in 0..<count {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                keys.append(DailySeed(date: date).dateKey)
            }
        }
        return keys
    }
}
