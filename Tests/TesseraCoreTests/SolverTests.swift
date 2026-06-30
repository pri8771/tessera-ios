import XCTest
@testable import TesseraCore

/// The locked T2 three-state solver matrix: every return arm exercised, and the
/// two that look alike (`unsolvable` vs `undecided`) proven separable.
final class SolverTests: XCTestCase {
    private let solver = Solver()

    /// Near-cap, genuinely solvable board, generous cap -> `.solvable` with a valid solution.
    func testSolvableBoardReturnsSolvableWithSolution() throws {
        let puzzle = PuzzleGenerator().endlessPuzzle(seed: 4242, difficulty: .deep)
        let result = solver.solve(puzzle.board, limits: .generous)
        XCTAssertEqual(result.outcome, .solvable)
        let solution = try XCTUnwrap(result.solution)
        XCTAssertTrue(puzzle.board.isSolved(by: solution))
    }

    /// Small, genuinely unsolvable board, generous cap -> `.unsolvable` by exhaustion.
    func testUnsolvableBoardReturnsUnsolvable() {
        let surface: Set<GridPoint> = [
            GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0), GridPoint(x: 0, y: 1)
        ]
        // A straight tromino cannot fit an L-shaped 3-cell surface.
        let line = Tile(id: "p0", cells: [
            GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0), GridPoint(x: 2, y: 0)
        ])
        let board = Board(surface: surface, tiles: [line])
        let result = solver.solve(board, limits: .generous)
        XCTAssertEqual(result.outcome, .unsolvable)
        XCTAssertNil(result.solution)
    }

    /// Known-solvable but deep board with a deliberately tiny cap -> `.undecided`.
    /// The same board solves under a generous cap, proving the cap interrupted a
    /// winnable search rather than coinciding with a dead one.
    func testTinyCapOnSolvableBoardReturnsUndecided() {
        let puzzle = PuzzleGenerator().endlessPuzzle(seed: 99, difficulty: .deep)

        let undecided = solver.solve(puzzle.board, limits: Solver.Limits(maxNodes: 1))
        XCTAssertEqual(undecided.outcome, .undecided)
        XCTAssertNil(undecided.solution)

        let solvable = solver.solve(puzzle.board, limits: .generous)
        XCTAssertEqual(solvable.outcome, .solvable)
    }

    /// Repeat-call determinism: identical verdict, first solution, and node count.
    func testRepeatCallDeterminism() {
        let puzzle = PuzzleGenerator().endlessPuzzle(seed: 7, difficulty: .calm)
        let first = solver.solve(puzzle.board, limits: .generous)
        for _ in 0..<5 {
            let again = solver.solve(puzzle.board, limits: .generous)
            XCTAssertEqual(again.outcome, first.outcome)
            XCTAssertEqual(again.solution, first.solution)
            XCTAssertEqual(again.nodesExplored, first.nodesExplored)
        }
    }

    func testEmptySurfaceIsTriviallySolvable() {
        let board = Board(surface: [], tiles: [])
        XCTAssertEqual(solver.solve(board).outcome, .solvable)
    }
}
