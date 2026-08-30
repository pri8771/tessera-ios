import Foundation

/// A single tile placement: which tile, where its local origin lands, and how it is rotated.
public struct Placement: Equatable, Codable, Sendable, Hashable {
    public var tileID: String
    public var origin: GridPoint
    public var rotation: Rotation

    public init(tileID: String, origin: GridPoint, rotation: Rotation = .degrees0) {
        self.tileID = tileID
        self.origin = origin
        self.rotation = rotation
    }
}

public enum PlacementValidationError: Error, Equatable, Sendable {
    case missingTile(String)
    case duplicateTile(String)
    case outOfBounds(tileID: String, cell: GridPoint)
    case overlap(tileID: String, cell: GridPoint)
    case gaps(Set<GridPoint>)
}

/// The logical puzzle: a surface (the cells that must be covered) and the tray of
/// tiles that must cover it. The board owns all correctness rules; UI layers only
/// render and forward intent.
public struct Board: Equatable, Codable, Sendable {
    public var surface: Set<GridPoint>
    public var tiles: [Tile]

    public init(surface: Set<GridPoint>, tiles: [Tile]) {
        self.surface = surface
        self.tiles = tiles
    }

    /// Total surface cells that must be covered.
    public var surfaceArea: Int { surface.count }

    /// Total area of every tray tile. For a well-formed tessellation puzzle this
    /// equals `surfaceArea`, so "all cells covered" is equivalent to "all tiles used".
    public var tilesArea: Int { tiles.reduce(0) { $0 + $1.area } }

    public func tile(withID id: String) -> Tile? {
        tiles.first { $0.id == id }
    }

    /// Returns the absolute (board-space) cells a placement would occupy, or `nil`
    /// if the placement references an unknown tile.
    public func absoluteCells(for placement: Placement) -> Set<GridPoint>? {
        guard let tile = tile(withID: placement.tileID) else { return nil }
        return Set(tile.rotated(placement.rotation).cells.map { $0 + placement.origin })
    }

    /// Validates a set of placements.
    ///
    /// On success returns the set of occupied cells. When `requireComplete` is
    /// `true`, every surface cell must be covered exactly once or `.gaps` is
    /// returned. A placement is illegal if it references an unknown tile, reuses a
    /// tile, leaves the surface, or overlaps another placement.
    public func validate(
        _ placements: [Placement],
        requireComplete: Bool = false
    ) -> Result<Set<GridPoint>, PlacementValidationError> {
        let tileByID = Dictionary(tiles.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var usedTiles = Set<String>()
        var occupied = Set<GridPoint>()

        for placement in placements {
            guard let tile = tileByID[placement.tileID] else {
                return .failure(.missingTile(placement.tileID))
            }
            guard usedTiles.insert(placement.tileID).inserted else {
                return .failure(.duplicateTile(placement.tileID))
            }

            for cell in tile.rotated(placement.rotation).cells {
                let boardCell = cell + placement.origin
                guard surface.contains(boardCell) else {
                    return .failure(.outOfBounds(tileID: placement.tileID, cell: boardCell))
                }
                guard occupied.insert(boardCell).inserted else {
                    return .failure(.overlap(tileID: placement.tileID, cell: boardCell))
                }
            }
        }

        if requireComplete {
            let gaps = surface.subtracting(occupied)
            guard gaps.isEmpty else { return .failure(.gaps(gaps)) }
        }

        return .success(occupied)
    }

    /// True when a single legal placement can be added to the current ones.
    public func canPlace(_ placement: Placement, given existing: [Placement]) -> Bool {
        if case .success = validate(existing + [placement]) { return true }
        return false
    }

    /// A board is solved when the placements legally cover every surface cell exactly once.
    public func isSolved(by placements: [Placement]) -> Bool {
        if case .success(let occupied) = validate(placements, requireComplete: true) {
            return occupied == surface
        }
        return false
    }
}
