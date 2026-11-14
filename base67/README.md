# BASE 67

BASE 67 is an offline-first Flutter project for a junior astronaut mission trainer. This setup step preserves the existing eight-scene prologue and establishes the data and campaign foundation. It does not yet contain the playable settlement simulation.

## Android APK

The checked-in release package is [`BASE 67.apk`](BASE%2067.apk). To use it,
copy it to an Android phone or tablet, open it with the file manager, allow
installation from that source when prompted, and launch **BASE 67** after
installation.

With ADB, install or update it from the `base67` directory:

```bash
adb install -r "BASE 67.apk"
```

The release build script produces a new package named `Base 67.apk` in
`dist/`, together with `dist/Base 67.apk.sha256`:

```powershell
.\build_base67.ps1
```

The script requires Flutter and a configured Android SDK. The checksum file
can be used to verify the generated APK before copying it to a device.

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

Run the app on a connected device or emulator during development:

```powershell
flutter run
```

`GameDataRepository.load()` loads all bundled JSON. `fact('rad_gale_surface')` and `source('S02')` retrieve NASA records. `DataClassChip` displays the required NASA DATA, GAME VALUE, or DERIVED label. The Data Check screen is intended for debug builds.

Campaign and timer design are provisional until values are balanced and reviewed. See [docs/GAME_BRIEF.md](docs/GAME_BRIEF.md) and [docs/DECISIONS.md](docs/DECISIONS.md).
