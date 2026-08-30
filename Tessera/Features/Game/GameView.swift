import SwiftUI
import TesseraCore

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme
    @Environment(GameStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    let config: GameConfig
    var onFinished: (() -> Void)?

    @State private var vm: GameViewModel
    @State private var boardFrame: CGRect = .zero
    @State private var showSolved = false
    @State private var showRipple = false
    @State private var didRecord = false
    @State private var showHintUnavailable = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let trayCellSize: CGFloat = 26

    init(config: GameConfig, onFinished: (() -> Void)? = nil) {
        self.config = config
        self.onFinished = onFinished
        _vm = State(initialValue: GameViewModel(puzzle: config.puzzle))
    }

    private var geometry: BoardGeometry {
        BoardGeometry(surface: vm.board.surface, containerSize: boardFrame.size, inset: 14)
    }

    var body: some View {
        let colors = theme.colors(for: scheme)
        ZStack {
            ThemedBackground()
            VStack(spacing: Spacing.sm) {
                header(colors)
                boardArea(colors)
                controls(colors)
                trayArea(colors)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.md)

            if showRipple { SolveRippleView().allowsHitTesting(false) }
            if showSolved { solvedOverlay(colors) }
        }
        .coordinateSpace(name: "game")
        .navigationBarBackButtonHidden(true)
        .onAppear {
            resumeIfPossible()
            bindSolveHandler()
            #if DEBUG
            if ProcessInfo.processInfo.environment["TESSERA_AUTOSOLVE"] == "1" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { vm.revealSolution() }
            }
            #endif
        }
        .onReceive(timer) { _ in if !showSolved { vm.tick() } }
        .onChange(of: vm.moves) { _, _ in persistSnapshot() }
        .onChange(of: scenePhase) { _, phase in
            // A backgrounding/interruption mid-drag never delivers DragGesture's
            // onEnded, so without this the ghost preview and DragState would be
            // stuck forever — the piece would look "held" with no way to drop or
            // cancel it. Clearing on any non-active phase makes it safe.
            if phase != .active { vm.cancelDrag() }
        }
        .onDisappear { persistSnapshot() }
        .alert("No hint available", isPresented: $showHintUnavailable) {
            Button("OK") {}
        } message: {
            Text("This arrangement can't be completed from here. Try picking up a piece and placing it differently.")
        }
    }

    // MARK: - Header

    private func header(_ colors: ThemeColors) -> some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Button {
                    persistSnapshot()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(colors.ink)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(colors.surface))
                }
                .accessibilityLabel("Back")

                VStack(spacing: 2) {
                    Text(config.title)
                        .font(AppFont.headline())
                        .foregroundStyle(colors.ink)
                    Text(config.subtitle)
                        .font(AppFont.caption())
                        .foregroundStyle(colors.inkSecondary)
                }
                .frame(maxWidth: .infinity)

                Menu {
                    Button("Restart", systemImage: "arrow.counterclockwise") { restart() }
                    Button("Reveal solution", systemImage: "eye") { revealSolution() }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(colors.ink)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(colors.surface))
                }
                .accessibilityLabel("More options")
            }

            HStack(spacing: Spacing.lg) {
                Label(vm.formattedTime, systemImage: "clock")
                Label("\(vm.moves)", systemImage: "hand.tap")
                Label("\(vm.remainingCount) left", systemImage: "square.grid.2x2")
            }
            .font(AppFont.caption())
            .foregroundStyle(colors.inkSecondary)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Board

    private func boardArea(_ colors: ThemeColors) -> some View {
        GeometryReader { geo in
            let boardGeometry = BoardGeometry(surface: vm.board.surface, containerSize: geo.size, inset: 14)
            BoardView(
                vm: vm,
                geometry: boardGeometry,
                breathingEnabled: store.settings.breathingEnabled,
                showGridGuides: store.settings.showGridGuides,
                onPickUpPlaced: { vm.pickUp(placedTileID: $0) },
                onPlaceSelected: { _ = vm.placeSelected(coveringBoardCell: $0) }
            )
            .background(
                Color.clear
                    .onAppear { boardFrame = geo.frame(in: .named("game")) }
                    .onChange(of: geo.frame(in: .named("game"))) { _, new in boardFrame = new }
            )
            // Drag-free placement: with a piece selected, tap an empty spot to place
            // it there. Keeps the board playable without dragging and is a faster
            // path for everyone. Taps on placed pieces are handled inside BoardView
            // (pick up) and take precedence. VoiceOver placement is handled
            // separately inside BoardView, where each empty cell is its own
            // accessibility element (a raw screen coordinate is meaningless to a
            // screen-reader user, so this gesture alone can't serve them).
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture(coordinateSpace: .named("game")).onEnded { value in
                    guard vm.selectedTileID != nil else { return }
                    let local = CGPoint(x: value.location.x - boardFrame.minX,
                                        y: value.location.y - boardFrame.minY)
                    let cell = boardGeometry.cell(at: local)
                    vm.placeSelected(coveringBoardCell: cell)
                }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Puzzle board, \(vm.board.tiles.count - vm.remainingCount) of \(vm.board.tiles.count) pieces placed")
    }

    // MARK: - Controls

    private func controls(_ colors: ThemeColors) -> some View {
        HStack(spacing: Spacing.md) {
            controlButton(title: "Rotate", system: "rotate.right", enabled: canRotate) {
                if let id = vm.selectedTileID { vm.rotate(id, geometry: geometry) }
            }
            controlButton(title: "Hint", system: "lightbulb", enabled: !vm.isSolved) {
                // A `nil` here (button was enabled, so the puzzle isn't already
                // solved) means the CURRENT arrangement can't be completed — a
                // real, reachable outcome of ordinary mixed manual/hint play, not
                // a hypothetical. Without this, nothing visibly happens, which
                // reads as "the game is frozen" rather than "you've reached a
                // dead end from here."
                if vm.useHint() == nil { showHintUnavailable = true }
            }
        }
    }

    private func controlButton(title: String, system: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        let colors = theme.colors(for: scheme)
        return Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: system)
                Text(title)
            }
            .font(AppFont.callout())
            .foregroundStyle(enabled ? colors.ink : colors.inkTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(colors.separator, lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!enabled)
    }

    private var canRotate: Bool {
        guard let id = vm.selectedTileID else { return false }
        return vm.placement(for: id) == nil
    }

    // MARK: - Tray

    private func trayArea(_ colors: ThemeColors) -> some View {
        TrayView(
            vm: vm,
            trayCellSize: trayCellSize,
            onDragChanged: { tileID, gameLocation in
                let local = CGPoint(x: gameLocation.x - boardFrame.minX, y: gameLocation.y - boardFrame.minY)
                // Compare tileID, not just nil-ness: if a stale DragState from a
                // different piece is still around (e.g. a previous drag's onEnded
                // never fired), a new drag on another piece must start fresh rather
                // than hijacking it and moving the WRONG piece's ghost preview.
                if vm.drag?.tileID != tileID {
                    vm.beginDrag(tileID: tileID, at: local, geometry: geometry)
                } else {
                    vm.updateDrag(to: local, geometry: geometry)
                }
            },
            onDragEnded: { _, _ in
                _ = vm.endDrag(geometry: geometry)
            }
        )
        .frame(minHeight: trayCellSize * 4)
        .padding(.top, Spacing.xs)
    }

    // MARK: - Solved overlay

    private func solvedOverlay(_ colors: ThemeColors) -> some View {
        SolvedOverlay(
            puzzle: vm.puzzle,
            timeText: vm.formattedTime,
            moves: vm.moves,
            hintsUsed: vm.hintsUsed,
            streak: store.progress.currentStreak,
            onDone: {
                onFinished?()
                dismiss()
            },
            onReplay: { restart() }
        )
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Actions

    private func resumeIfPossible() {
        guard config.allowResume, let saved = store.savedGame(forPuzzleID: config.puzzle.id) else { return }
        vm = GameViewModel(puzzle: config.puzzle, resuming: saved)
    }

    private func bindSolveHandler() {
        vm.onSolved = { handleSolved() }
    }

    private func handleSolved() {
        guard !didRecord else { return }
        didRecord = true
        store.recordCompletion(
            puzzle: vm.puzzle,
            moves: vm.moves,
            durationSeconds: vm.elapsedSeconds,
            hintsUsed: vm.hintsUsed,
            completedAt: Date(),
            isTodaysDaily: config.isTodaysDaily
        )
        if config.puzzle.mode == .tutorial { store.tutorialCompleted() }
        withAnimation(.easeOut(duration: 0.9)) { showRipple = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { showSolved = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            showRipple = false
        }
    }

    private func restart() {
        withAnimation { showSolved = false }
        showRipple = false
        didRecord = false
        vm.reset()
        store.clearSavedGame(puzzleID: config.puzzle.id)
        bindSolveHandler()
    }

    private func revealSolution() {
        vm.revealSolution()
    }

    private func persistSnapshot() {
        guard config.allowResume, !vm.isSolved else { return }
        if vm.placements.isEmpty {
            store.clearSavedGame(puzzleID: config.puzzle.id)
        } else {
            store.saveGame(vm.snapshot())
        }
    }
}
