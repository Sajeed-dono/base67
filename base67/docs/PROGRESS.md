# BASE 67 Development Progress

Updated: 2026-11-08

## Current prompt and gate

- Current prompt: **Prompt 2 of 8 — Visual Design System, Astronauts, Persistent Base Map and Navigation.**
- Prompt 1 and Prompt 2 are complete. Prompt 3 has not started and requires user approval.
- This step implemented presentation, navigation, and accessibility support. It did not implement the simulation or mission outcomes.

## Foundation status

- `docs/GAME_BRIEF.md` follows the canonical 15-level brief. Pre-update brief and decision copies are archived under `docs/archive/`.
- `docs/DECISIONS.md` records the six-level legacy mapping into the 15-level campaign. Original `assets/data/levels.json` remains a read-only reference.
- The sequence-authoritative simulation note is `docs/SIM_MODEL.md`; the earlier rename preserved its content.
- The new 15-level campaign, chapter membership, sequential unlock chain, and site risk classifications live under `assets/data/extra/`.
- Timer and research durations remain provisional GAME VALUEs. No new balancing values were introduced in Prompt 2.
- The legacy display mapping renders the current game name as BASE 67. Tests scan Dart UI sources for the obsolete title.
- The typed repository, validator, persistent save schema, timer completion, and deterministic RNG remain in place from Prompt 1.
- The original data pack checksum test passed. `python check_data.py` reported `facts: 40 | sources: 24 | ALL OK` during Prompt 1 validation.

## Prompt 1 completion

- `flutter analyze` and `flutter test` passed at Prompt 1 completion.
- The debug-only Data Check screen is accessible from a long-press on the first prologue title and from the debug Settings menu.
- The original prologue story and choice sequence remain intact.

## Prompt 2 completion

- `lib/ui/theme.dart` defines color, spacing, radii, motion, typography, and the four text-size settings. The palette includes color-blind-safe status colors and visible status icons.
- `lib/ui/game_widgets.dart` provides the requested reusable controls and cards, including `DataChip`, `TimerCard`, `ResourceCard`, `BuildingCard`, `ResearchCard`, and `CrewAssignmentCard`.
- `lib/ui/crew_bean.dart` draws four astronaut roles, role badges, 12 suit colors, and all nine requested moods. Reduced-motion mode disables the breathing loop.
- `lib/ui/mars_base_painter.dart` draws Mars terrain and vector facilities. Built/unbuilt and upgraded facilities have distinct map states; solar panels show dust.
- Home Base reads campaign save data for facilities, crew, resource amounts, timers, site, and next goal. Unconfigured resource amounts remain visibly unset.
- Campaign Map shows all 15 levels in five visually differentiated chapters, with locked, available, completed, and mastered states. Available levels open briefings. The Mars Notebook route is present, but `assets/data/extra/fact_cards.json` currently has no card entries.
- Navigation routes cover Splash, Prologue, Home Base, Campaign Map, mission flow, build, research, crew, notebook, rewards, settings, About, Credits, Debug Design Gallery, and Debug Data Check. Later mission systems remain presentation shells for their approved steps.
- The app preserves the prologue story and decision flow. Its scene text can scroll on smaller screens at larger text sizes, and the final scene can hand off to Home Base.
- Settings persist the four text-size choices and reduced-motion preference. Reduced-motion mode also removes route fades.
- Widget tests exercise the requested reusable UI, all navigation routes, Home Base and Campaign Map at 360 dp and 1024 dp, and 1.4× text scaling.

## Visual references

- `docs/reference/` contains no files. Prompt 2 uses the sequence's written visual direction; this gap is recorded in `docs/DECISIONS.md`.

## Validation for Prompt 2

- `flutter analyze`: exit code 0; no issues found.
- `flutter test --no-pub --reporter expanded`: exit code 0; all 17 tests passed.
- The original-pack checksum test passed in the full suite. No files in the original `assets/data/` pack were edited.