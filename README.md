# Tessera iOS

Tessera is a calm, gorgeous daily tessellation puzzle for iOS with the tagline: **"A living jigsaw that breathes."**

Players place and rotate irregular/polyomino tiles onto a surface so the pattern tessellates with no gaps or overlaps. Tiles subtly breathe, and a solved stable board locks with a satisfying ripple animation.

## Current Scope

This repository currently contains:

- Source-of-truth product and engineering docs in `Docs/`.
- Native iOS app folder scaffolding in `Tessera/`.
- A pure-Swift puzzle foundation in `Sources/TesseraCore`.
- Swift Package tests in `Tests/TesseraCoreTests`.

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
