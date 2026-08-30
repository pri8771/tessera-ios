# Tessera iOS

Tessera is a calm, gorgeous daily tessellation puzzle for iOS with the tagline: **"A living jigsaw that breathes."**

Players place and rotate irregular/polyomino tiles onto a surface so the pattern tessellates with no gaps or overlaps. Tiles subtly breathe, and a solved stable board locks with a satisfying ripple animation.

> **Status: V1 built and running.** The full SwiftUI app, the pure-Swift puzzle
> engine (with a three-state solvability solver + deterministic generator),
> local persistence, StoreKit 2, and the share card are implemented and compile +
> test green for the iOS Simulator. See **[Docs/CURRENT_STATUS.md](Docs/CURRENT_STATUS.md)**
> for what's done and **[LAUNCH_READINESS.md](LAUNCH_READINESS.md)** for the
> remaining path to the App Store.

## What's in the box

- **`Sources/TesseraCore`** — deterministic, UI-free puzzle engine: grid/tiles/
  rotations, placement validation, solved-state, a bounded **three-state solver**
  (`solvable` / `unsolvable` / `undecided`), a seeded **puzzle generator**
  (generate-by-construction + solver-verified), and the daily seed. 19 unit tests.
- **`Tessera/`** — the SwiftUI app:
  - `DesignSystem/` — 5 light/dark themes, type scale, spacing, haptics, components.
  - `Game/Board/` — `Canvas`/`TimelineView` board with breathing, drag-to-place
    with live snap preview, the solve ripple, and the view model.
  - `Game/Generator/` — app-facing puzzle service (caching, "today", archive keys).
  - `App/` — entry point, navigation, local persistence, app state.
  - `Features/` — Home, Game, Onboarding, Endless, Archive, Settings, Store
    (paywall), Stats, and the share card.
- **`TesseraTests/`** — app-level unit tests for the game view model (5 tests).

## Locked V1 Direction

- Native iOS 17+ and SwiftUI.
- SwiftUI `Canvas`/`TimelineView` board rendering.
- Offline-first, local-only persistence (Codable to Application Support).
- Deterministic daily puzzle seed by UTC calendar date plus Endless random seeds.
- StoreKit 2 monetization (free daily + one-time **Tessera Pro** unlock), no ads.
- No backend, accounts, analytics SDKs, Unity, React Native, Flutter, or web.

## Development

The Xcode project is generated with [XcodeGen](https://github.com/yonyz/XcodeGen)
from `project.yml`, so the source-of-truth is the `.yml` and the Swift files.

```bash
# Core engine tests (no Xcode project needed):
swift test

# Generate the Xcode project:
brew install xcodegen
xcodegen generate

# Build + test the app for the simulator:
xcodebuild -project Tessera.xcodeproj -scheme Tessera \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

The core package is intentionally UI-free so puzzle rules stay deterministic and
testable. `TesseraCore` never imports SwiftUI, StoreKit, or any networking.
