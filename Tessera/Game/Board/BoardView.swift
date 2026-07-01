import SwiftUI
import TesseraCore

/// Renders the board surface, placed pieces, the live drag preview, and the
/// "breathing" motion. Pure presentation — all rules live in `GameViewModel`.
struct BoardView: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let vm: GameViewModel
    let geometry: BoardGeometry
    let breathingEnabled: Bool
    var showGridGuides: Bool = true
    var onPickUpPlaced: (String) -> Void
    var onPlaceSelected: (GridPoint) -> Void = { _ in }

    var body: some View {
        let colors = theme.colors(for: scheme)
        ZStack(alignment: .topLeading) {
            boardWell(colors)
            emptyCells(colors)
            placedPieces(colors)
            dragPreview(colors)
            accessibleCellTargets(colors)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Layers

    private func boardWell(_ colors: ThemeColors) -> some View {
        RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
            .fill(colors.boardWell)
            .frame(width: geometry.boardSize.width + Spacing.md,
                   height: geometry.boardSize.height + Spacing.md)
            .position(x: geometry.origin.x + geometry.boardSize.width / 2,
                      y: geometry.origin.y + geometry.boardSize.height / 2)
            .shadow(color: colors.shadow, radius: 8, x: 0, y: 4)
    }

    private func emptyCells(_ colors: ThemeColors) -> some View {
        let occupied = vm.occupiedCells
        let showGridGuides = showGridGuides
        return Canvas { context, _ in
            for cell in vm.board.surface where !occupied.contains(cell) {
                let rect = geometry.rect(for: cell).insetBy(dx: 1.5, dy: 1.5)
                let radius = geometry.cellSize * Radius.cellFraction
                let path = Path(roundedRect: rect, cornerRadius: radius)
                context.fill(path, with: .color(colors.cellEmpty))
                if showGridGuides {
                    context.stroke(path, with: .color(colors.gridLine), lineWidth: 1)
                }
            }
        }
    }

    /// VoiceOver-only per-empty-cell targets. `emptyCells` above is drawn with
    /// `Canvas`, which produces no accessibility nodes at all, and the sighted
    /// placement gesture (`SpatialTapGesture` in `GameView.boardArea`) resolves a
    /// screen-reader "activate" to nothing meaningful, since VoiceOver doesn't
    /// convey *where* on screen a double-tap lands. Each empty cell gets its own
    /// invisible, non-hit-testable element instead, so VoiceOver users can navigate
    /// cell by cell and activate the exact one they want.
    private func accessibleCellTargets(_ colors: ThemeColors) -> some View {
        let occupied = vm.occupiedCells
        let hasSelection = vm.selectedTileID != nil
        return ForEach(Array(vm.board.surface.subtracting(occupied)).sorted(), id: \.self) { cell in
            let rect = geometry.rect(for: cell)
            Color.clear
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .allowsHitTesting(false)
                .accessibilityElement()
                .accessibilityLabel("Empty cell, row \(cell.y + 1), column \(cell.x + 1)")
                .accessibilityAddTraits(hasSelection ? [.isButton] : [])
                .accessibilityHint(hasSelection
                    ? "Places the selected piece here if it fits."
                    : "Select a piece below first.")
                .accessibilityAction { onPlaceSelected(cell) }
        }
    }

    private func placedPieces(_ colors: ThemeColors) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !shouldBreathe)) { timeline in
            let phase = breathingPhase(at: timeline.date)
            ZStack(alignment: .topLeading) {
                ForEach(Array(vm.placements.keys.sorted()), id: \.self) { tileID in
                    if let placement = vm.placement(for: tileID),
                       let absolute = vm.board.absoluteCells(for: placement) {
                        let cells = Array(absolute)
                        let color = theme.tileColor(forPieceIndex: vm.colorIndex(for: tileID))
                        let breath = breathScale(forIndex: vm.colorIndex(for: tileID), phase: phase)
                        TilePieceView(cells: cells, cellSize: geometry.cellSize, color: color, isPlaced: true)
                            .position(piecePosition(for: cells))
                            .scaleEffect(breath)
                            .onTapGesture { onPickUpPlaced(tileID) }
                            .accessibilityElement()
                            .accessibilityLabel("Placed piece, \(cells.count) cells")
                            .accessibilityHint("Double tap to pick it back up.")
                            .accessibilityAction { onPickUpPlaced(tileID) }
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dragPreview(_ colors: ThemeColors) -> some View {
        if let drag = vm.drag, let origin = drag.snappedOrigin {
            let cells = vm.boardCells(tileID: drag.tileID, rotation: drag.rotation, displayOrigin: origin)
            let valid = drag.isValid
            Canvas { context, _ in
                for cell in cells {
                    let rect = geometry.rect(for: cell).insetBy(dx: 2, dy: 2)
                    let radius = geometry.cellSize * Radius.cellFraction
                    let path = Path(roundedRect: rect, cornerRadius: radius)
                    let tint = valid ? colors.success : colors.accent
                    context.fill(path, with: .color(tint.opacity(0.28)))
                    context.stroke(path, with: .color(tint.opacity(0.9)), lineWidth: 2)
                }
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: - Helpers

    private var shouldBreathe: Bool { breathingEnabled && !reduceMotion }

    private func piecePosition(for cells: [GridPoint]) -> CGPoint {
        let minX = cells.map(\.x).min() ?? 0
        let minY = cells.map(\.y).min() ?? 0
        let cols = (cells.map(\.x).max() ?? 0) - minX + 1
        let rows = (cells.map(\.y).max() ?? 0) - minY + 1
        let topLeft = geometry.point(for: GridPoint(x: minX, y: minY))
        return CGPoint(
            x: topLeft.x + CGFloat(cols) * geometry.cellSize / 2,
            y: topLeft.y + CGFloat(rows) * geometry.cellSize / 2
        )
    }

    private func breathingPhase(at date: Date) -> Double {
        guard shouldBreathe else { return 0 }
        return date.timeIntervalSinceReferenceDate
    }

    private func breathScale(forIndex index: Int, phase: Double) -> CGFloat {
        guard shouldBreathe else { return 1 }
        let offset = Double(index) * 0.9
        let wave = sin((phase * 0.7) + offset)
        return 1 + CGFloat(wave) * 0.01
    }
}
