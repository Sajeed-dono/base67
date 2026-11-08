# BASE 67 Development Progress

Updated: 2026-11-08

## Current prompt and gate

- Prompt 2 status: **COMPLETE** — its definition of done was met and verified.
- Current activity: **Prompt 2 visual reference pass IN PROGRESS** — Home Base and Campaign Map edits are complete; owner visual review remains open.
- Prompt 3 status: **NOT STARTED** — requires explicit owner approval.
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
- Home Base reads campaign save data for facilities, crew, resource amounts, timers, site, and next goal. Unconfigured resource amounts show a dash and GAME VALUE chip.
- Campaign Map shows all 15 levels in five visually differentiated chapters, with locked, available, completed, and mastered states. Available levels open briefings. The Mars Notebook route is present, but `assets/data/extra/fact_cards.json` currently has no card entries.
- Navigation routes cover Splash, Prologue, Home Base, Campaign Map, mission flow, build, research, crew, notebook, rewards, settings, About, Credits, Debug Design Gallery, and Debug Data Check. Later mission systems remain presentation shells for their approved steps.
- The app preserves the prologue story and decision flow. Its scene text can scroll on smaller screens at larger text sizes, and the final scene can hand off to Home Base.
- Settings persist the four text-size choices and reduced-motion preference. Reduced-motion mode also removes route fades.
- Widget tests exercise the requested reusable UI, all navigation routes, Home Base and Campaign Map at 360 dp and 1024 dp, and 1.4× text scaling.

## Visual references

- Read all five style references: `dribbble_01.png.png` through `dribbble_05.png.png`. They use angular navy-framed panels, cream surfaces, orange highlights, compact controls, and a dark technical atmosphere. Their artwork was not copied.
- The references were applied to Home Base and Campaign Map only. Prompt 2's winding 15-node path and five-chapter grouping remain in place.

## Prompt 2 visual polish pass

- Home Base and Campaign Map use angular navy-outlined panels with cream surfaces, bevels, and stronger shadows. The Home Base map has a subtle cartographic grid and corner markers over the original vector Mars art.
- Campaign chapter headers use rust number plates and dark panels; the winding route uses a layered track and outlined circular nodes. Labels, colors, and state behavior remain accessible and unchanged.
- Home Base navigation buttons now use high-contrast beveled surfaces with rust icon accents. All tap targets remain at least 48 dp.
- `test/prompt2_ui_test.dart` checks both screens at 360 dp and tablet widths with 1.4× text, plus chapter panels and route smoke checks.
- A live browser screenshot comparison could not be performed because the browser-control host was unavailable. Layout tests do not establish aesthetic quality; owner review of the screens is still useful.

## Validation for Prompt 2

- Final after the visual polish pass: `flutter analyze` exited 0 (`No issues found!`); `flutter test --no-pub --reporter compact` exited 0 (`All tests passed!`, 17 tests).
- The original-pack checksum test passed in the full suite. No files in the original `assets/data/` pack were edited.
