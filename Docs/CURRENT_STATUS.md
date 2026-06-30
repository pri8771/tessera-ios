# Current Status

_Updated 2026-06-30 — Tessera V1 built end-to-end and verified on the iOS Simulator._

**Maturity: V1 built and running.** The full SwiftUI app and the puzzle engine are
implemented and compile + test green for the iOS Simulator.

## What is built

**Engine (`Sources/TesseraCore`, pure Swift, no UI):**
- Geometry: `GridPoint`, `Rotation`, `Tile` (orientations, connectivity, normalization).
- `Board`: placement validation (overlap / out-of-bounds / duplicate / gaps) and solved-state.
- **Three-state solver** (`solvable` / `unsolvable` / `undecided`): bounded backtracking
  exact-cover over a `UInt64` bitmask, deterministic first-uncovered-cell branching, node
  cap. `undecided` (cap hit) is never conflated with `unsolvable` — the locked contract.
- **`PuzzleGenerator`**: deterministic generate-by-construction (seeded partition →
  guaranteed tiling) verified by the solver gate; daily (by UTC date) + endless across three
  difficulties (Gentle / Calm / Deep).
- `SeededGenerator` (SplitMix64), `DailySeed` (FNV-1a by UTC date), curated tutorial puzzles.
- 19 unit tests, including the locked three-state matrix and determinism checks.

**App (`Tessera/`, SwiftUI, iOS 17+):**
- Design system: 5 themes (Daybreak free + Aurora/Dusk/Meadow/Ink premium), each with
  light + dark palettes; type scale, spacing, haptics, reusable components, flow layout.
- Board: `Canvas`/`TimelineView` rendering with subtle "breathing", drag-to-place with a live
  snapped validity preview, rotate, hint, pick-up, and the solved-lock ripple.
- Features: Home (daily card + streaks), Game, Onboarding, Endless, Archive (Pro), Settings,
  Store paywall, Stats, and an on-device `ImageRenderer` share card.
- Local-only persistence (Codable → Application Support): completed dailies, current/longest
  streak, totals, saved-game resume, settings, and the StoreKit entitlement cache.
- StoreKit 2: free daily; one-time **Tessera Pro** non-consumable unlocks Endless, Archive,
  and premium themes. `.storekit` config for local testing; restore supported.
- 5 app-level unit tests for the game view model.

## Verification

- `swift test` → 19/19 core tests pass.
- `xcodebuild ... test` (iPhone 17 simulator) → app + core tests pass; **BUILD SUCCEEDED**.
- Ran in the simulator and screenshot-verified: onboarding, home (light + dark), board with
  tray, dark-mode board, and the solved overlay.

## Not yet done (see LAUNCH_READINESS.md)

- Run on real hardware; finalize App Store metadata, screenshots, privacy nutrition label.
- Real App Store Connect product setup for `com.priyanshchordia.tessera.pro` (the in-repo
  `.storekit` file is for local testing only).
- Accessibility deep-pass (VoiceOver order, Dynamic Type at extreme sizes) and a broader
  curated daily-quality review.

## Constraints held

No backend, accounts, ads, analytics SDKs, third-party engines, React Native, Flutter, or web
dependencies. `TesseraCore` imports only `Foundation`; the app imports only Apple frameworks
(SwiftUI, StoreKit, UIKit for haptics/share).
