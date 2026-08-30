import Foundation

/// The three-state verdict of a bounded solve.
///
/// The distinction is the correctness lynchpin of the daily puzzle: a search that
/// hits its node budget has proven *nothing*, so `.undecided` must never be
/// conflated with `.unsolvable`. Daily generation accepts only `.solvable`,
/// rejects `.unsolvable`, and regenerates on `.undecided`.
public enum SolveOutcome: Equatable, Sendable {
    /// At least one exact tiling exists (a concrete solution is attached to `SolveResult`).
    case solvable
    /// The search space was fully exhausted with no tiling — proven impossible.
    case unsolvable
    /// The node budget was exhausted before a solution or full exhaustion. No proof either way.
    case undecided
}

public struct SolveResult: Equatable, Sendable {
    public let outcome: SolveOutcome
    /// A concrete winning placement set, present iff `outcome == .solvable`.
    public let solution: [Placement]?
    public let nodesExplored: Int

    public init(outcome: SolveOutcome, solution: [Placement]?, nodesExplored: Int) {
        self.outcome = outcome
        self.solution = solution
        self.nodesExplored = nodesExplored
    }
}

/// A bounded, fully-deterministic exact-cover solver for tessellation boards.
///
/// Algorithm: backtracking DFS over the **first uncovered cell** in stable
/// row-major order. Branching only on placements that cover that specific cell is
/// the classic polyomino exact-cover ordering — every branch is forced to make
/// progress on a concrete target, which keeps the branching factor tight and the
/// per-node cost low. It still fails fast: if the target cell has zero legal
/// placements the branch dies immediately. Occupancy is a `UInt64` bitmask over
/// surface-cell indices (boards are ≤64 cells), and all ordering — cell selection,
/// candidate ordering, tie-breaks — is by stable grid coordinate and tile id,
/// never by `Set`/`Dictionary` iteration order, so the same board always yields
/// the same verdict and the same first solution.
public struct Solver {
    public struct Limits: Sendable {
        /// Maximum number of search nodes (placement attempts) before returning `.undecided`.
        public var maxNodes: Int
        public init(maxNodes: Int = 300_000) {
            self.maxNodes = maxNodes
        }
        public static let `default` = Limits()
        public static let generous = Limits(maxNodes: 1_000_000)
    }

    public init() {}

    /// Returns whether the board can be tiled, with a concrete solution when solvable.
    public func solve(_ board: Board, limits: Limits = .default) -> SolveResult {
        var engine = Engine(board: board, maxNodes: limits.maxNodes, stopAtFirst: true)
        engine.run()
        return SolveResult(
            outcome: engine.outcome,
            solution: engine.firstSolution,
            nodesExplored: engine.nodes
        )
    }

    /// Counts solutions up to `limit` (used for future uniqueness heuristics and tests).
    /// Returns `nil` if the node budget was exhausted before the count could complete.
    public func countSolutions(_ board: Board, upTo limit: Int = 2, limits: Limits = .generous) -> Int? {
        var engine = Engine(board: board, maxNodes: limits.maxNodes, stopAtFirst: false, solutionCap: limit)
        engine.run()
        return engine.outcome == .undecided ? nil : engine.solutionCount
    }

    // MARK: - Search engine

    /// Maximum surface size the bitmask engine can represent (one `UInt64` bit per cell).
    /// Every v1 board is far smaller; larger boards return `.undecided` rather than
    /// silently mis-solving.
    public static let maxSupportedCells = 64

    /// A precomputed legal placement: the tile it uses, the cells it covers (as a
    /// bitmask over surface-cell indices), and the concrete `Placement` for the UI.
    private struct PlacementOption {
        let tileIndex: Int
        let mask: UInt64
        let placement: Placement
    }

    private struct Engine {
        let maxNodes: Int
        let stopAtFirst: Bool
        let solutionCap: Int

        let cellCount: Int
        let fullMask: UInt64
        let oversized: Bool
        /// Sum of tile areas; if it is below the surface area the board can never
        /// be covered (each tile is used at most once).
        let coverable: Bool
        /// For each surface-cell index, the legal placements covering it, in
        /// deterministic order. Branching consults only the lowest uncovered cell.
        let optionsByCell: [[PlacementOption]]

        var occupied: UInt64 = 0
        var usedTiles: UInt64 = 0
        var current: [Placement] = []

        var nodes = 0
        var capHit = false
        var solutionCount = 0
        var firstSolution: [Placement]?

        init(board: Board, maxNodes: Int, stopAtFirst: Bool, solutionCap: Int = 1) {
            self.maxNodes = maxNodes
            self.stopAtFirst = stopAtFirst
            self.solutionCap = solutionCap

            let surface = board.surface.sorted()
            self.cellCount = surface.count
            self.oversized = surface.count > Solver.maxSupportedCells
            self.coverable = board.tilesArea >= board.surfaceArea

            if surface.isEmpty {
                self.fullMask = 0
            } else if surface.count >= 64 {
                self.fullMask = ~UInt64(0)
            } else {
                self.fullMask = (UInt64(1) << UInt64(surface.count)) - 1
            }

            // Index every surface cell once; bit `i` ⇒ `surface[i]`.
            var cellToIndex: [GridPoint: Int] = [:]
            cellToIndex.reserveCapacity(surface.count)
            for (index, cell) in surface.enumerated() { cellToIndex[cell] = index }

            // Tiles in stable id order so the solver verdict and first solution are
            // deterministic regardless of tray ordering.
            let tiles = board.tiles.sorted { $0.id < $1.id }
            var options: [[PlacementOption]] = Array(repeating: [], count: surface.count)

            if !oversized {
                for (tileIndex, tile) in tiles.enumerated() {
                    for orientation in tile.distinctOrientations {
                        let rotation = orientation.rotation
                        // Normalised cells (min at origin) drive the mask…
                        let normalizedCells = orientation.cells.sorted()
                        // …but a recorded `Placement` re-expands via the *un-normalised*
                        // `tile.rotated(rotation)`, so the placement origin must subtract
                        // that rotation's component-wise offset to land on the same cells.
                        let rotatedCells = tile.rotated(rotation).cells
                        let offset = GridPoint(
                            x: rotatedCells.map(\.x).min() ?? 0,
                            y: rotatedCells.map(\.y).min() ?? 0
                        )
                        for placePoint in surface {
                            var mask: UInt64 = 0
                            var legal = true
                            for cell in normalizedCells {
                                guard let bit = cellToIndex[cell + placePoint] else { legal = false; break }
                                mask |= (UInt64(1) << UInt64(bit))
                            }
                            guard legal else { continue }
                            let option = PlacementOption(
                                tileIndex: tileIndex,
                                mask: mask,
                                placement: Placement(tileID: tile.id, origin: placePoint - offset, rotation: rotation)
                            )
                            // Register the option under every cell it covers.
                            var remaining = mask
                            while remaining != 0 {
                                let bit = remaining.trailingZeroBitCount
                                options[bit].append(option)
                                remaining &= remaining - 1
                            }
                        }
                    }
                }
            }
            self.optionsByCell = options
        }

        var outcome: SolveOutcome {
            // Check capHit first. For `solve()` (stopAtFirst=true) these two can
            // never both be true — finding a solution unwinds immediately, before
            // any later node-budget check — so this reordering doesn't change that
            // path. It matters for `countSolutions()` (stopAtFirst=false), which
            // keeps searching past the first solution: there, a run can have
            // solutionCount > 0 *and* capHit if the budget expired while still
            // looking for more. Reporting `.solvable` in that case would hand back
            // a partial count as if it were the final, exact answer — exactly the
            // "undecided must never be conflated with a definite result" bug the
            // three-state contract exists to prevent.
            if capHit { return .undecided }
            if firstSolution != nil || solutionCount > 0 { return .solvable }
            return .unsolvable
        }

        mutating func run() {
            if oversized { capHit = true; return }       // can't represent → undecided
            if cellCount == 0 { firstSolution = []; solutionCount = 1; return }
            guard coverable else { return }              // tiles can't cover surface → unsolvable
            _ = backtrack()
        }

        /// Returns `true` to request the whole search unwind (solution found in
        /// first-only mode, or cap hit) so callers stop immediately.
        mutating func backtrack() -> Bool {
            if occupied == fullMask {
                if firstSolution == nil { firstSolution = current }
                solutionCount += 1
                return stopAtFirst || solutionCount >= solutionCap
            }

            // Lowest uncovered cell index — the forced branch target.
            let free = ~occupied & fullMask
            let target = free.trailingZeroBitCount

            for option in optionsByCell[target] {
                if usedTiles & (UInt64(1) << UInt64(option.tileIndex)) != 0 { continue }
                if option.mask & occupied != 0 { continue }

                nodes += 1
                if nodes > maxNodes {
                    capHit = true
                    return true
                }

                usedTiles |= (UInt64(1) << UInt64(option.tileIndex))
                occupied |= option.mask
                current.append(option.placement)

                let shouldUnwind = backtrack()

                current.removeLast()
                occupied &= ~option.mask
                usedTiles &= ~(UInt64(1) << UInt64(option.tileIndex))

                if shouldUnwind { return true }
            }
            return false
        }
    }
}
