# Game Design Draft

## Vision

Tessera is a calm, gallery-like daily tessellation puzzle: "A living jigsaw that breathes." Players place irregular tiles into a continuous surface with generous negative space, subtle motion, light/dark palettes, and a satisfying solve ripple.

## First-Draft Tessellation Model

- **Surface/grid:** V1 starts with a discrete 2D grid surface represented by valid cells. Later visual rendering can round, bevel, and morph cell boundaries while preserving deterministic logical cells.
- **Tiles/shapes:** A tile is a set of local grid cells. Irregular/polyomino tiles are represented as cell sets plus an id. Rotation supports 0/90/180/270 degrees for the first implementation.
- **Placement:** A placement references a tile id, an origin cell, and a rotation.
- **Validation:** A placement is valid when every transformed tile cell lies inside the surface and no transformed tile cell overlaps an already occupied cell.
- **Solved state:** A board is solved only when every surface cell is occupied exactly once: no gaps, no overlaps, no out-of-bounds cells, no duplicate tile placements.

## Breathing Concept

Breathing is a visual and timing layer over the logical model. Tiles gently morph along deterministic phase curves, making edges feel alive while retaining a stable logical footprint for validation. A solved board should remain stable for a short window before the lock/ripple animation triggers.

## Daily and Endless Seeds

The daily puzzle uses a deterministic seed derived from the UTC calendar date key (`YYYY-MM-DD`) so every player receives the same puzzle for that day. Endless mode uses random seeds stored with the run so puzzles can be resumed locally.

## Streaks and Share Rules

Daily completions update local-only streak history. Share cards are generated on-device using SwiftUI `ImageRenderer`, contain no copyrighted assets, and should summarize date, outcome, time/moves once those metrics exist, and selected visual theme.
