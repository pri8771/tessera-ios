# Locked V1 Decisions

1. Tessera is a native iOS 17+ game built with SwiftUI.
2. The core mechanic is placing and rotating irregular/polyomino tiles onto a surface so they tessellate with no gaps or overlaps.
3. Tiles subtly "breathe" by slowly morphing shape; when the solved pattern is stable, the board locks with a ripple animation.
4. Daily puzzle generation is deterministic and seeded by calendar date so every player receives the same daily puzzle.
5. Endless mode uses random seeds.
6. Wordle-style streaks and shareable solve cards are local-only and generated with SwiftUI `ImageRenderer`.
7. Persistence is local-only via Codable and/or SwiftData for daily completion history, streaks, settings, and entitlements cache.
8. Monetization uses StoreKit 2: the daily puzzle is free; Pro unlocks archive, premium visual themes, and extra modes; premium themes may also be standalone IAPs.
9. Tessera includes one free theme plus structure for premium themes.
10. The puzzle model is deterministic, fully testable pure Swift, and separate from UI.

## Exclusions

No backend, accounts, ads, analytics SDKs, Unity, third-party game engines, React Native, Flutter, multiplayer, or web implementation.
