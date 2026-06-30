# Tessera — Project Documentation

_Updated 2026-06-30 to match the shipped product and launch scope. See LAUNCH_READINESS.md._

GitHub is the source of truth for this project documentation. Notion indexes this file in the Priyansh App Factory Command Center.

## Executive Summary
Tessera is a **calm daily tessellation puzzle for iOS** — tagline "A living jigsaw that breathes." It is for players who want one short, beautiful, ad-free puzzle a day (the Wordle / NYT-Games audience), plus an Endless mode for more volume. The hook is a **deterministic daily puzzle** (the same board for everyone, every day) with a local-only streak — no accounts, no ads, no tracking.

**Implementation maturity: pre-build / docs-first.** Today the repo contains only the pure-Swift puzzle core (`Sources/TesseraCore`, ~146 LOC) with 3 passing unit tests, source-of-truth docs, and empty app-folder scaffolding. The app target, SwiftUI board UI, generator, solver, persistence, share, and StoreKit are not built yet. LAUNCH_READINESS.md is the authoritative build-to spec.

## Product
The core loop: the player drags and rotates irregular/polyomino tiles onto a surface so they tessellate with **no gaps and no overlaps**; a solved, stable board locks with a ripple. V1 delivers a free **deterministic daily puzzle**, an **Endless** mode (random seeds), local streaks/history, and a shareable solve card. The first playable slice to build is drag/rotate on a single hand-authored board to a solved state — proving the core verb before generation or onboarding. (Earlier drafts of this doc described a generic "tutorial + starter levels" puzzle; the locked direction is the daily-puzzle product above — see `Docs/LOCKED_V1_DECISIONS.md`.)

## Design
Clean, gallery-like geometric visual system with generous negative space, light/dark palettes, clear tile states, subtle "breathing" motion, and a satisfying solve ripple. **Breathing is visual/feel polish only in v1, not a gameplay mechanic.** Logical grid cells stay authoritative so rendering can be organic without breaking hit-testing.

## Frontend Technical
Native iOS 17+, SwiftUI. Board rendering via SwiftUI `Canvas` + `TimelineView`; share cards via `ImageRenderer`. All puzzle rules live in the UI-free `TesseraCore` package (validation, solved-state, deterministic daily seed, and the planned solver/generator). UI may depend on the core; the core never depends on UI, StoreKit, persistence, or networking.

## Backend Technical
No backend in any version of v1. Offline-first, local-only. Persistence via Codable and/or SwiftData for daily completion history, streaks, in-progress board state, settings, and StoreKit entitlement cache.

## Business
Daily puzzle is free. **Pro** (StoreKit 2) unlocks the daily archive, premium visual themes, and extra modes; premium themes may also ship as standalone IAPs. One free theme plus structure for premium themes. No ads. Monetization is deferred until daily-puzzle retention is shown.

## Marketing
Position Tessera as a calm, ad-free daily ritual: the same beautiful tessellation board for everyone each day, with a streak to keep and nothing tracking you — Wordle's shared-daily cadence with breathing geometric tiles.

## User Acquisition
Recruit calm-puzzle / polyomino players for TestFlight beta. Because the app collects no analytics, measure success via TestFlight feedback and App Store Connect surfaces only: daily return rate, median streak length, qualitative "is the verb satisfying?", and crash-free sessions.

## Execution
Audit the repo (done), freeze the puzzle rules (done — `TesseraCore`), add the **solvability solver**, build the deterministic generator gated by the solver, create the Xcode app target + SwiftUI shell, build the one-board drag/rotate playable slice, then persistence, share, themes, and (optionally) StoreKit. Prepare TestFlight. See LAUNCH_READINESS.md §8 for the ordered build path.

## QA
Verify **every shipping daily seed is solver-proven solvable** (the trust gate), the core verb feels good in the hand, progress/streaks persist across relaunch and offline, light/dark visuals are correct, and the app works across iPhone sizes. Run `swift test` for the core; run Xcode build once the app target exists (currently `UNVERIFIED_XCODE_ENVIRONMENT`).

## Legal / Compliance
Keep v1 local and simple. Ship a `PrivacyInfo.xcprivacy` declaring no data collected / no tracking, and set the App Store privacy label to "Data Not Collected" to match the implementation. Expected age rating 4+ (abstract puzzle, no objectionable content). If any IAP ships, ensure working purchase + Restore Purchases in sandbox.

## Operations
Release through internal QA → beta → TestFlight → App Store submission when the free daily loop is end-to-end, privacy-clean, and buildable.
