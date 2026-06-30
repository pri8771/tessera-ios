import CoreGraphics
import TesseraCore

/// Maps between logical grid cells and view-space points for one board layout.
///
/// The surface is measured to a bounding box, then centred within the available
/// size at a uniform cell size. Conversions are pure so they're trivial to reason
/// about and reuse for hit-testing, drawing, and drag snapping.
struct BoardGeometry {
    let minX: Int
    let minY: Int
    let columns: Int
    let rows: Int
    let cellSize: CGFloat
    let origin: CGPoint  // top-left of the board content within the container

    init(surface: Set<GridPoint>, containerSize: CGSize, inset: CGFloat = 0) {
        let xs = surface.map(\.x)
        let ys = surface.map(\.y)
        self.minX = xs.min() ?? 0
        self.minY = ys.min() ?? 0
        let maxX = xs.max() ?? 0
        let maxY = ys.max() ?? 0
        self.columns = max(1, maxX - minX + 1)
        self.rows = max(1, maxY - minY + 1)

        let usableWidth = max(1, containerSize.width - inset * 2)
        let usableHeight = max(1, containerSize.height - inset * 2)
        let size = min(usableWidth / CGFloat(columns), usableHeight / CGFloat(rows))
        self.cellSize = size

        let boardWidth = size * CGFloat(columns)
        let boardHeight = size * CGFloat(rows)
        self.origin = CGPoint(
            x: (containerSize.width - boardWidth) / 2,
            y: (containerSize.height - boardHeight) / 2
        )
    }

    var boardSize: CGSize {
        CGSize(width: cellSize * CGFloat(columns), height: cellSize * CGFloat(rows))
    }

    /// Top-left point of a cell's rect in container space.
    func point(for cell: GridPoint) -> CGPoint {
        CGPoint(
            x: origin.x + CGFloat(cell.x - minX) * cellSize,
            y: origin.y + CGFloat(cell.y - minY) * cellSize
        )
    }

    /// Centre of a cell in container space.
    func center(for cell: GridPoint) -> CGPoint {
        let p = point(for: cell)
        return CGPoint(x: p.x + cellSize / 2, y: p.y + cellSize / 2)
    }

    func rect(for cell: GridPoint) -> CGRect {
        CGRect(origin: point(for: cell), size: CGSize(width: cellSize, height: cellSize))
    }

    /// The grid cell containing a container-space point (may be outside the surface).
    func cell(at location: CGPoint) -> GridPoint {
        let cx = Int(((location.x - origin.x) / cellSize).rounded(.down)) + minX
        let cy = Int(((location.y - origin.y) / cellSize).rounded(.down)) + minY
        return GridPoint(x: cx, y: cy)
    }
}
