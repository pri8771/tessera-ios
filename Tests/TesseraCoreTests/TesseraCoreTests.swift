import XCTest
@testable import TesseraCore

final class TesseraCoreTests: XCTestCase {
    func testPlacementValidationDetectsOverlap() {
        let board = PlaceholderPuzzleFactory.makeIntroBoard()
        let placements = [
            Placement(tileID: "domino", origin: GridPoint(x: 0, y: 0)),
            Placement(tileID: "triomino", origin: GridPoint(x: 0, y: 0))
        ]

        XCTAssertEqual(board.validate(placements), .failure(.overlap(tileID: "triomino", cell: GridPoint(x: 0, y: 0))))
    }

    func testSolvedStateRequiresNoGapsOrOverlaps() {
        let board = PlaceholderPuzzleFactory.makeIntroBoard()
        let placements = [
            Placement(tileID: "domino", origin: GridPoint(x: 0, y: 0), rotation: .degrees90),
            Placement(tileID: "triomino", origin: GridPoint(x: 1, y: 0)),
            Placement(tileID: "monomino", origin: GridPoint(x: 2, y: 0))
        ]

        XCTAssertTrue(board.isSolved(by: placements))
    }

    func testDailySeedIsDeterministicForCalendarDate() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-06-29T18:45:00Z"))
        let sameDay = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-06-29T00:01:00Z"))
        let nextDay = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-06-30T00:00:00Z"))

        XCTAssertEqual(DailySeed(date: date), DailySeed(date: sameDay))
        XCTAssertNotEqual(DailySeed(date: date), DailySeed(date: nextDay))
        XCTAssertEqual(DailySeed(date: date).dateKey, "2026-06-29")
    }
}
