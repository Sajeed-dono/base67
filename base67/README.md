# BASE 67

BASE 67 is an offline-first Flutter project for a junior astronaut mission trainer. This setup step preserves the existing eight-scene prologue and establishes the data and campaign foundation. It does not yet contain the playable settlement simulation.

## Project map

- `lib/main.dart` starts the existing prologue in `lib/prologue/`.
- `lib/data/` loads bundled JSON once, exposes NASA facts and sources by ID, and validates original and extra data.
- `lib/sim/` contains pure Dart deterministic simulation utilities.
- `lib/app/` contains the local persistent campaign save model and store.
- `lib/progression/` contains real-time timer completion rules.
- `assets/data/` is the supplied original data pack. Do not edit it.
- `assets/data/extra/` contains versioned provisional GAME VALUE campaign and system configuration.
- `docs/` contains the game brief, decisions, and supplied source material.

## Data checks

Run the original pack checker from its directory:

```powershell
Set-Location assets/data; python check_data.py
```

Run Flutter checks after dependencies are available:

```powershell
flutter analyze
flutter test
```

`GameDataRepository.load()` loads all bundled JSON. `fact('rad_gale_surface')` and `source('S02')` retrieve NASA records. `DataClassChip` displays the required NASA DATA, GAME VALUE, or DERIVED label. The Data Check screen is intended for debug builds.

Campaign and timer design are provisional until values are balanced and reviewed. See [docs/GAME_BRIEF.md](docs/GAME_BRIEF.md) and [docs/DECISIONS.md](docs/DECISIONS.md).

