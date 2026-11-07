# BASE 67 Development Progress

Updated: 2026-11-08

## Current prompt and gate

- **Current prompt: Prompt 1 of 8 — Foundation, Game Brief, Data Layer and Campaign Architecture.**
- **Prompt 1 is complete.** Do not begin Prompt 2 until the user approves moving on.
- This update completed Prompt 1 foundation work only. It did not start Prompt 2 or implement a playable simulation.

## Completed and verified

- `docs/GAME_BRIEF.md` matches the canonical 15-level brief in Prompt 1. The pre-update brief and decisions snapshots are preserved under `docs/archive/`.
- `docs/DECISIONS.md` now maps all six original `levels.json` entries, their lesson IDs, and their win-rule intent into the 15-level campaign. The legacy file remains read-only.
- The simulation note is at the sequence-required `docs/SIM_MODEL.md`; its content was preserved during rename.
- All original data files remain unchanged. The SHA-256 test passed. The supplied data checker passed in the previous foundation session; it was also rerun during this Prompt 1 task (see validation below).
- The 15-level campaign, chapter membership, sequential unlock chain, and site risk classifications are in extra GAME VALUE configuration.
- Building and research definitions reference the provisional timer rules. Timer and research durations come from the updated GDD proposals and remain explicitly provisional GAME VALUEs.
- `display_text.json` maps the legacy title to `BASE 67`. `GameDataRepository.displayText` applies that mapping. Tests cover displayed radio text and scan Dart UI sources for the obsolete title.
- All bundled JSON files load into typed `DataDocument`/`DataRecord` structures. NASA facts and sources also have dedicated typed models and repository lookup methods.
- The validator checks NASA hosts and fact/source references, metadata classes, campaign ordering and chapters, progression unlocks, building/equipment/level/timer references, research prerequisites/timers, crew task references, timer ranges and prerequisites, and site risk labels.
- The campaign save schema includes crew names, site, cargo/inventory, buildings, resources, research, timer jobs/timestamps, event history, rewards, results, and settings. Local SharedPreferences storage is abstracted behind a testable key-value interface.
- Tests cover data validation and loading, original-pack checksums, display text, deterministic RNG, campaign save/store round-trip, timer completion idempotence after serialization/restart, the prologue entry point, and the debug-only Data Check entry.
- `lib/game/` remains an empty implementation area with `.gitkeep` so it is tracked.

## Prompt 1 completion

- `flutter analyze` is clean after a brace-only style fix to the existing site timeout condition. The change preserves the same conditional and timeout action.
- The first prologue title has a long-press Data Check entry point only in debug builds. The widget test opens the Data Check screen through that entry point; the entry key and handler are gated by `kDebugMode`.
- No playable simulation was added, as Prompt 1 requires.

## Validation for this Prompt 1 task

- `flutter analyze`: exit code 0; no issues found.
- `flutter test --no-pub --reporter expanded`: exit code 0; all 10 tests passed, including the debug Data Check entry test.
- `python check_data.py`: facts: 40 | sources: 24 | ALL OK.
- `git diff -- assets/data :!assets/data/extra/**` returned no diff. The original data directory is untracked in this Git root, so the checksum test also verified each original pack file against the saved SHA-256 manifest. The prologue change is limited to braces and a debug-only Data Check gesture.
