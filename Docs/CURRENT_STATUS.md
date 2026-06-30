# Current Status

_Updated 2026-06-30 to match the shipped product and launch scope. See LAUNCH_READINESS.md._

**Maturity: pre-build / docs-first.** The only executable code is the pure-Swift puzzle core; everything the user touches is still spec.

## Built today
- `Sources/TesseraCore/TesseraCore.swift` (~146 LOC): `GridPoint`, `Tile` (cell-set + id), `Rotation` (0/90/180/270 lattice rotation), `Placement`, `Board.validate(...)` (out-of-bounds / overlap / duplicate-tile / gaps), `Board.isSolved(by:)`, `DailySeed` (UTC `YYYY-MM-DD` key + FNV-1a-64 value), and `PlaceholderPuzzleFactory.makeIntroBoard()` (one hand-authored 3×2 demo board).
- `Tests/TesseraCoreTests` — 3 tests, all passing via `swift test` (overlap detection, full solved-state, deterministic daily seed).
- Source-of-truth docs under `Docs/`; `Package.swift` for the `TesseraCore` library + tests.
- iOS app folder scaffolding under `Tessera/` — currently **empty `.gitkeep` placeholders only** (App, DesignSystem, Game/Board, Game/Generator, Features, Resources).

## Not built yet
- Solvability solver (critical gap — legality ≠ solvability).
- Deterministic daily/Endless generator gated by the solver.
- Xcode app target, SwiftUI app shell, navigation, design system.
- Interactive board UI (drag/rotate/snap), breathing + lock ripple.
- Local persistence (streaks/history/in-progress), share card, StoreKit 2 monetization.
- `PrivacyInfo.xcprivacy`, CI.

## Constraints held
No backend, accounts, ads, analytics SDKs, third-party engines, React Native, Flutter, or web dependencies were introduced. `TesseraCore` imports only `Foundation`.

See LAUNCH_READINESS.md for the full launch scope, per-feature acceptance criteria, bug/risk triage, and the ordered build path to 80–90% production-ready.
