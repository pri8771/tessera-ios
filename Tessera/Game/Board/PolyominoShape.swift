import SwiftUI
import TesseraCore

/// Draws a polyomino as the union of per-cell rounded rectangles. Same-colour
/// adjacent cells merge visually into one soft, gallery-like piece, while the
/// rounded corners keep the "living jigsaw" feel.
struct PolyominoShape: Shape {
    /// Cells in local coordinates (any integer offsets).
    let cells: [GridPoint]
    let cellSize: CGFloat
    /// Gap between a cell's edge and its drawn rounded rect (visual breathing room).
    var inset: CGFloat = 1.0

    func path(in rect: CGRect) -> Path {
        guard !cells.isEmpty else { return Path() }
        let minX = cells.map(\.x).min() ?? 0
        let minY = cells.map(\.y).min() ?? 0
        let radius = cellSize * Radius.cellFraction

        var path = Path()
        for cell in cells {
            let x = CGFloat(cell.x - minX) * cellSize + inset
            let y = CGFloat(cell.y - minY) * cellSize + inset
            let side = cellSize - inset * 2
            let cellRect = CGRect(x: x, y: y, width: side, height: side)
            path.addRoundedRect(in: cellRect, cornerSize: CGSize(width: radius, height: radius))
        }
        return path
    }

    /// The pixel size of this shape's bounding box at the given cell size.
    static func size(for cells: [GridPoint], cellSize: CGFloat) -> CGSize {
        guard !cells.isEmpty else { return .zero }
        let xs = cells.map(\.x)
        let ys = cells.map(\.y)
        let cols = (xs.max() ?? 0) - (xs.min() ?? 0) + 1
        let rows = (ys.max() ?? 0) - (ys.min() ?? 0) + 1
        return CGSize(width: CGFloat(cols) * cellSize, height: CGFloat(rows) * cellSize)
    }
}

/// A filled, softly shaded polyomino piece used in the tray and as placed tiles.
struct TilePieceView: View {
    let cells: [GridPoint]
    let cellSize: CGFloat
    let color: Color
    var isPlaced: Bool = false

    var body: some View {
        let shape = PolyominoShape(cells: cells, cellSize: cellSize)
        shape
            .fill(
                LinearGradient(
                    colors: [color.opacity(isPlaced ? 0.98 : 1.0), color.opacity(0.82)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                shape.stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .frame(
                width: PolyominoShape.size(for: cells, cellSize: cellSize).width,
                height: PolyominoShape.size(for: cells, cellSize: cellSize).height
            )
    }
}
