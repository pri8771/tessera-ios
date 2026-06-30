import Foundation

/// A discrete cell on the logical puzzle grid.
///
/// The grid is the authoritative, deterministic representation of the puzzle.
/// Visual layers may round, bevel, or "breathe" cell boundaries, but hit-testing
/// and validation always happen against these integer coordinates.
public struct GridPoint: Hashable, Codable, Sendable, Comparable {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    /// Stable ordering used for deterministic iteration and solver tie-breaks.
    /// Rows first (y), then columns (x), so iteration reads top-to-bottom,
    /// left-to-right and never depends on `Set`/`Dictionary` ordering.
    public static func < (lhs: GridPoint, rhs: GridPoint) -> Bool {
        if lhs.y != rhs.y { return lhs.y < rhs.y }
        return lhs.x < rhs.x
    }

    public static func + (lhs: GridPoint, rhs: GridPoint) -> GridPoint {
        GridPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    public static func - (lhs: GridPoint, rhs: GridPoint) -> GridPoint {
        GridPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    /// The four orthogonal neighbours, in deterministic order.
    public var orthogonalNeighbours: [GridPoint] {
        [GridPoint(x: x, y: y - 1),
         GridPoint(x: x - 1, y: y),
         GridPoint(x: x + 1, y: y),
         GridPoint(x: x, y: y + 1)]
    }
}

/// Quarter-turn rotations applied around the origin `(0, 0)`.
public enum Rotation: Int, Codable, CaseIterable, Sendable {
    case degrees0 = 0
    case degrees90 = 90
    case degrees180 = 180
    case degrees270 = 270

    public func apply(to point: GridPoint) -> GridPoint {
        switch self {
        case .degrees0:
            return point
        case .degrees90:
            return GridPoint(x: -point.y, y: point.x)
        case .degrees180:
            return GridPoint(x: -point.x, y: -point.y)
        case .degrees270:
            return GridPoint(x: point.y, y: -point.x)
        }
    }

    /// The next clockwise quarter turn.
    public var clockwise: Rotation {
        switch self {
        case .degrees0: return .degrees90
        case .degrees90: return .degrees180
        case .degrees180: return .degrees270
        case .degrees270: return .degrees0
        }
    }

    public var counterClockwise: Rotation {
        switch self {
        case .degrees0: return .degrees270
        case .degrees90: return .degrees0
        case .degrees180: return .degrees90
        case .degrees270: return .degrees180
        }
    }
}

/// A polyomino tile: a connected set of local grid cells plus a stable identity.
public struct Tile: Equatable, Codable, Sendable, Identifiable {
    public var id: String
    public var cells: Set<GridPoint>

    public init(id: String, cells: Set<GridPoint>) {
        self.id = id
        self.cells = cells
    }

    /// Number of cells the tile occupies.
    public var area: Int { cells.count }

    /// Cells in a deterministic order (row-major).
    public var sortedCells: [GridPoint] { cells.sorted() }

    public func rotated(_ rotation: Rotation) -> Tile {
        Tile(id: id, cells: Set(cells.map { rotation.apply(to: $0) }))
    }

    /// Returns the same shape translated so its minimum cell sits at `(0, 0)`.
    /// Two tiles with the same shape and rotation always normalise identically,
    /// which lets the generator and solver compare and de-duplicate orientations.
    public func normalized() -> Tile {
        Tile(id: id, cells: Self.normalize(cells))
    }

    /// Distinct orientations of this tile after rotation, de-duplicated by shape.
    /// A square has one orientation; an L-tromino has four. Each entry pairs the
    /// canonical rotation with its normalised cells, ordered deterministically by
    /// rotation value so generation and solving never depend on hashing order.
    public var distinctOrientations: [(rotation: Rotation, cells: Set<GridPoint>)] {
        var seen = Set<[GridPoint]>()
        var result: [(Rotation, Set<GridPoint>)] = []
        for rotation in Rotation.allCases {
            let normalized = Self.normalize(rotated(rotation).cells)
            let key = normalized.sorted()
            if seen.insert(key).inserted {
                result.append((rotation, normalized))
            }
        }
        return result.map { (rotation: $0.0, cells: $0.1) }
    }

    /// Translates a set of cells so its component-wise minimum sits at `(0, 0)`.
    public static func normalize(_ cells: Set<GridPoint>) -> Set<GridPoint> {
        guard let minX = cells.map(\.x).min(), let minY = cells.map(\.y).min() else {
            return cells
        }
        let offset = GridPoint(x: minX, y: minY)
        return Set(cells.map { $0 - offset })
    }

    /// True when the tile is a single orthogonally-connected region.
    public var isConnected: Bool {
        guard let start = cells.min() else { return false }
        var visited: Set<GridPoint> = [start]
        var stack = [start]
        while let current = stack.popLast() {
            for neighbour in current.orthogonalNeighbours where cells.contains(neighbour) && !visited.contains(neighbour) {
                visited.insert(neighbour)
                stack.append(neighbour)
            }
        }
        return visited.count == cells.count
    }
}
