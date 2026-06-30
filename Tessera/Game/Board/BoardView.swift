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
    var onPickUpPlaced: (String) -> Void

    var body: some View {
        let colors = theme.colors(for: scheme)
        ZStack(alignment: .topLeading) {
            boardWell(colors)
            emptyCells(colors)
            placedPieces(colors)
            dragPreview(colors)
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
        return Canvas { context, _ in
            for cell in vm.board.surface where !occupied.contains(cell) {
                let rect = geometry.rect(for: cell).insetBy(dx: 1.5, dy: 1.5)
                let radius = geometry.cellSize * Radius.cellFraction
                let path = Path(roundedRect: rect, cornerRadius: radius)
                context.fill(path, with: .color(colors.cellEmpty))
                context.stroke(path, with: .color(colors.gridLine), lineWidth: 1)
            }
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
