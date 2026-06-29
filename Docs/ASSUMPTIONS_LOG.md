# Assumptions Log

- The logical puzzle model can start on a discrete grid while visual tile outlines later become more organic through deterministic rendering/morphing.
- UTC date keys are the initial canonical source for daily puzzle seeds; product may later decide whether daily rollover should use device-local calendar time.
- Rotation starts with quarter turns for testability and clarity; later tile sets may constrain allowed rotations per tile.
- Swift Package tests are the reliable validation path in this environment; Xcode project generation/build is deferred.
