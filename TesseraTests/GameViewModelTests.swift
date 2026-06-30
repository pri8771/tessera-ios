import XCTest
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
