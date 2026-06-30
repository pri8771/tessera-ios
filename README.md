# Tessera iOS

Tessera is a calm, gorgeous daily tessellation puzzle for iOS with the tagline: **"A living jigsaw that breathes."**

Players place and rotate irregular/polyomino tiles onto a surface so the pattern tessellates with no gaps or overlaps. Tiles subtly breathe, and a solved stable board locks with a satisfying ripple animation.

> **Status: pre-build / docs-first.** Only the pure-Swift puzzle core (`Sources/TesseraCore`) and its 3 unit tests exist today. The app target, board UI, generator, solvability solver, persistence, share, and StoreKit are not built yet. See **[LAUNCH_READINESS.md](LAUNCH_READINESS.md)** for the full launch scope, per-feature acceptance criteria, and the ordered build path.

## Current Scope

This repository currently contains:

- Source-of-truth product and engineering docs in `Docs/`.
- The canonical launch-scope spec in `LAUNCH_READINESS.md`.
- Native iOS app folder scaffolding in `Tessera/` (currently empty `.gitkeep` placeholders).
- A pure-Swift puzzle foundation in `Sources/TesseraCore` (grid, tiles, rotations, placement validation, solved-state, deterministic daily seed).
- Swift Package tests in `Tests/TesseraCoreTests` (3 passing).

## Locked V1 Direction

- Native iOS 17+ and SwiftUI.
- SwiftUI `Canvas`/`TimelineView` board rendering planned.
- Offline-first, local-only persistence.
- Deterministic daily puzzle seed by calendar date plus Endless mode random seeds.
- StoreKit 2 monetization, no ads.
- No backend, accounts, analytics SDKs, Unity, React Native, Flutter, or web.

## Development

Run core tests with:

```bash
swift test
```

The core package is intentionally UI-free so puzzle rules remain deterministic and testable.
