import Foundation

public enum Difficulty: String, Codable, CaseIterable, Sendable, Comparable {
    case gentle
    case calm
    case deep

    public var displayName: String {
        switch self {
        case .gentle: return "Gentle"
        case .calm: return "Calm"
        case .deep: return "Deep"
        }
    }

    public static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        let order: [Difficulty] = [.gentle, .calm, .deep]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

public enum PuzzleMode: String, Codable, Sendable {
    case daily
    case endless
    case tutorial
}

/// A complete, solvable puzzle ready to play.
///
/// The board carries the surface and the tray tiles; `solution` is a known-good
/// placement set (used for hints and for proving solvability at generation time).
/// Puzzles are `Codable` so an in-progress board can be persisted and resumed
/// locally with no backend.
public struct Puzzle: Equatable, Codable, Sendable, Identifiable {
    public let id: String
    public let mode: PuzzleMode
    public let difficulty: Difficulty
    public let seed: UInt64
    public let dateKey: String?
    public let board: Board
    public let solution: [Placement]

    public init(
        id: String,
        mode: PuzzleMode,
        difficulty: Difficulty,
        seed: UInt64,
        dateKey: String?,
        board: Board,
        solution: [Placement]
    ) {
        self.id = id
        self.mode = mode
        self.difficulty = difficulty
        self.seed = seed
        self.dateKey = dateKey
        self.board = board
        self.solution = solution
    }

    /// Bounding size of the surface, for layout.
    public var dimensions: (width: Int, height: Int) {
        let xs = board.surface.map(\.x)
        let ys = board.surface.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else {
            return (0, 0)
        }
        return (maxX - minX + 1, maxY - minY + 1)
    }

    public var pieceCount: Int { board.tiles.count }
}
