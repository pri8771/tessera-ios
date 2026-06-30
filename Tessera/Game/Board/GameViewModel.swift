import Foundation
import Observation
import CoreGraphics
import TesseraCore

/// Drives one playable board: tray, placements, drag/rotate interaction, timer,
/// hints, and win detection. UI-agnostic apart from `CGPoint` drag math, which
/// keeps it unit-testable. All rules defer to `TesseraCore`.
@MainActor
@Observable
final class GameViewModel {
    let puzzle: Puzzle

    /// tileID → committed placement.
    private(set) var placements: [String: Placement] = [:]
    /// Unplaced tray pieces, in stable order.
    private(set) var trayOrder: [String]
    /// Chosen rotation for each piece (applies in tray and on drop).
    private(set) var rotationByTile: [String: Rotation] = [:]

    private(set) var moves = 0
    private(set) var hintsUsed = 0
    private(set) var elapsedSeconds = 0
    private(set) var isSolved = false

    var selectedTileID: String?
    private(set) var drag: DragState?

    /// Called once when the board becomes solved.
    var onSolved: (() -> Void)?

    private let tileByID: [String: Tile]
    private let colorIndexByTile: [String: Int]

    struct DragState {
        var tileID: String
        var rotation: Rotation
        var displayCells: [GridPoint]
        var fingerLocation: CGPoint
        var snappedOrigin: GridPoint?  // display-space origin (where displayCells (0,0) lands)
        var isValid: Bool
    }

    init(puzzle: Puzzle, resuming saved: SavedGame? = nil) {
        self.puzzle = puzzle
        self.trayOrder = puzzle.board.tiles.map(\.id)
        self.tileByID = Dictionary(uniqueKeysWithValues: puzzle.board.tiles.map { ($0.id, $0) })
        var colorIndex: [String: Int] = [:]
        for (index, tile) in puzzle.board.tiles.enumerated() { colorIndex[tile.id] = index }
        self.colorIndexByTile = colorIndex

        for tile in puzzle.board.tiles { rotationByTile[tile.id] = .degrees0 }

        if let saved { restore(from: saved) }
    }

    private func restore(from saved: SavedGame) {
        for placement in saved.placements {
            placements[placement.tileID] = placement
            rotationByTile[placement.tileID] = placement.rotation
            trayOrder.removeAll { $0 == placement.tileID }
        }
        moves = saved.moves
        elapsedSeconds = saved.elapsedSeconds
        hintsUsed = saved.hintsUsed
        evaluateSolved(triggerCallback: false)
    }

    // MARK: - Derived

    var board: Board { puzzle.board }
    var remainingCount: Int { trayOrder.count }

    func tile(_ id: String) -> Tile? { tileByID[id] }
    func colorIndex(for id: String) -> Int { colorIndexByTile[id] ?? 0 }
    func rotation(for id: String) -> Rotation { rotationByTile[id] ?? .degrees0 }

    /// Normalised, rotated cells used for drawing a piece in its current rotation.
    func displayCells(for id: String, rotation: Rotation? = nil) -> [GridPoint] {
        guard let tile = tileByID[id] else { return [] }
        let rot = rotation ?? self.rotation(for: id)
        return Tile.normalize(Set(tile.rotated(rot).cells)).sorted()
    }

    func placement(for id: String) -> Placement? { placements[id] }

    var occupiedCells: Set<GridPoint> {
        var occupied = Set<GridPoint>()
        for placement in placements.values {
            if let cells = board.absoluteCells(for: placement) { occupied.formUnion(cells) }
        }
        return occupied
    }

    // MARK: - Selection & rotation

    func toggleSelection(_ id: String) {
        selectedTileID = (selectedTileID == id) ? nil : id
        Haptics.selection()
    }

    func rotate(_ id: String) {
        guard placements[id] == nil else { return }
        rotationByTile[id] = rotation(for: id).clockwise
        Haptics.rotate()
    }

    // MARK: - Drag

    func beginDrag(tileID: String, at location: CGPoint, geometry: BoardGeometry) {
        guard placements[tileID] == nil else { return }
        selectedTileID = tileID
        let rot = rotation(for: tileID)
        let cells = displayCells(for: tileID, rotation: rot)
        drag = DragState(
            tileID: tileID,
            rotation: rot,
            displayCells: cells,
            fingerLocation: location,
            snappedOrigin: nil,
            isValid: false
        )
        updateDrag(to: location, geometry: geometry)
        Haptics.pickUp()
    }

    func updateDrag(to location: CGPoint, geometry: BoardGeometry) {
        guard var state = drag else { return }
        state.fingerLocation = location

        // Anchor the piece's bounding box centre under the finger, then snap.
        let cols = (state.displayCells.map(\.x).max() ?? 0) + 1
        let rows = (state.displayCells.map(\.y).max() ?? 0) + 1
        let topLeft = CGPoint(
            x: location.x - CGFloat(cols) * geometry.cellSize / 2,
            y: location.y - CGFloat(rows) * geometry.cellSize / 2
        )
        let snapped = geometry.cell(at: CGPoint(x: topLeft.x + geometry.cellSize / 2,
                                                y: topLeft.y + geometry.cellSize / 2))
        state.snappedOrigin = snapped
        state.isValid = isValidPlacement(tileID: state.tileID, rotation: state.rotation, displayOrigin: snapped)
        drag = state
    }

    /// Commits the drag if valid. Returns whether a placement was made.
    @discardableResult
    func endDrag(geometry: BoardGeometry) -> Bool {
        defer { drag = nil }
        guard let state = drag, let origin = state.snappedOrigin, state.isValid else {
            Haptics.invalid()
            return false
        }
        commitPlacement(tileID: state.tileID, rotation: state.rotation, displayOrigin: origin)
        return true
    }

    func cancelDrag() { drag = nil }

    // MARK: - Placement rules

    /// Board cells covered if `tileID` is placed at `displayOrigin` (display space).
    func boardCells(tileID: String, rotation: Rotation, displayOrigin: GridPoint) -> [GridPoint] {
        displayCells(for: tileID, rotation: rotation).map { $0 + displayOrigin }
    }

    func isValidPlacement(tileID: String, rotation: Rotation, displayOrigin: GridPoint) -> Bool {
        let cells = boardCells(tileID: tileID, rotation: rotation, displayOrigin: displayOrigin)
        let occupied = occupiedCells
        for cell in cells {
            if !board.surface.contains(cell) { return false }
            if occupied.contains(cell) { return false }
        }
        return true
    }

    private func placement(tileID: String, rotation: Rotation, displayOrigin: GridPoint) -> Placement {
        // Convert display origin to a core Placement origin (subtract rotation offset).
        guard let tile = tileByID[tileID] else {
            return Placement(tileID: tileID, origin: displayOrigin, rotation: rotation)
        }
        let rotated = tile.rotated(rotation).cells
        let offset = GridPoint(
            x: rotated.map(\.x).min() ?? 0,
            y: rotated.map(\.y).min() ?? 0
        )
        return Placement(tileID: tileID, origin: displayOrigin - offset, rotation: rotation)
    }

    private func commitPlacement(tileID: String, rotation: Rotation, displayOrigin: GridPoint) {
        let placement = placement(tileID: tileID, rotation: rotation, displayOrigin: displayOrigin)
        placements[tileID] = placement
        trayOrder.removeAll { $0 == tileID }
        moves += 1
        if selectedTileID == tileID { selectedTileID = nil }
        Haptics.place()
        evaluateSolved(triggerCallback: true)
    }

    /// Drag-free placement: places the currently selected tray piece so that it
    /// covers `cell`, trying each of the piece's cells as the one landing on the
    /// tap. Returns whether a placement was made. This is the accessible path
    /// (VoiceOver / Switch Control can't drag) and a faster option for everyone:
    /// tap a piece to select, then tap a spot.
    @discardableResult
    func placeSelected(coveringBoardCell cell: GridPoint) -> Bool {
        guard let id = selectedTileID, placements[id] == nil else { return false }
        let rot = rotation(for: id)
        let cells = displayCells(for: id, rotation: rot)
        for anchor in cells {
            let displayOrigin = cell - anchor
            if isValidPlacement(tileID: id, rotation: rot, displayOrigin: displayOrigin) {
                commitPlacement(tileID: id, rotation: rot, displayOrigin: displayOrigin)
                return true
            }
        }
        Haptics.invalid()
        return false
    }

    /// Picks a placed piece back up, returning it to the tray.
    func pickUp(placedTileID id: String) {
        guard placements[id] != nil else { return }
        placements.removeValue(forKey: id)
        if !trayOrder.contains(id) { trayOrder.append(id) }
        trayOrder.sort { lhs, rhs in
            (puzzle.board.tiles.firstIndex { $0.id == lhs } ?? 0) < (puzzle.board.tiles.firstIndex { $0.id == rhs } ?? 0)
        }
        moves += 1
        isSolved = false
        Haptics.pickUp()
    }

    /// Commits a core `Placement` directly. Used by previews and unit tests to set
    /// up a board state without simulating drags.
    func applyForTesting(_ placement: Placement) {
        placements[placement.tileID] = placement
        rotationByTile[placement.tileID] = placement.rotation
        trayOrder.removeAll { $0 == placement.tileID }
        moves += 1
        evaluateSolved(triggerCallback: true)
    }

    // MARK: - Hint

    /// Places one correct piece from the known solution. Returns the placed tile id.
    @discardableResult
    func useHint() -> String? {
        guard !isSolved else { return nil }
        for solutionPlacement in puzzle.solution where trayOrder.contains(solutionPlacement.tileID) {
            let tileID = solutionPlacement.tileID
            placements[tileID] = solutionPlacement
            rotationByTile[tileID] = solutionPlacement.rotation
            trayOrder.removeAll { $0 == tileID }
            hintsUsed += 1
            moves += 1
            Haptics.place()
            evaluateSolved(triggerCallback: true)
            return tileID
        }
        return nil
    }

    func revealSolution() {
        for solutionPlacement in puzzle.solution {
            placements[solutionPlacement.tileID] = solutionPlacement
            rotationByTile[solutionPlacement.tileID] = solutionPlacement.rotation
        }
        trayOrder.removeAll()
        evaluateSolved(triggerCallback: true)
    }

    // MARK: - Reset & timer

    func reset() {
        placements.removeAll()
        trayOrder = puzzle.board.tiles.map(\.id)
        for tile in puzzle.board.tiles { rotationByTile[tile.id] = .degrees0 }
        moves = 0
        hintsUsed = 0
        elapsedSeconds = 0
        isSolved = false
        selectedTileID = nil
        drag = nil
    }

    func tick() {
        guard !isSolved else { return }
        elapsedSeconds += 1
    }

    private func evaluateSolved(triggerCallback: Bool) {
        let solved = board.isSolved(by: Array(placements.values))
        if solved && !isSolved {
            isSolved = true
            if triggerCallback {
                Haptics.solved()
                onSolved?()
            }
        } else {
            isSolved = solved
        }
    }

    // MARK: - Snapshot

    func snapshot() -> SavedGame {
        SavedGame(
            puzzleID: puzzle.id,
            mode: puzzle.mode,
            placements: Array(placements.values),
            elapsedSeconds: elapsedSeconds,
            moves: moves,
            hintsUsed: hintsUsed
        )
    }

    var formattedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
