# Simulation model foundation

No playable simulation is included in this setup step. The simulation package is pure Dart so it can be tested independently from Flutter widgets.

- The default deterministic random seed is read from `assets/data/game_constants.json` (`rng.default_seed`); its specified algorithm is Mulberry32. `SeededRng` implements the specified sequence generator.
- NASA values remain in `nasa_data.json`, with source links resolved through `sources.json`. Simulation code must obtain values using fact IDs.
- Existing assumptions and formulas remain in the original game pack. New balance choices belong in the versioned GAME VALUE files under `assets/data/extra/`.
- The Martian simulation clock and real-world progression timers are separate. Timer deadlines are stored as UTC timestamps and completion is idempotent. Backward device-clock changes do not cause early completion.

Detailed rates, step ordering, and mission balance will be documented when the simulation is designed; this foundation does not infer them.
