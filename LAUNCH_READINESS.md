# Tessera — Launch Readiness (v1)

> Tessera is a calm, gallery-like **daily tessellation puzzle for iOS** — tagline "A living jigsaw that breathes." The player drags and rotates irregular/polyomino tiles onto a surface so they tessellate with no gaps or overlaps; a solved board locks with a satisfying ripple. It targets people who want a short, low-pressure, visually beautiful daily ritual (a calmer cousin of Wordle), with a deterministic daily puzzle everyone shares plus an Endless mode. **Implementation maturity: pre-build / docs-first.** The only real code is a pure-Swift puzzle core (`Sources/TesseraCore/TesseraCore.swift`, ~146 LOC) with 3 passing unit tests; there is **no app target, no SwiftUI, no rendering, no persistence, no StoreKit, no Xcode project, and no solver.** The `Tessera/` app tree is empty `.gitkeep` placeholders. This document is therefore the authoritative **build-to spec** for v1; per-feature status below is honest about what exists versus what must still be built.

---

## 1. PRD / Launch Scope

### Problem & insight
Most mobile puzzle games are loud, ad-saturated, and engagement-engineered. There is a durable audience (proven by Wordle, daily crosswords, NYT Games) for a **single, calm, shared daily puzzle** that respects attention: no ads, no accounts, no endless scroll. The insight Tessera bets on: tessellation/polyomino placement is tactile and meditative, and a *deterministic daily* board (same puzzle for everyone, every day) creates a low-key social ritual and natural return cadence — without any backend, telemetry, or growth machinery.

### Target user
- **Primary:** Calm-daily-puzzle players (the Wordle / NYT-Games / Two Dots audience) who want one short, beautiful, ad-free session per day and a streak to maintain.
- **Secondary:** Polyomino / tessellation / spatial-reasoning enthusiasts who will play Endless mode for more volume; and aesthetics-driven casual players drawn to the "living, breathing" visual identity.

### Value proposition (one sentence)
A calm, ad-free daily tessellation puzzle you can finish in a few minutes — the same board for everyone, every day — with a streak to keep and nothing tracking you.

### Positioning / category & one-sentence pitch
- **Category:** Games → Puzzle (daily puzzle / casual / relaxing). Product line: **Games**.
- **Pitch:** "Wordle's calm, shared-daily ritual, but with breathing geometric tiles you slot into a perfect mosaic."

### Platform & tech baseline
- **Native iOS 17+**, **SwiftUI** (locked: `Docs/LOCKED_V1_DECISIONS.md` #1, #3).
- Board rendering planned via SwiftUI **`Canvas` + `TimelineView`** (`Docs/ARCHITECTURE.md`); share cards via **`ImageRenderer`**.
- Pure-Swift **`TesseraCore`** package holds all deterministic rules; it must not import SwiftUI/StoreKit/persistence/networking (`Docs/ARCHITECTURE.md`, dependency rules — currently enforced: `TesseraCore.swift` imports only `Foundation`).
- Persistence: local-only via Codable and/or SwiftData (`LOCKED_V1_DECISIONS.md` #7). Offline-first, no backend.
- Monetization: **StoreKit 2** (`LOCKED_V1_DECISIONS.md` #8), no ads.
- macOS(.v13) is listed as a secondary package platform in `Package.swift` for test convenience; **macOS is not a launch target**.

### Business model (only what the repo supports/plans)
Per `LOCKED_V1_DECISIONS.md` #8–#9: the **daily puzzle is free**; a **Pro** unlock (StoreKit 2) opens the **daily archive, premium visual themes, and extra modes**; premium themes may also ship as standalone IAPs. One free theme ships with structure for premium themes. No ads. **None of the monetization is built** (no `.storekit` config, no StoreKit code, no products).

### North-star / success signals (local-only, privacy-respecting)
The app ships with **no analytics SDK and no telemetry** (`Docs/PRIVACY_NOTES.md`), so success is judged by **beta-observable / App-Store-surface signals only**:
- **D1 / D7 daily-puzzle return rate** and **median streak length** (observed via TestFlight feedback + App Store retention charts, not in-app tracking).
- **Daily completion rate** (started-vs-solved) gathered from beta testers qualitatively.
- **Crash-free sessions** (Xcode Organizer).
- **Conversion to Pro** (App Store Connect sales) once monetization is wired.
- Qualitative "is the core verb satisfying?" signal from the first playable slice (see §4).

---

## 2. MVP Feature List (with acceptance criteria)

> Status legend — **Built**: implemented and tested in-repo today. **Partial**: foundation/logic exists but no usable surface. **Not built**: nothing in-repo yet (spec only).

### F1. Deterministic puzzle core (rules, validation, solved-state) — Status: **Built**
The pure-Swift model: `GridPoint`, `Tile` (cell-set + id), `Rotation` (0/90/180/270 via integer point transforms), `Placement` (tileID + origin + rotation), `Board.validate(...)`, `Board.isSolved(by:)`. (`Sources/TesseraCore/TesseraCore.swift`.)
- **Acceptance criteria**
  - Given a placement whose transformed cell falls outside `surface`, validate returns `.outOfBounds`. *(verifiable; covered indirectly by model)*
  - Given two placements occupying the same cell, validate returns `.overlap`. *(covered: `testPlacementValidationDetectsOverlap`)*
  - Given the same `tileID` placed twice, validate returns `.duplicateTile`. *(logic present; no dedicated test — see Limitations L7)*
  - Given `requireComplete: true` and uncovered cells, validate returns `.gaps(...)` with the exact missing set. *(logic present; no dedicated test)*
  - Given a full, legal, non-overlapping cover, `isSolved(by:)` returns `true`. *(covered: `testSolvedStateRequiresNoGapsOrOverlaps`)*
  - `Rotation.apply` is a true 90° lattice rotation (verifiable: `degrees90`(1,0)→(0,1); composition of four 90° turns = identity). *(logic present; no dedicated rotation test — L7)*

### F2. Deterministic daily seed — Status: **Built**
`DailySeed(date:)` derives a UTC `YYYY-MM-DD` `dateKey` and an FNV-1a-64 `value`. (`TesseraCore.swift` L116–136.)
- **Acceptance criteria**
  - Given two timestamps on the same UTC calendar day, `DailySeed` values are equal. *(covered: `testDailySeedIsDeterministicForCalendarDate`)*
  - Given timestamps on adjacent UTC days, values differ. *(covered)*
  - `dateKey` for a known instant equals the expected `YYYY-MM-DD` string. *(covered)*
  - Rollover boundary is **UTC midnight** (documented assumption, `Docs/ASSUMPTIONS_LOG.md`); device-local rollover is explicitly deferred.

### F3. Solvability validator / solver — Status: **Not built** ← *critical gap*
A function that proves a given board+tile-set is **completable** (legality ≠ solvability). Required so a deterministic daily seed can never emit an unsolvable board. Flagged as the make-or-break gap in the product conversation (`Tessera.md`, Claude turn) and absent from `TesseraCore`.
- **Acceptance criteria**
  - Given a board+tiles with at least one exact cover, `solve()` returns a valid `[Placement]` where `board.isSolved(by:)` is `true`.
  - Given a board with no exact cover, `solve()` returns `nil` (proves unsolvable).
  - The solver is deterministic: same input → same result/solution ordering.
  - Performance: solves the v1 daily board size within an interactive budget (target < 50 ms on-device) so generation can reject bad seeds.
  - A test asserts **every daily seed across a representative date range (e.g. 365 days) yields a solvable board** before any board ships. *(This is the gate that protects daily-puzzle trust.)*

### F4. Deterministic daily puzzle generator — Status: **Not built**
App-facing generator (planned `Tessera/Game/Generator`) that turns a `DailySeed` into a concrete `Board` + tile bag, **rejecting any seed whose board fails F3's solver**. Today only `PlaceholderPuzzleFactory.makeIntroBoard()` (one hand-authored 3×2 board) exists.
- **Acceptance criteria**
  - Given a `DailySeed`, generator returns a deterministic `Board` (same date → identical board for every install).
  - Generated board passes F3 `solve()` (guaranteed solvable); unsolvable candidates are regenerated/rejected, not shipped.
  - Difficulty stays within a bounded band (cell count / piece count / required-rotation heuristic) so daily puzzles aren't trivially empty or brutally large.
  - Endless mode uses a random seed persisted with the run so it can be resumed (`LOCKED_V1_DECISIONS.md` #5).

### F5. Interactive board UI — drag, rotate, snap, validate — Status: **Not built**
The smallest playable slice per the conversation: drag + rotate tiles on **one** board until solved, driven entirely by `TesseraCore`. Planned `Tessera/Game/Board` with SwiftUI `Canvas`/`TimelineView`.
- **Acceptance criteria**
  - A tile can be dragged from a tray onto the board and snaps to the nearest valid grid cell.
  - A tile can be rotated through 0/90/180/270 by a gesture/button; its rendered footprint matches `Tile.rotated(...)` exactly (rendering must not diverge from logical cells — `Docs/RISK_LOG.md`).
  - Illegal placements (out-of-bounds / overlap) are visibly rejected with feedback and never enter committed state.
  - When the committed placements satisfy `board.isSolved(by:)`, the solve state fires (→ F6).
  - All legality decisions route through `TesseraCore`; the UI holds **no** independent rules copy.

### F6. Solved-state feedback ("breathing" + lock ripple) — Status: **Not built**
Visual feel layer: tiles subtly "breathe" (deterministic phase morph) and a solved, stable board triggers a lock/ripple. **Visual polish only — not a gameplay state in v1** (conversation decision; `GAME_DESIGN.md` "Breathing Concept").
- **Acceptance criteria**
  - Breathing is purely visual: it never changes logical cells, hit-testing, or solve validity (logical footprint stays stable while edges animate).
  - On solve, the board holds stable for a short window, then plays a one-shot lock ripple.
  - Breathing can be reduced/disabled to satisfy **Reduce Motion** accessibility (see §9).

### F7. Local progress, streaks & daily history — Status: **Not built**
On-device persistence (Codable/SwiftData) of: completed dailies, current in-progress board state, current/longest streak, and settings. No accounts, no cloud (`LOCKED_V1_DECISIONS.md` #6–#7; `PRIVACY_NOTES.md`).
- **Acceptance criteria**
  - Completing today's daily marks it done and increments the streak; missing a day resets the current streak per a defined rule.
  - In-progress board state survives app kill/relaunch and offline.
  - All data stays on-device; nothing is transmitted. Deleting the app removes all data.

### F8. Shareable solve card — Status: **Not built**
User-initiated share card rendered on-device with `ImageRenderer`, summarizing date, outcome, time/moves (once those metrics exist), and theme. No copyrighted assets (`GAME_DESIGN.md` "Streaks and Share Rules").
- **Acceptance criteria**
  - Share is user-initiated (never automatic); generated locally with `ImageRenderer`.
  - Card contains only first-party generated content (no third-party/copyrighted assets).
  - Card omits any personal identifiers; it is shareable via the system share sheet.

### F9. Monetization — Pro unlock + premium themes (StoreKit 2) — Status: **Not built**
Daily free; Pro unlocks archive + premium themes + extra modes; standalone theme IAPs possible. One free theme + structure for premium themes. Deferred until daily retention is shown (conversation: "defer StoreKit until the loop is proven").
- **Acceptance criteria**
  - Daily puzzle and core loop are fully playable **without** any purchase.
  - Pro entitlement (and standalone theme IAPs) purchase + **restore** work in StoreKit sandbox; entitlement cache behaves correctly **offline** (`Docs/RISK_LOG.md`).
  - Entitlement state is isolated from core gameplay (purchase failures never block the free daily).
  - `.storekit` configuration exists and products match App Store Connect.

### F10. App shell, navigation & design system — Status: **Not built**
SwiftUI app entry point, navigation between Daily / Endless / Archive / Settings / Store, and a light/dark design-system (colors, typography, spacing, themes). Planned `Tessera/App` + `Tessera/DesignSystem` (currently empty `.gitkeep`).
- **Acceptance criteria**
  - App launches to today's daily; navigation reaches Endless, Settings, and (gated) Archive/Store.
  - Full light & dark mode support (`Docs/RELEASE_CHECKLIST.md`).
  - Layout is correct across iPhone sizes (small → Pro Max) and respects safe areas.

---

## 3. Out of Scope (v1 non-goals)

Explicitly **not** in v1, per `Docs/LOCKED_V1_DECISIONS.md` (Exclusions) and the product conversation:
- **No backend, accounts, or login.** Local-only; no server, no sync.
- **No ads or ad SDKs.** Calm, ad-free is core positioning.
- **No analytics SDKs / telemetry / gameplay tracking** (`PRIVACY_NOTES.md`). Privacy posture forbids it.
- **No multiplayer / leaderboards / social graph.** Sharing is a static card only.
- **No cross-platform engine** — no Unity, third-party game engines, React Native, Flutter, or web runtime.
- **No Android / web / macOS launch.** iOS 17+ only (macOS package platform is for test convenience, not a shipped app).
- **Breathing is NOT a gameplay mechanic in v1.** It is visual/feel polish; time-varying gameplay is deferred until the static place-and-solve loop is proven sticky.
- **No procedural-art / fancy organic tile rendering as a gameplay dependency.** Logical cells stay authoritative; organic morphing is rendering-only and can land post-v1.
- **No tutorial sequencing or onboarding course in the first slice.** The smallest slice proves the core verb first; structured onboarding comes after.
- **No iCloud / cross-device streak continuity.** Out of scope given local-only posture.

---

## 4. User Flows

> No UI exists yet; flows below are the **build-to** design, with screen names matching the planned `Tessera/` structure (`Docs/ARCHITECTURE.md`). The only flow exercisable today is the test-only core flow (F1/F2).

### Flow A — First run / first daily (target)
1. App launches (`Tessera/App`) directly into today's **Daily** screen (`Tessera/Features`).
2. Generator (F4) derives today's board from `DailySeed` (F2); solver (F3) has already guaranteed it's solvable.
3. A light first-time hint shows the two verbs: **drag** a tile onto the board, **rotate** it.
4. Player drags/rotates tiles; each commit is validated through `TesseraCore` (F5); illegal moves bounce back with feedback.
5. On a gap-free, overlap-free cover, `isSolved(by:)` fires → breathing settles and the **lock ripple** plays (F6).
6. Streak increments and today's daily is marked complete (F7); player is offered the **share card** (F8).

### Flow B — Core loop (returning daily player)
1. Open app → today's daily (or the resumed in-progress board if started earlier, F7).
2. Solve → streak update → optional share. One short session, then done for the day.
3. (Pro) Player may open the **Archive** to replay past dailies, or switch to **Endless** for more boards.

### Flow C — Endless mode
1. From navigation, choose **Endless** (`Tessera/Features`).
2. A random-seeded, solver-verified board is generated (F4); run state persists locally so it can be resumed (`LOCKED_V1_DECISIONS.md` #5).
3. Solve → next board. No streak pressure.

### Flow D — Settings / privacy
1. Open **Settings**. Toggle theme (light/dark + selected visual theme), **Reduce Motion** (disables breathing), and other preferences (F10).
2. A plain-language privacy statement reflects the local-only, no-tracking posture (`PRIVACY_NOTES.md`).

### Flow E — Monetization (Pro / themes)
1. Player hits a gated surface (Archive, premium theme, extra mode) → **Store** screen (F9).
2. Purchase Pro or a standalone theme via StoreKit 2; **Restore Purchases** available.
3. Entitlement caches locally and works offline; the free daily is never blocked by purchase state.

### Flow F — Core model flow (exists today, test-only)
1. `PlaceholderPuzzleFactory.makeIntroBoard()` builds a hand-authored 3×2 board with domino/triomino/monomino tiles.
2. `Board.validate(placements:)` and `Board.isSolved(by:)` evaluate placements. `DailySeed(date:)` produces the deterministic daily key/value. Verified by 3 passing `swift test` cases — **no interactive surface.**

---

## 5. Acceptance Criteria Summary

| ID | Feature | Status | Launch gate (pass = ✔) |
|----|---------|--------|------------------------|
| F1 | Puzzle core (validate/solved) | Built | `swift test` green; overlap/gaps/duplicate/out-of-bounds/solved all enforced (add missing tests, L7) |
| F2 | Deterministic daily seed | Built | Same UTC day → equal seed; adjacent days differ; dateKey correct (tested) |
| F3 | **Solvability solver** | **Not built** | `solve()` finds a cover when one exists, returns `nil` otherwise; **365-day daily-seed solvability test passes** |
| F4 | Daily/Endless generator | Not built | Deterministic per seed; every generated board passes F3; difficulty bounded; Endless resumable |
| F5 | Interactive board (drag/rotate/snap) | Not built | Drag+rotate+snap work; illegal placements rejected; solve fires; rules only via core |
| F6 | Breathing + lock ripple | Not built | Visual-only (no logic impact); ripple on solve; Reduce-Motion honored |
| F7 | Local progress / streaks | Not built | Streak inc/reset correct; in-progress resumes offline; data on-device only |
| F8 | Share card | Not built | User-initiated; `ImageRenderer`; first-party assets only; no PII |
| F9 | StoreKit 2 Pro / themes | Not built | Free loop unaffected; sandbox purchase+restore; offline entitlement; isolated from gameplay |
| F10 | App shell + design system | Not built | Launches to daily; light/dark; correct across iPhone sizes |

**Launch is gated on F1–F8 + F10 working end-to-end** (the playable free daily loop). **F9 may be deferred** to a fast-follow if the daily loop is proven first (conversation guidance), but if Pro/themes ship at launch they must pass their criteria.

---

## 6. Known Limitations

- **L1 — No solver exists (severity: critical).** `TesseraCore` validates legality but cannot prove solvability. A deterministic daily seed could emit an unsolvable board, the single worst failure for a daily game. (`Tessera.md` conversation; absent from `TesseraCore.swift`.)
- **L2 — Pre-build everywhere above the core.** No app target, no SwiftUI, no `.xcodeproj`, no Info.plist, no persistence, no StoreKit, no rendering. The `Tessera/` tree is six empty `.gitkeep` folders. ~90% of shippable surface is unwritten.
- **L3 — Only one hand-authored board.** `PlaceholderPuzzleFactory.makeIntroBoard()` is a 3×2 demo; there is no real content pipeline or board library yet.
- **L4 — Rotation around origin can place cells at negative coordinates.** `Rotation.apply` rotates about (0,0), so rotated tiles often need a non-trivial `origin` offset to land in-bounds. This is correct but means the generator/UI must compute valid origins; there is no normalization/bounding-box helper yet.
- **L5 — Daily rollover is UTC, not device-local.** Players near a day boundary may see "today's" puzzle change at an unintuitive local time. Deliberate per `ASSUMPTIONS_LOG.md`, revisitable.
- **L6 — "Breathing" vs hit-testing tension.** If organic visual morphs drift from logical cells, hit-testing breaks. Mitigation locked: core stays authoritative (`RISK_LOG.md`); but this constrains how far rendering can stray and is unproven without UI.
- **L7 — Thin test coverage.** Only 3 tests. No coverage for `.gaps`, `.duplicateTile`, `.outOfBounds`, rotation correctness/composition, or `.missingTile`. No solver/generator/UI/persistence tests (those features don't exist yet).
- **L8 — Monetization details unresolved.** Exact Pro vs standalone-theme boundary, price points, and theme catalog are undecided; no `.storekit` config exists.
- **L9 — No accessibility work yet.** Reduce Motion, Dynamic Type, VoiceOver labeling for a drag/rotate spatial puzzle, and color-contrast for themes are all unaddressed (no UI).
- **L10 — No CI.** No `.github` workflows; tests run only manually via `swift test`.

---

## 7. Bug & Risk Triage

> These are derived from real repo gaps (code + missing pieces) plus product/privacy/content risk. Because the app is pre-build, most "launch-blocking" items are **must-build**, not regressions.

### Launch-blocking (must fix/build before TestFlight/App Store)

| ID | Description | Where | Why blocking |
|----|-------------|-------|--------------|
| B1 | **No solvability solver.** Cannot prove a daily board is completable. | `Sources/TesseraCore` (missing F3) | An unsolvable daily destroys trust in the core promise; a daily game cannot ship without this guarantee. |
| B2 | **No deterministic generator gated by the solver.** Only one hand-authored board exists. | `Tessera/Game/Generator` (empty `.gitkeep`) | Without it there is no daily puzzle; with it but no solver gate, bad seeds ship. |
| B3 | **No interactive board / app target.** No way to actually play. | `Tessera/App`, `Tessera/Game/Board` (empty) | There is no shippable product surface; nothing runs on a device. |
| B4 | **No local persistence for streaks/progress.** | `Tessera/Features` (empty) | The daily-ritual + streak value prop fails if progress doesn't survive relaunch. |
| B5 | **No `PrivacyInfo.xcprivacy` / App Store privacy answers.** | repo root (missing) | App Store requires a privacy manifest + accurate "Data Not Collected" declaration; must exist and match the no-tracking reality (`PRIVACY_NOTES.md`). |
| B6 | **No StoreKit config / restore path (if Pro ships at launch).** | repo (missing `.storekit`, StoreKit code) | If any IAP ships, Apple requires working purchase + **Restore Purchases**; broken IAP = guaranteed rejection. *(Deferrable only if launch ships fully free.)* |
| B7 | **Rendering must not diverge from logical cells.** Breathing/organic morph could break hit-testing. | `Tessera/Game/Board` (to build) | A puzzle that mis-detects placements is unshippable; must be proven in the board UI (`RISK_LOG.md`). |
| B8 | **No Xcode project / build verification.** Only `swift test` on the core runs. | repo (no `.xcodeproj`) | Cannot produce an `.ipa`/TestFlight build; `RELEASE_CHECKLIST.md` flags `UNVERIFIED_XCODE_ENVIRONMENT`. |

### Non-blocking (ship-with, fix later)

| ID | Description | Rationale for deferral |
|----|-------------|------------------------|
| N1 | Sparse core tests (no `.gaps`/`.duplicateTile`/rotation tests). | Existing logic is exercised indirectly; add tests alongside the solver work — quality, not a launch blocker by itself. |
| N2 | UTC vs device-local daily rollover (L5). | Acceptable v1 behavior; revisit based on beta feedback. |
| N3 | No CI workflow (L10). | Manual `swift test` suffices for a solo pre-build phase; add GitHub Actions before scaling. |
| N4 | `PROJECT_DOCUMENTATION.md` previously described a generic "tutorial + starter levels" product that didn't match the daily-puzzle direction. | Doc-level mismatch (now reconciled, see §3 of this doc and the doc note); not a code risk. |
| N5 | Rotation produces negative-coordinate cells needing origin offset (L4). | Mathematically correct; only ergonomics — add a bounding-box/normalize helper when building the generator/UI. |
| N6 | macOS(.v13) platform in `Package.swift`. | Harmless (eases testing); just never present macOS as a shipping target. |
| N7 | Endless-mode difficulty curve / pacing undefined. | Endless is secondary; tune after the daily loop ships. |
| N8 | Monetization boundary/pricing undecided (L8). | Can finalize during the StoreKit phase; doesn't block the free loop. |

---

## 8. Production-Readiness Assessment

### Current estimated readiness: **15%**
Justification: the **rules core (F1) and daily seed (F2) are built, clean, and tested** (`swift test` → 3/3 passing, builds in ~8s), and the architecture/scope is genuinely well-locked (docs + conversation). That is real, load-bearing foundation — but it is roughly **one of ~ten** features. Everything the user actually touches — solver, generator, board UI, persistence, share, themes, StoreKit, app shell — is unwritten, and there is no Xcode project to even produce a build. 15% credits a solid, tested core and clear spec against a large remaining build.

### Ordered remaining-work checklist to reach 80–90% production-ready
1. **Add the solvability solver (F3) to `TesseraCore`** with deterministic backtracking exact-cover; tests for solvable→solution, unsolvable→nil, determinism, and performance.
2. **Add the daily generator (F4)** that maps `DailySeed`→board and **rejects any board failing the solver**; add a **365-day "every daily is solvable" test** (the trust gate). Add `Tile` bounding-box/normalize helper (fixes L4) for valid origins.
3. **Create the Xcode app target + SwiftUI app shell (F10/B3/B8):** entry point, navigation (Daily/Endless/Settings), light/dark design-system primitives; wire `TesseraCore` as a local package. Produce a build.
4. **Build the playable slice — interactive board (F5):** `Canvas`/`TimelineView` board, tile tray, drag + rotate + snap, all validated through the core; illegal-move feedback; solve detection. This is the "is the verb fun?" milestone.
5. **Solved-state feel (F6):** breathing morph (visual-only, logical cells fixed) + lock ripple; honor **Reduce Motion**.
6. **Local persistence (F7):** Codable/SwiftData for completed dailies, in-progress board, and streak; resume-after-kill; offline.
7. **Share card (F8):** `ImageRenderer` card (date/outcome/theme), user-initiated, first-party assets only.
8. **Privacy + App Store prep (B5):** add `PrivacyInfo.xcprivacy` (Data Not Collected), age rating, screenshots, metadata; verify offline launch.
9. **Accessibility pass (L9):** Reduce Motion, Dynamic Type, VoiceOver for the spatial puzzle, theme contrast.
10. **(Optional for launch) Monetization (F9/B6):** StoreKit 2 Pro + premium themes + `.storekit` config + **Restore**; offline entitlement cache isolated from gameplay. Defer to fast-follow if proving the free daily first.
11. **CI + regression (N1/N3):** GitHub Actions running `swift test`; expand core/solver/generator test coverage.

> Reaching **~80%** = items 1–8 done (free daily loop end-to-end on device, privacy-clean, buildable for TestFlight). **~90%** adds 9 and either 10 or a deliberate "launch fully free" decision.

### Test coverage summary
- **Tested today (3 tests, all passing):** overlap detection (`testPlacementValidationDetectsOverlap`), full solved-state with no gaps/overlaps (`testSolvedStateRequiresNoGapsOrOverlaps`), deterministic daily seed across same/adjacent UTC days + dateKey format (`testDailySeedIsDeterministicForCalendarDate`). Verified via `swift test`: build succeeds, 3/3 pass.
- **Not tested (logic exists but uncovered):** `.gaps`, `.duplicateTile`, `.missingTile`, `.outOfBounds`, rotation correctness/4-turn-identity, `requireComplete` boundary behavior.
- **Not tested (features don't exist):** solver, generator, board UI/gestures, persistence, share card, StoreKit, app shell. No UI tests, no snapshot tests, no CI.

---

## 9. Launch Checklist

App Store / privacy / safety / content items specific to Tessera:

- [ ] **Xcode project + signed build** produced; archive validates; `RELEASE_CHECKLIST.md` `UNVERIFIED_XCODE_ENVIRONMENT` cleared. *(B8)*
- [ ] **`PrivacyInfo.xcprivacy` present** declaring **no data collected / no tracking**, matching `PRIVACY_NOTES.md`. *(B5)*
- [ ] **App Store privacy "nutrition label"** set to **Data Not Collected**; confirm no SDK silently collects (none present today — keep it that way).
- [ ] **No required-reason API misuse** in the privacy manifest (timestamp/UserDefaults reasons if SwiftData/UserDefaults persistence is used).
- [ ] **Age rating:** abstract puzzle, no objectionable content → expect **4+**; confirm questionnaire answers (no gambling, no user-generated content, no contests).
- [ ] **Offline launch verified** — daily puzzle, streak persistence, and share card all work with no network. *(`RELEASE_CHECKLIST.md`)*
- [ ] **Light & dark mode** verified across iPhone sizes (small → Pro Max); safe-area correct.
- [ ] **Accessibility:** Reduce Motion disables breathing; Dynamic Type; VoiceOver labels for tiles/board; theme color-contrast meets guidance. *(L9)*
- [ ] **Every daily puzzle in the shipping seed range is solver-verified** (no unsolvable daily). *(B1/B2 — the trust gate)*
- [ ] **Rendering/hit-test parity** confirmed: breathing visuals never change logical placement detection. *(B7)*
- [ ] **StoreKit (only if IAP ships):** products match App Store Connect; sandbox purchase **and Restore Purchases** verified; entitlement cache correct offline; free daily never blocked by purchase state. *(B6)*
- [ ] **Share card content review:** first-party assets only, no copyrighted material, no PII. *(F8)*
- [ ] **No forbidden dependencies** shipped: no backend SDK, accounts, ads, analytics, Unity/RN/Flutter/web. *(`LOCKED_V1_DECISIONS.md` Exclusions; `RELEASE_CHECKLIST.md`)*
- [ ] **Metadata & screenshots** reflect the calm-daily-puzzle positioning; no promises (e.g. multiplayer, cloud) the app doesn't deliver.

---

_This document is the canonical launch-scope artifact for Tessera. Implementation status is **pre-build**: only `TesseraCore` (rules + daily seed) and its 3 tests exist; this spec is the build-to plan for everything else. See repo `Docs/` for source-of-truth design, architecture, and privacy notes._
