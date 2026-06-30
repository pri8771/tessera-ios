import Foundation

/// Hand-authored puzzles used for the tutorial and as deterministic fixtures.
///
/// These intentionally escalate in difficulty so the first-run experience teaches
/// place → rotate → complete without a generator in the loop.
public enum CuratedPuzzles {

    /// Tutorial step 1 — a 2x3 surface, three simple pieces. Teaches placement.
    public static func tutorialPlace() -> Puzzle {
        let surface = rectangle(width: 3, height: 2)
        let domino = Tile(id: "p0", cells: [GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0)])
        let trio = Tile(id: "p1", cells: [GridPoint(x: 0, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1)])
        let mono = Tile(id: "p2", cells: [GridPoint(x: 0, y: 0)])
        let board = Board(surface: surface, tiles: [domino, trio, mono])
        let solution = [
            Placement(tileID: "p0", origin: GridPoint(x: 0, y: 0), rotation: .degrees90),
            Placement(tileID: "p1", origin: GridPoint(x: 1, y: 0), rotation: .degrees0),
            Placement(tileID: "p2", origin: GridPoint(x: 2, y: 0), rotation: .degrees0)
        ]
        return Puzzle(
            id: "tutorial-1", mode: .tutorial, difficulty: .gentle, seed: 1,
            dateKey: nil, board: board, solution: solution
        )
    }

    /// Tutorial step 2 — a 3x3 surface needing a rotation to fit the L-piece. Teaches rotation.
    public static func tutorialRotate() -> Puzzle {
        let surface = rectangle(width: 3, height: 3)
        let lPiece = Tile(id: "p0", cells: [
            GridPoint(x: 0, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1)
        ])
        let line = Tile(id: "p1", cells: [
            GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0), GridPoint(x: 2, y: 0)
        ])
        let bend = Tile(id: "p2", cells: [
            GridPoint(x: 1, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1)
        ])
        let board = Board(surface: surface, tiles: [lPiece, line, bend])
        // Derive a guaranteed solution with the solver so the fixture stays correct
        // even if the shapes above are tweaked.
        let solution = Solver().solve(board, limits: .generous).solution ?? []
        return Puzzle(
            id: "tutorial-2", mode: .tutorial, difficulty: .gentle, seed: 2,
            dateKey: nil, board: board, solution: solution
        )
    }

    public static func tutorialSequence() -> [Puzzle] {
        [tutorialPlace(), tutorialRotate()]
    }

    public static func rectangle(width: Int, height: Int) -> Set<GridPoint> {
        var cells = Set<GridPoint>()
        for y in 0..<height {
            for x in 0..<width {
                cells.insert(GridPoint(x: x, y: y))
            }
        }
        return cells
    }
}

/// Retained for backwards compatibility with the original scaffold tests, which
/// reference the `domino` / `triomino` / `monomino` tile ids directly.
public enum PlaceholderPuzzleFactory {
    public static func makeIntroBoard() -> Board {
        let surface = CuratedPuzzles.rectangle(width: 3, height: 2)
        let domino = Tile(id: "domino", cells: [GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0)])
        let triomino = Tile(id: "triomino", cells: [GridPoint(x: 0, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1)])
        let monomino = Tile(id: "monomino", cells: [GridPoint(x: 0, y: 0)])
        return Board(surface: surface, tiles: [domino, triomino, monomino])
    }
}
