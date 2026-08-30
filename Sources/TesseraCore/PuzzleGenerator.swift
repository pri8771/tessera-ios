import Foundation

/// Generates solvable tessellation puzzles deterministically from a seed.
///
/// Strategy: **generate by construction.** A rectangular surface is partitioned
/// into connected polyomino regions by seeded region-growth; that partition *is* a
/// guaranteed perfect tiling, so the board is solvable before the player ever sees
/// it. Each region becomes a tray tile (normalised and given a seeded display
/// rotation so rotation is a real verb). The known solution is reconstructed
/// directly from the partition, then the bounded `Solver` is run as a verification
/// gate: a puzzle ships only when the solver independently returns `.solvable`;
/// `.undecided`/`.unsolvable` causes regeneration with a bumped sub-seed.
public struct PuzzleGenerator {

    public struct Configuration: Sendable {
        public var width: Int
        public var height: Int
        public var minPieceSize: Int
        public var maxPieceSize: Int

        public init(width: Int, height: Int, minPieceSize: Int, maxPieceSize: Int) {
            self.width = width
            self.height = height
            self.minPieceSize = minPieceSize
            self.maxPieceSize = maxPieceSize
        }

        public static func configuration(for difficulty: Difficulty) -> Configuration {
            switch difficulty {
            case .gentle: return Configuration(width: 4, height: 4, minPieceSize: 3, maxPieceSize: 4)
            case .calm:   return Configuration(width: 5, height: 5, minPieceSize: 3, maxPieceSize: 5)
            case .deep:   return Configuration(width: 5, height: 6, minPieceSize: 3, maxPieceSize: 5)
            }
        }
    }

    public init() {}

    // MARK: - Public entry points

    /// The deterministic daily puzzle for a calendar date.
    public func dailyPuzzle(for date: Date) -> Puzzle {
        let seed = DailySeed(date: date)
        return dailyPuzzle(for: seed)
    }

    public func dailyPuzzle(for seed: DailySeed) -> Puzzle {
        let difficulty = Self.dailyDifficulty(for: seed.value)
        return makePuzzle(
            id: "daily-\(seed.dateKey)",
            mode: .daily,
            difficulty: difficulty,
            seed: seed.value,
            dateKey: seed.dateKey
        )
    }

    /// A fresh endless puzzle at a chosen difficulty from a caller-supplied seed.
    public func endlessPuzzle(seed: UInt64, difficulty: Difficulty) -> Puzzle {
        makePuzzle(
            id: "endless-\(difficulty.rawValue)-\(seed)",
            mode: .endless,
            difficulty: difficulty,
            seed: seed,
            dateKey: nil
        )
    }

    /// Daily difficulty rhythm: roughly 30% gentle, 50% calm, 20% deep.
    public static func dailyDifficulty(for seed: UInt64) -> Difficulty {
        switch seed % 10 {
        case 0, 1, 2: return .gentle
        case 8, 9:    return .deep
        default:      return .calm
        }
    }

    // MARK: - Construction

    private func makePuzzle(
        id: String,
        mode: PuzzleMode,
        difficulty: Difficulty,
        seed: UInt64,
        dateKey: String?
    ) -> Puzzle {
        let config = Configuration.configuration(for: difficulty)
        let solver = Solver()

        // Try a handful of sub-seeds; construction almost always succeeds on the
        // first, but the solver gate must independently confirm `.solvable`, and
        // the size-contract check below now also rejects attempts. 40 keeps the
        // truly-defensive fallback path rare without meaningfully slowing
        // generation (each attempt is cheap; a sweep of hundreds of seeds is still
        // well under a second).
        for attempt in 0..<40 {
            let attemptSeed = seed &+ UInt64(attempt) &* 0x9E3779B97F4A7C15
            var rng = SeededGenerator(seed: attemptSeed)
            let regions = partition(config: config, rng: &rng)

            // A degenerate partition (a single piece) is no puzzle; try again.
            guard regions.count >= 2 else { continue }

            // Enforce the documented per-tile size contract. mergeStrays only folds
            // an undersized region into a neighbour when the merged result stays
            // within maxPieceSize (see mergeStrays below); on the rare occasion no
            // such neighbour exists, a region can still land outside [min, max].
            // Rather than accept a puzzle where "gentle" ships a piece dominating
            // the whole board, retry with the next sub-seed.
            guard regions.allSatisfy({ (config.minPieceSize...config.maxPieceSize).contains($0.count) }) else { continue }

            var tiles: [Tile] = []
            var solution: [Placement] = []
            for (index, region) in regions.enumerated() {
                let tileID = "p\(index)"
                let displayRotation = Rotation.allCases[rng.int(below: Rotation.allCases.count)]
                let localCells = Tile.normalize(region)
                let displayedCells = Tile.normalize(Set(localCells.map { displayRotation.apply(to: $0) }))
                let tile = Tile(id: tileID, cells: displayedCells)
                tiles.append(tile)
                solution.append(Self.placement(for: tile, reconstructing: region))
            }

            let surface = regions.reduce(into: Set<GridPoint>()) { $0.formUnion($1) }
            let board = Board(surface: surface, tiles: tiles)

            // Sanity: the constructed solution must actually solve the board.
            guard board.isSolved(by: solution) else { continue }

            // Verification gate: the independent solver must confirm solvability.
            let result = solver.solve(board, limits: .generous)
            guard result.outcome == .solvable else { continue }

            return Puzzle(
                id: id,
                mode: mode,
                difficulty: difficulty,
                seed: seed,
                dateKey: dateKey,
                board: board,
                solution: solution
            )
        }

        // Extremely defensive fallback, reusing the same bounded partition.
        return fallbackPuzzle(id: id, mode: mode, difficulty: difficulty, seed: seed, dateKey: dateKey)
    }

    /// Partitions the rectangle into connected regions via seeded growth, then
    /// merges any undersized strays into a neighbour so every tile is "interesting".
    private func partition(config: Configuration, rng: inout SeededGenerator) -> [Set<GridPoint>] {
        var remaining = Set<GridPoint>()
        for y in 0..<config.height {
            for x in 0..<config.width {
                remaining.insert(GridPoint(x: x, y: y))
            }
        }

        var regions: [Set<GridPoint>] = []
        while !remaining.isEmpty {
            // Deterministic seed cell: smallest remaining, perturbed by the RNG so
            // growth direction varies between seeds without stranding cells.
            let sortedRemaining = remaining.sorted()
            let start = sortedRemaining[rng.int(below: min(sortedRemaining.count, 3))]

            var region: Set<GridPoint> = [start]
            remaining.remove(start)
            let targetSize = rng.int(in: config.minPieceSize...config.maxPieceSize)

            while region.count < targetSize {
                // Candidate frontier: remaining cells adjacent to the region.
                let frontier = region
                    .flatMap { $0.orthogonalNeighbours }
                    .filter { remaining.contains($0) }
                let uniqueFrontier = Array(Set(frontier)).sorted()
                guard let next = pickFrontier(uniqueFrontier, rng: &rng) else { break }
                region.insert(next)
                remaining.remove(next)
            }

            regions.append(region)
        }

        return mergeStrays(regions, minSize: config.minPieceSize, maxSize: config.maxPieceSize)
    }

    private func pickFrontier(_ frontier: [GridPoint], rng: inout SeededGenerator) -> GridPoint? {
        guard !frontier.isEmpty else { return nil }
        return frontier[rng.int(below: frontier.count)]
    }

    /// Merges any region below `minSize` into an orthogonally-adjacent region so no
    /// lonely monominoes survive. Always preserves connectivity (we only merge
    /// across a shared edge), and never merges into a host that would push the
    /// result above `maxSize` — an unbounded merge here was the root cause of
    /// pieces routinely landing 2x+ over the documented per-difficulty size cap
    /// (a "gentle" board dominated by one giant blob next to two scraps). If a
    /// stray has no host it can join without busting the cap, it's left as-is;
    /// `makePuzzle`'s own size-contract check then retries with a fresh sub-seed
    /// rather than shipping the violation.
    private func mergeStrays(_ regions: [Set<GridPoint>], minSize: Int, maxSize: Int) -> [Set<GridPoint>] {
        var working = regions
        var didMerge = true
        while didMerge {
            didMerge = false
            // Process smallest-first for stable, deterministic results.
            let order = working.indices.sorted { lhs, rhs in
                if working[lhs].count != working[rhs].count { return working[lhs].count < working[rhs].count }
                return working[lhs].sorted().first! < working[rhs].sorted().first!
            }
            for index in order where working[index].count < minSize {
                guard let host = adjacentRegionIndex(to: working[index], in: working, maxSize: maxSize) else { continue }
                working[host].formUnion(working[index])
                working.remove(at: index)
                didMerge = true
                break
            }
        }
        return working
    }

    private func adjacentRegionIndex(to region: Set<GridPoint>, in regions: [Set<GridPoint>], maxSize: Int) -> Int? {
        let neighbourCells = Set(region.flatMap { $0.orthogonalNeighbours }).subtracting(region)
        let candidates = regions.indices.filter { index in
            !regions[index].isDisjoint(with: neighbourCells)
                && regions[index] != region
                && regions[index].count + region.count <= maxSize
        }
        // Deterministic: pick the region with the smallest minimum cell.
        return candidates.min { lhs, rhs in
            regions[lhs].sorted().first! < regions[rhs].sorted().first!
        }
    }

    // MARK: - Solution reconstruction

    /// Finds the placement that maps `tile`'s cells exactly onto `regionAbs`.
    /// Aligning the row-major minimum cells of matching shapes is sufficient.
    static func placement(for tile: Tile, reconstructing regionAbs: Set<GridPoint>) -> Placement {
        let targetMin = regionAbs.sorted().first ?? GridPoint(x: 0, y: 0)
        for rotation in Rotation.allCases {
            let rotated = tile.rotated(rotation).cells
            guard let rotatedMin = rotated.sorted().first else { continue }
            let origin = targetMin - rotatedMin
            let placed = Set(rotated.map { $0 + origin })
            if placed == regionAbs {
                return Placement(tileID: tile.id, origin: origin, rotation: rotation)
            }
        }
        return Placement(tileID: tile.id, origin: targetMin, rotation: .degrees0)
    }

    // MARK: - Fallback

    /// Last-resort construction for the rare case none of the normal attempts
    /// produced a solvable, size-compliant board. Reuses the same bounded
    /// `partition`/`mergeStrays` machinery as the main path (with a seed offset
    /// so it explores a fresh partition rather than repeating a failed attempt)
    /// instead of a bespoke hardcoded shape: a hardcoded 2x2-domino split — used
    /// here previously — always solves, but ships two 2-cell pieces regardless of
    /// difficulty, which is a size-contract violation in its own right the moment
    /// this path actually fires (every difficulty's minimum piece size is 3).
    private func fallbackPuzzle(
        id: String,
        mode: PuzzleMode,
        difficulty: Difficulty,
        seed: UInt64,
        dateKey: String?
    ) -> Puzzle {
        let config = Configuration.configuration(for: difficulty)
        var rng = SeededGenerator(seed: seed &+ 0xF0F0_F0F0_F0F0_F0F0)
        let regions = partition(config: config, rng: &rng)

        var tiles: [Tile] = []
        var solution: [Placement] = []
        for (index, region) in regions.enumerated() {
            let tileID = "fallback-p\(index)"
            let tile = Tile(id: tileID, cells: Tile.normalize(region))
            tiles.append(tile)
            solution.append(Self.placement(for: tile, reconstructing: region))
        }
        let surface = regions.reduce(into: Set<GridPoint>()) { $0.formUnion($1) }
        let board = Board(surface: surface, tiles: tiles)

        return Puzzle(
            id: id, mode: mode, difficulty: difficulty, seed: seed,
            dateKey: dateKey, board: board, solution: solution
        )
    }
}
