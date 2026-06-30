import SwiftUI
import TesseraCore

/// The pool of unplaced pieces. Each piece can be tapped (select) and dragged onto
/// the board. Drag locations are reported in the shared `"game"` coordinate space
/// so the board can snap them.
struct TrayView: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme

    let vm: GameViewModel
    let trayCellSize: CGFloat
    var onDragChanged: (_ tileID: String, _ gameLocation: CGPoint) -> Void
    var onDragEnded: (_ tileID: String, _ gameLocation: CGPoint) -> Void

    var body: some View {
        let colors = theme.colors(for: scheme)
        FlowLayout(spacing: Spacing.md) {
            ForEach(vm.trayOrder, id: \.self) { tileID in
                pieceView(tileID: tileID, colors: colors)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.trayOrder)
    }

    private func pieceView(tileID: String, colors: ThemeColors) -> some View {
        let cells = vm.displayCells(for: tileID)
        let color = theme.tileColor(forPieceIndex: vm.colorIndex(for: tileID))
        let isSelected = vm.selectedTileID == tileID
        let isDragging = vm.drag?.tileID == tileID
        let size = PolyominoShape.size(for: cells, cellSize: trayCellSize)

        return TilePieceView(cells: cells, cellSize: trayCellSize, color: color)
            .padding(Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .fill(isSelected ? colors.accentSoft : Color.clear)
            )
            .frame(width: size.width + Spacing.md, height: size.height + Spacing.md)
            .opacity(isDragging ? 0.25 : 1)
            .scaleEffect(isSelected ? 1.04 : 1)
            .contentShape(Rectangle())
            .onTapGesture { vm.toggleSelection(tileID) }
            .gesture(
                DragGesture(minimumDistance: 6, coordinateSpace: .named("game"))
                    .onChanged { onDragChanged(tileID, $0.location) }
                    .onEnded { onDragEnded(tileID, $0.location) }
            )
            .accessibilityElement()
            .accessibilityLabel("Piece, \(cells.count) cells")
            .accessibilityHint(isSelected ? "Selected. Double tap to deselect, or drag to the board." : "Double tap to select, then use Rotate. Drag to place on the board.")
    }
}
