import Foundation

public struct GridPoint: Hashable, Codable, Sendable {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

public struct Tile: Equatable, Codable, Sendable {
    public var id: String
    public var cells: Set<GridPoint>

    public init(id: String, cells: Set<GridPoint>) {
        self.id = id
        self.cells = cells
    }

    public func rotated(_ rotation: Rotation) -> Tile {
        Tile(id: id, cells: Set(cells.map { rotation.apply(to: $0) }))
    }
}

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
}

public struct Placement: Equatable, Codable, Sendable {
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

public struct Board: Equatable, Codable, Sendable {
    public var surface: Set<GridPoint>
    public var tiles: [Tile]

    public init(surface: Set<GridPoint>, tiles: [Tile]) {
        self.surface = surface
        self.tiles = tiles
    }

    public func validate(_ placements: [Placement], requireComplete: Bool = false) -> Result<Set<GridPoint>, PlacementValidationError> {
        let tileByID = Dictionary(uniqueKeysWithValues: tiles.map { ($0.id, $0) })
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
                let boardCell = GridPoint(x: cell.x + placement.origin.x, y: cell.y + placement.origin.y)
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

    public func isSolved(by placements: [Placement]) -> Bool {
        if case .success(let occupied) = validate(placements, requireComplete: true) {
            return occupied == surface
        }
        return false
    }
}

public struct DailySeed: Equatable, Codable, Sendable {
    public let dateKey: String
    public let value: UInt64

    public init(date: Date, calendar: Calendar = Calendar(identifier: .gregorian)) {
        var calendar = calendar
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.dateKey = String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
        self.value = DailySeed.fnv1a64(dateKey)
    }

    private static func fnv1a64(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        return hash
    }
}

public enum PlaceholderPuzzleFactory {
    public static func makeIntroBoard() -> Board {
        let surface = Set((0..<3).flatMap { x in (0..<2).map { y in GridPoint(x: x, y: y) } })
        let domino = Tile(id: "domino", cells: [GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0)])
        let triomino = Tile(id: "triomino", cells: [GridPoint(x: 0, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1)])
        let monomino = Tile(id: "monomino", cells: [GridPoint(x: 0, y: 0)])
        return Board(surface: surface, tiles: [domino, triomino, monomino])
    }
}
