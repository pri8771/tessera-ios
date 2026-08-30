import XCTest
@testable import TesseraCore

final class GeometryTests: XCTestCase {
    func testRotationFourTurnsReturnsToStart() {
        let point = GridPoint(x: 2, y: 1)
        let result = Rotation.degrees90.apply(to: Rotation.degrees90.apply(to: Rotation.degrees90.apply(to: Rotation.degrees90.apply(to: point))))
        XCTAssertEqual(result, point)
    }

    func testDistinctOrientationsDeduplicatesSymmetry() {
        let square = Tile(id: "sq", cells: [
            GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0),
            GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1)
        ])
        XCTAssertEqual(square.distinctOrientations.count, 1)

        let lPiece = Tile(id: "l", cells: [
            GridPoint(x: 0, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1)
        ])
        XCTAssertEqual(lPiece.distinctOrientations.count, 4)
    }

    func testTileConnectivity() {
        let connected = Tile(id: "c", cells: [GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0)])
        XCTAssertTrue(connected.isConnected)
        let split = Tile(id: "s", cells: [GridPoint(x: 0, y: 0), GridPoint(x: 2, y: 0)])
        XCTAssertFalse(split.isConnected)
    }
}

final class DailySeedExtraTests: XCTestCase {
    func testDailySeedFromKeyMatchesDateInit() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-06-29T12:00:00Z"))
        XCTAssertEqual(DailySeed(date: date), DailySeed(dateKey: "2026-06-29"))
    }
}

final class CuratedPuzzlesTests: XCTestCase {
    func testCuratedTutorialSolutionsSolveTheirBoards() {
        for puzzle in CuratedPuzzles.tutorialSequence() {
            XCTAssertFalse(puzzle.solution.isEmpty, "\(puzzle.id) has no solution")
            XCTAssertTrue(puzzle.board.isSolved(by: puzzle.solution), "\(puzzle.id) solution does not solve board")
        }
    }

    func testOutOfBoundsPlacementFails() {
        let board = CuratedPuzzles.tutorialPlace().board
        let result = board.validate([Placement(tileID: "p1", origin: GridPoint(x: 5, y: 5))])
        if case .failure(.outOfBounds) = result {} else {
            XCTFail("expected out-of-bounds failure, got \(result)")
        }
    }

    func testDuplicateTilePlacementFails() {
        let board = CuratedPuzzles.tutorialPlace().board
        let result = board.validate([
            Placement(tileID: "p0", origin: GridPoint(x: 0, y: 0)),
            Placement(tileID: "p0", origin: GridPoint(x: 0, y: 1))
        ])
        XCTAssertEqual(result, .failure(.duplicateTile("p0")))
    }
}
