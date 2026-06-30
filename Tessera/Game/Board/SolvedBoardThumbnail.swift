import SwiftUI
import TesseraCore

/// A compact, non-interactive render of a puzzle's solution. Used in the archive
/// grid and the share card. Colours match the active theme's tile palette.
struct SolvedBoardThumbnail: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme

    let puzzle: Puzzle
    /// Use the puzzle's known solution by default; pass custom placements to show
    /// an in-progress or empty board.
    var placements: [Placement]?

    var body: some View {
        let colors = theme.colors(for: scheme)
        GeometryReader { geo in
            let geometry = BoardGeometry(surface: puzzle.board.surface, containerSize: geo.size, inset: 4)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .fill(colors.boardWell)

                Canvas { context, _ in
                    for cell in puzzle.board.surface {
                        let rect = geometry.rect(for: cell).insetBy(dx: 1, dy: 1)
                        let path = Path(roundedRect: rect, cornerRadius: geometry.cellSize * Radius.cellFraction)
                        context.fill(path, with: .color(colors.cellEmpty))
                    }
                }

                let shown = placements ?? puzzle.solution
                ForEach(Array(shown.enumerated()), id: \.offset) { _, placement in
                    if let cells = puzzle.board.absoluteCells(for: placement) {
                        let index = puzzle.board.tiles.firstIndex { $0.id == placement.tileID } ?? 0
                        let color = theme.tileColor(forPieceIndex: index)
                        TilePieceView(cells: Array(cells), cellSize: geometry.cellSize, color: color, isPlaced: true)
                            .position(center(of: Array(cells), geometry: geometry))
                    }
                }
            }
        }
        .aspectRatio(aspect, contentMode: .fit)
    }

    private var aspect: CGFloat {
        let dims = puzzle.dimensions
        guard dims.height > 0 else { return 1 }
        return CGFloat(dims.width) / CGFloat(dims.height)
    }

    private func center(of cells: [GridPoint], geometry: BoardGeometry) -> CGPoint {
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
}
