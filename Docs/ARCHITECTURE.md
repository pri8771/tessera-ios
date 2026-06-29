# Architecture

Tessera is split into a SwiftUI iOS shell and a pure-Swift puzzle core.

## Folders

- `Tessera/App`: future SwiftUI app entry point, navigation, scene setup.
- `Tessera/DesignSystem`: colors, typography, spacing, theme definitions, light/dark support.
- `Tessera/Game/Board`: SwiftUI `Canvas` and `TimelineView` board rendering.
- `Tessera/Game/Generator`: app-facing generator orchestration around TesseraCore.
- `Tessera/Features`: daily puzzle, endless mode, share card, settings, store screens.
- `Tessera/Resources`: bundled app resources and local-only assets.
- `Sources/TesseraCore`: deterministic pure-Swift model, validation, solved checks, seeds, and generator primitives.
- `Tests/TesseraCoreTests`: Swift Package tests for core model behavior.

## Dependency Rules

`TesseraCore` must not depend on SwiftUI, StoreKit, persistence frameworks, networking, or app resources. UI layers may depend on the core, never the reverse. Forbidden dependencies include backend SDKs, ad SDKs, analytics SDKs, Unity, React Native, Flutter, and web runtimes.
