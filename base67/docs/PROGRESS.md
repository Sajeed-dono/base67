# BASE 67 Development Progress

Updated: 2026-11-09

## Current prompt and gate

- Prompt 2 status: **COMPLETE** — visual reference pass reviewed by the owner and committed as `43e15ac`.
- Current activity: **Prompt 3 of 8 — implementation complete and locally verified; owner commit is pending**.
- Prompt 4 status: **NOT STARTED**.
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

## Prompt 3 implementation status

- The prologue now saves four named roles, whole-number ages, suit/visor/face choices, landing site, starting cargo and inventory, initial habitat and landing craft, campaign state, resource stores/capacities, research, jobs, patch/name fields, deterministic seed, event history, settings, and schema version 2 in the existing local campaign save.
- Crew age accepts a positive one- or two-digit whole number. The source supplies no age range; this technical limit remains provisional and is listed in `docs/vault/10_OPEN_QUESTIONS.md`.
- The site screen keeps its 60-second countdown. Expiry picks a deterministic random site, explains the choice, and lets the player change it before confirming. Site numeric facts are repository lookups with NASA DATA chips; GAME VALUE site risk is shown separately.
- Cargo reads Level 1's allowed equipment and budget from the original read-only data. The budget and costs are in points. Cargo validation, available equipment, locked equipment, and repository-backed solar/battery previews are implemented. No timer or research values were added.
- Completing the prologue saves state and routes to the persistent Home Base with First Light available. Settings now offers replay without clearing campaign state and a reset action behind confirmation.
- The eight-scene dialogue uses `docs/source/BASE_67_Prologue_Preview.pdf`. The prompt's named `docs/source/BASE_67.pdf` was not found; `docs/source/BASE 67.pdf` is a different earlier script. The source correction is logged in decisions and open questions.
- `test/prompt3_prologue_test.dart` covers token enforcement, save/load and schema migration, cargo over-budget rejection, the editable random site timeout, and completing the prologue with fake inputs through Home Base. It lists the `lib/ui/**` exemptions (theme, shared widgets, CustomPainter scenery, and CrewBean art).
- Latest validation: `flutter analyze` exited 0 (`No issues found!`, 0.9s); `flutter test` exited 0 (`All tests passed!`, 24 tests). Crew, site, and cargo layouts pass at 360 dp and 1024 dp with 1.4× text; long site and cargo dialogue scrolls within the shared theme-token viewport.
- Prompt 3 is locally implemented and verified. It remains pending owner commit per the vault's completion gate. Prompt 4 is **NOT STARTED**.
