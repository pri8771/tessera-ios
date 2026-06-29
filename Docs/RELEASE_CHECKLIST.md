# Release Checklist

- Confirm iOS 17+ deployment target.
- Run Swift Package tests for `TesseraCore`.
- Run Xcode build when Xcode is available; otherwise record `UNVERIFIED_XCODE_ENVIRONMENT`.
- Verify no forbidden dependencies: backend SDKs, accounts, ads, analytics SDKs, Unity, React Native, Flutter, or web runtimes.
- Verify light and dark mode visuals.
- Verify offline launch, daily puzzle, streak persistence, and share card generation.
- Verify StoreKit 2 products and restore purchases in sandbox before release.
