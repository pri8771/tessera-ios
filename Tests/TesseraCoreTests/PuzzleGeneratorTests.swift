import XCTest
@testable import TesseraCore

final class PuzzleGeneratorTests: XCTestCase {
    private let generator = PuzzleGenerator()

    func testDailyPuzzleIsDeterministicForDate() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-06-30T10:00:00Z"))
        let a = generator.dailyPuzzle(for: date)
        let b = generator.dailyPuzzle(for: date)
        XCTAssertEqual(a.board, b.board)
        XCTAssertEqual(a.solution, b.solution)
        XCTAssertEqual(a.dateKey, "2026-06-30")
    }

    func testGeneratedDailyPuzzlesAreAlwaysSolvable() throws {
        let formatter = ISO8601DateFormatter()
        // Sweep a month of dates. The generator already runs the solver gate, so
        // validating the stored solution here (cheap, O(area)) is sufficient proof.
        for day in 1...28 {
            let key = String(format: "2026-07-%02dT09:00:00Z", day)
            let date = try XCTUnwrap(formatter.date(from: key))
            let puzzle = generator.dailyPuzzle(for: date)

            XCTAssertGreaterThanOrEqual(puzzle.pieceCount, 2, "\(puzzle.id) too few pieces")
            XCTAssertTrue(puzzle.board.isSolved(by: puzzle.solution), "\(puzzle.id) stored solution invalid")
            XCTAssertEqual(puzzle.board.surfaceArea, puzzle.board.tilesArea, "\(puzzle.id) area mismatch")
            for tile in puzzle.board.tiles {
                XCTAssertTrue(tile.isConnected, "\(puzzle.id) tile \(tile.id) not connected")
            }
        }
    }

    func testEndlessPuzzlesAreSolvableAcrossDifficulties() {
        let solver = Solver()
        for difficulty in Difficulty.allCases {
            for seed in stride(from: UInt64(1), through: 15, by: 1) {
                let puzzle = generator.endlessPuzzle(seed: seed, difficulty: difficulty)
                XCTAssertTrue(
                    puzzle.board.isSolved(by: puzzle.solution),
                    "endless \(difficulty) seed \(seed) stored solution invalid"
                )
                if seed % 5 == 0 {
                    XCTAssertEqual(
                        solver.solve(puzzle.board, limits: .generous).outcome,
                        .solvable,
                        "endless \(difficulty) seed \(seed) not solver-solvable"
                    )
                }
            }
        }
    }

    func testEndlessPuzzleDeterministicForSeed() {
        let a = generator.endlessPuzzle(seed: 12345, difficulty: .calm)
        let b = generator.endlessPuzzle(seed: 12345, difficulty: .calm)
        XCTAssertEqual(a.board, b.board)
        XCTAssertEqual(a.solution, b.solution)
    }
}
