# Release Checklist

_Updated 2026-06-30 to match the shipped product and launch scope. See LAUNCH_READINESS.md (§9) for the full, app-specific launch checklist._

- Confirm iOS 17+ deployment target.
- Add `PrivacyInfo.xcprivacy` declaring no data collected / no tracking; set App Store privacy label to "Data Not Collected".
- Confirm every shipping daily seed is solver-verified solvable (no unsolvable daily).
- Run Swift Package tests for `TesseraCore`.
- Run Xcode build when Xcode is available; otherwise record `UNVERIFIED_XCODE_ENVIRONMENT`.
- Verify no forbidden dependencies: backend SDKs, accounts, ads, analytics SDKs, Unity, React Native, Flutter, or web runtimes.
- Verify light and dark mode visuals.
- Verify offline launch, daily puzzle, streak persistence, and share card generation.
- Verify StoreKit 2 products and restore purchases in sandbox before release.
