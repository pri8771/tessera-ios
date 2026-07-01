import XCTest
import CoreGraphics
import TesseraCore
@testable import Tessera

@MainActor
final class GameViewModelTests: XCTestCase {

    func testPlacingAllPiecesSolvesTutorial() {
        let puzzle = CuratedPuzzles.tutorialPlace()
        let vm = GameViewModel(puzzle: puzzle)
        var solvedFired = false
        vm.onSolved = { solvedFired = true }

        for placement in puzzle.solution {
            vm.applyForTesting(placement)
        }
        XCTAssertTrue(vm.isSolved)
        XCTAssertTrue(solvedFired)
        XCTAssertEqual(vm.remainingCount, 0)
    }

    func testHintPlacesACorrectPiece() {
        let puzzle = CuratedPuzzles.tutorialRotate()
        let vm = GameViewModel(puzzle: puzzle)
        let before = vm.remainingCount
        let placed = vm.useHint()
        XCTAssertNotNil(placed)
        XCTAssertEqual(vm.remainingCount, before - 1)
        XCTAssertEqual(vm.hintsUsed, 1)
    }

    func testRevealSolutionSolves() {
        let puzzle = CuratedPuzzles.tutorialRotate()
        let vm = GameViewModel(puzzle: puzzle)
        vm.revealSolution()
        XCTAssertTrue(vm.isSolved)
    }

    func testPickUpReturnsPieceToTray() {
        let puzzle = CuratedPuzzles.tutorialPlace()
        let vm = GameViewModel(puzzle: puzzle)
        let first = puzzle.solution[0]
        vm.applyForTesting(first)
        XCTAssertFalse(vm.trayOrder.contains(first.tileID))
        vm.pickUp(placedTileID: first.tileID)
        XCTAssertTrue(vm.trayOrder.contains(first.tileID))
        XCTAssertFalse(vm.isSolved)
    }

    func testTapToPlaceSelectedPiece() {
        let puzzle = CuratedPuzzles.tutorialPlace()
        let vm = GameViewModel(puzzle: puzzle)
        // Select the first tile and place it by "tapping" a cell it legally covers.
        let tileID = puzzle.board.tiles[0].id
        vm.selectedTileID = tileID
        let cell = puzzle.board.surface.sorted().first!
        XCTAssertTrue(vm.placeSelected(coveringBoardCell: cell))
        XCTAssertNotNil(vm.placement(for: tileID))
        XCTAssertFalse(vm.trayOrder.contains(tileID))
    }

    func testTapToPlaceWithNoSelectionDoesNothing() {
        let puzzle = CuratedPuzzles.tutorialPlace()
        let vm = GameViewModel(puzzle: puzzle)
        vm.selectedTileID = nil
        XCTAssertFalse(vm.placeSelected(coveringBoardCell: GridPoint(x: 0, y: 0)))
        XCTAssertEqual(vm.remainingCount, puzzle.board.tiles.count)
    }

    /// Regresses a stuck-ghost bug: a system interruption (call, notification,
    /// Control Center) can cancel a `DragGesture` mid-drag without SwiftUI ever
    /// calling `.onEnded`, leaving `drag` non-nil for the piece that was being
    /// held. Without a tileID check, the next drag on a *different* piece would
    /// hit `updateDrag` instead of `beginDrag` and silently move the stale
    /// piece's ghost — so lifting the finger would commit the wrong piece.
    func testBeginDragOnDifferentTileReplacesStaleDrag() {
        let puzzle = CuratedPuzzles.tutorialPlace()
        let vm = GameViewModel(puzzle: puzzle)
        let geometry = BoardGeometry(surface: puzzle.board.surface, containerSize: CGSize(width: 300, height: 300), inset: 14)

        vm.beginDrag(tileID: "p0", at: CGPoint(x: 50, y: 50), geometry: geometry)
        XCTAssertEqual(vm.drag?.tileID, "p0")

        // Simulate an interruption: no cancelDrag()/endDrag() call happens here,
        // then a fresh drag gesture begins on a different tray piece.
        vm.beginDrag(tileID: "p1", at: CGPoint(x: 80, y: 80), geometry: geometry)

        XCTAssertEqual(vm.drag?.tileID, "p1")
    }

    /// Regresses the most severe gameplay bug found in manual testing: `useHint()`
    /// used to blindly apply `puzzle.solution`'s FIXED placement for the next
    /// tile, which is only valid for the untouched original board. A board can
    /// have more than one valid tiling (this test's two identical dominoes make
    /// that concrete): if the player manually places a tile at a position the
    /// recorded solution assigns to a *different* tile, the stale hint silently
    /// overlaps it — the tray empties to 0 remaining while cells stay uncovered,
    /// and the board can never be detected as solved again. The fix recomputes a
    /// fresh solve of the remaining sub-puzzle on every hint.
    func testUseHintAdaptsToManualPlacementNotMatchingStaleSolution() {
        let surface: Set<GridPoint> = [
            GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0),
            GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1)
        ]
        // Two identical horizontal dominoes: the 2x2 square has (at least) two
        // valid tilings — d1-top/d2-bottom, or d1-bottom/d2-top.
        let d1 = Tile(id: "d1", cells: [GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0)])
        let d2 = Tile(id: "d2", cells: [GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0)])
        let board = Board(surface: surface, tiles: [d1, d2])
        // Recorded "solution": d1 on top, d2 on bottom.
        let solution = [
            Placement(tileID: "d1", origin: GridPoint(x: 0, y: 0)),
            Placement(tileID: "d2", origin: GridPoint(x: 0, y: 1))
        ]
        let puzzle = Puzzle(
            id: "test-swap-tiling", mode: .tutorial, difficulty: .gentle, seed: 1,
            dateKey: nil, board: board, solution: solution
        )
        let vm = GameViewModel(puzzle: puzzle)

        // Manually place d1 on the BOTTOM instead — the swapped, still-fully-valid
        // tiling, which the stale solution does not anticipate for d1.
        vm.applyForTesting(Placement(tileID: "d1", origin: GridPoint(x: 0, y: 1)))

        let hinted = vm.useHint()

        XCTAssertEqual(hinted, "d2")
        XCTAssertEqual(vm.remainingCount, 0)
        XCTAssertTrue(vm.isSolved, "hint must adapt so the board ends fully, validly covered")
    }

    /// Regresses a rotate/drag desync: rotating a tile while it's mid-drag used to
    /// update `rotationByTile` but leave the in-flight `DragState` (ghost preview,
    /// snap, validity) frozen at the OLD orientation — so the ghost would show the
    /// new shape while `endDrag` still committed the stale one on drop.
    func testRotateDuringDragUpdatesInFlightState() {
        let puzzle = CuratedPuzzles.tutorialRotate()
        let vm = GameViewModel(puzzle: puzzle)
        let geometry = BoardGeometry(surface: puzzle.board.surface, containerSize: CGSize(width: 300, height: 300), inset: 14)
        let tileID = puzzle.board.tiles[0].id

        vm.beginDrag(tileID: tileID, at: CGPoint(x: 50, y: 50), geometry: geometry)
        let originalCells = vm.drag?.displayCells
        let originalRotation = vm.drag?.rotation

        vm.rotate(tileID, geometry: geometry)

        XCTAssertEqual(vm.drag?.tileID, tileID, "rotate must not disturb which tile is being dragged")
        XCTAssertEqual(vm.drag?.rotation, vm.rotation(for: tileID), "drag state must track the new rotation")
        XCTAssertNotEqual(vm.drag?.rotation, originalRotation)
        XCTAssertNotEqual(vm.drag?.displayCells, originalCells, "ghost preview must reflect the new orientation")
    }

    /// Regresses a race during the solved-celebration window: without this guard,
    /// a tap landing between `onSolved` firing (which already recorded the
    /// completion) and the overlay appearing ~1.4s later could pull a piece back
    /// into the tray, leaving "Solved" displayed over a board that no longer is.
    func testPickUpBlockedOnceSolved() {
        let puzzle = CuratedPuzzles.tutorialPlace()
        let vm = GameViewModel(puzzle: puzzle)
        for placement in puzzle.solution { vm.applyForTesting(placement) }
        XCTAssertTrue(vm.isSolved)

        let firstTileID = puzzle.solution[0].tileID
        vm.pickUp(placedTileID: firstTileID)

        XCTAssertNotNil(vm.placement(for: firstTileID), "piece must remain placed once solved")
        XCTAssertTrue(vm.isSolved, "solved state must not be disturbed")
    }

    func testResetClearsBoard() {
        let puzzle = CuratedPuzzles.tutorialPlace()
        let vm = GameViewModel(puzzle: puzzle)
        for placement in puzzle.solution { vm.applyForTesting(placement) }
        vm.reset()
        XCTAssertEqual(vm.remainingCount, puzzle.board.tiles.count)
        XCTAssertFalse(vm.isSolved)
        XCTAssertEqual(vm.moves, 0)
    }
}
