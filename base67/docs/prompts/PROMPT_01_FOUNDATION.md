<!-- Paste this prompt into Codex ONLY after the vault load message (docs/vault/00_START_HERE.md) and only when the previous prompt is verified complete in docs/PROGRESS.md. -->

# PROMPT 1 OF 8 — FOUNDATION, GAME BRIEF, DATA LAYER AND CAMPAIGN ARCHITECTURE

You are working in an existing Flutter project. The BASE 67 prologue already exists and runs from the current application entry point. We are expanding it into a complete, kid-friendly, 2D, offline-first Android game for the NASA Space Apps 2026 challenge, “Build a Junior Astronaut Mission Trainer.”

Build the project in eight controlled steps. This is step 1. Do not build the playable simulation yet.

## A. Inspect before changing anything

1. Read the entire repository and report its current structure.
2. Inspect `lib/`, `pubspec.yaml`, `assets/`, `docs/`, Android configuration, and existing tests.
3. Identify the existing prologue implementation and confirm that it runs.
4. Check for the existing data pack in `assets/data/`, including:
   - `nasa_data.json`
   - `sources.json`
   - `game_constants.json`
   - `sites.json`
   - `equipment.json`
   - `loads.json`
   - `levels.json`
   - `events.json`
   - `lessons.json`
   - `crew.json`
   - `radio.json`
   - `badges.json`
   - `credits.json`
   - `credits.md`
   - `check_data.py`
   - `README.md`
5. Check `docs/source/` for the BASE 67 prologue PDF and the existing video/story script. Check `docs/reference/` for any supplied visual references.
6. If a required file is missing, report the exact missing files. Do not invent their contents or silently replace them.

## B. Create `docs/GAME_BRIEF.md`

Create the following updated brief. It is the source of truth for all later prompts. If an implementation detail conflicts with this brief, follow this brief and record the conflict in `docs/DECISIONS.md`.

```markdown
# GAME BRIEF: BASE 67

## 1. Game identity

BASE 67 is a 2D, offline-first, portrait-first Android Mars settlement and junior astronaut mission-training game for children aged 10–14.

The player becomes the commander of a four-person crew sent to Mars. The player establishes and manages one persistent Mars base. The same base, crew, facilities, research progress, resources, and mission history carry forward throughout the campaign.

The game has 15 progressively challenging levels grouped into five chapters. Each level introduces a manageable new concept or system. Later levels combine previously learned systems so that the player gradually learns to manage a functioning Mars settlement.

The game should feel like a small, thoughtful settlement-management game, not a collection of disconnected survival mini-games.

## 2. Core gameplay loop

The core loop is:

1. Learn a new Mars science or settlement-management concept.
2. Review the base, crew, resources, forecast, and mission objective.
3. Make a decision: build, upgrade, research, assign crew, manage energy, gather resources, or prepare for an event.
4. Let the simulation run and observe the consequences.
5. Respond to changing conditions and unexpected events.
6. Review the outcome and learn why a decision worked or failed.
7. Unlock the next level and continue developing the same base.

Construction, upgrades, research, repairs, and selected crew tasks may use real-world timers. These timers are optional progression pacing, not a requirement to keep the app open. Progress must continue safely while the app is closed.

## 3. Persistent base — mandatory design

There is ONE persistent Mars base for the entire 15-level campaign.

- The player does not start from zero at every level.
- Buildings, upgrades, research, crew, mission patch, unlocked technologies, and campaign progress persist.
- A level adds a new challenge, system, location, event, or management responsibility to the existing base.
- A level may temporarily provide a scenario-specific mission objective or resource allocation, but it must not erase the player's established base.
- The Home Map is the player's actual base and campaign hub, not merely a menu of unrelated level buttons.
- New buildings and systems appear physically on the base map when constructed.
- The base should visibly evolve from a small landing site into a functioning Mars settlement.

## 4. Campaign structure: 15 levels, five chapters

### Chapter 1 — Power and Energy
1. First Light: sunlight, solar panels, and the first energy supply.
2. Power Storage: batteries, capacity, charging, and stored energy.
3. Energy Manager: power consumption, essential loads, and trade-offs.

### Chapter 2 — Martian Weather
4. Dust on Mars: dust accumulation and reduced panel efficiency.
5. The Great Storm: dust storms, forecasts, panel cleaning, and load shedding.

### Chapter 3 — Oxygen and Life Support
6. Greenhouse Online: greenhouse construction, lights, and basic operation.
7. Breathing Matters: oxygen production, consumption, and emergency reserves.

### Chapter 4 — Radiation, Water and Food
8. Radiation Alert: radiation exposure and monitoring.
9. Shelter Protocol: radiation shielding, safe shelter, and solar particle events.
10. Finding Water: ice surveys, landing-site conditions, and evidence-based exploration.
11. Ice Operations: ice mining, extraction capacity, and water reserves.
12. Food and Supplies: food consumption, storage, greenhouse contribution, and supply planning.

### Chapter 5 — Crew Management and Mission Survival
13. Crew Care: health, morale, temperature, workload, rest, and crew assignments.
14. Mission Control: forecasts, maintenance, research, logistics, and multiple systems operating together.
15. The Final Mission: a complete settlement-management challenge combining the systems learned throughout the campaign.

Each level must have a clear learning objective, a clear mission objective, a new concept or management responsibility, and a short debrief. Avoid introducing several unrelated concepts at once.

## 5. Five campaign chapters

Chapter 1: Power and Energy — Levels 1–3.
Chapter 2: Martian Weather — Levels 4–5.
Chapter 3: Oxygen and Life Support — Levels 6–7.
Chapter 4: Radiation, Water and Food — Levels 8–12.
Chapter 5: Crew Management and Mission Survival — Levels 13–15.

## 6. Persistent progression systems

The campaign includes:

- Base construction and building upgrades.
- Research and technology unlocks.
- Crew assignments and role-based advantages.
- Resource storage and production.
- Repairs and maintenance.
- A Martian sol calendar and simulation clock.
- Forecasts and mission events.
- A campaign map showing the 15 levels and five chapters.
- A Mars Notebook that unlocks educational facts progressively.
- Badges, mission patches, and a Junior Astronaut certificate.

Construction and research times are GAME VALUE design choices, not NASA facts. Store them in separate, documented configuration files.

## 7. Real-time timers and offline progression

Some activities use real-world elapsed time:

- Construction and building upgrades.
- Research projects.
- Major repairs.
- Selected long-running extraction or production projects.

Rules:

- The player must be able to close the app. Timers continue based on saved timestamps.
- When the app reopens, calculate elapsed time using saved UTC timestamps and complete any finished activity.
- Never require the player to keep the screen open.
- Never punish a child for being offline or not opening the game.
- No crew member dies, disappears, or suffers severe harm because the player did not return.
- No premium currency, paid speed-up, ad-gated timer, loot box, manipulative streak, or artificial urgency.
- Do not create a timer that blocks all meaningful gameplay. While something is building or researching, the player can inspect the base, read Notebook entries, plan, complete available missions, manage other systems, or perform other unlocked activities.
- Clearly show remaining time and what the activity will unlock.
- Use a consistent timer service and persist start/end timestamps.
- Prevent duplicate completion or timer rewards after app restarts.
- Keep real-world timers separate from the in-game Martian clock. A 30-minute construction timer must not secretly equal a particular number of Martian sols.
- The app must handle device clock changes defensively. Do not grant duplicate rewards or corrupt saves if the clock moves backwards. Document the chosen approach.

## 8. Two different clocks

The game has two distinct concepts of time:

A. Martian simulation time:
- Used for sunlight, day/night, resource consumption, weather, radiation, and survival simulation.
- One sol is read from NASA data (`sol_hours`, 24.6597 hours).
- One simulation tick is one hour unless the simulation design requires a documented smaller step.
- Daylight uses the existing game configuration.

B. Real-world progression time:
- Used for construction, upgrades, research, and selected maintenance tasks.
- Based on elapsed real-world time.
- Continues while the app is closed.
- Must never be confused with Martian sols.

## 9. Data integrity: three data classes

Never mix these classes:

- NASA DATA: values in `nasa_data.json`, with source IDs in `sources.json`.
- GAME VALUE: design choices in other game JSON files and new files under `assets/data/extra/`.
- DERIVED: values calculated by formulas using NASA facts and/or explicitly labelled game assumptions.

No NASA number may be typed directly into Dart code. Read it by fact ID. Every displayed scientific or simulation number must show a small NASA DATA, GAME VALUE, or DERIVED chip.

Never edit the original data pack. New campaign and design values go into new files under `assets/data/extra/`, each with `_meta.data_class = "GAME_VALUE"` where appropriate.

## 10. Offline and content rules

- No network calls, web views, remote fonts, or remote images.
- Bundle all assets.
- Do not add Android INTERNET permission to the release manifest unless a future, explicitly approved requirement changes this rule.
- Never use the NASA logo or insignia. “NASA data” may appear as plain text.
- Credits must be read from the supplied credits files.
- The About screen must say: “Not yet tested with students.” Do not claim proven learning outcomes.

## 11. Child-friendly design

- Target reading level: approximately grade 5–6.
- Use short sentences, clear icons, and progressive disclosure.
- Minimum interactive target size: 48 dp.
- Avoid graphic harm. Crew members never die. If a crew member needs help, pause or soften the relevant challenge and explain what happened.
- Failure is feedback, not punishment. Offer retry, explanation, and a way to improve.
- Avoid manipulative retention systems, pressure, fear-based alerts, and punitive timers.
- Keep the first minute of every level understandable and rewarding.
- Provide reduced-motion and text-size settings.
- Never rely on colour alone to communicate danger or success.

## 12. Crew

Four crew roles are used throughout the campaign:

- Commander — Unshakable; leadership, planning, morale, and power priorities.
- Engineer — Technical Genius; construction, repair, maintenance, and panel cleaning.
- Scientist — Keen Observer; research, ice surveys, science observations, and forecasts.
- Medic — Field Medic; health checks, recovery, shelter drills, and crew wellbeing.

Crew names are chosen by the player. The supplied crew JSON contains templates and traits; preserve the source terminology unless a documented design decision changes it.

## 13. Landing sites

Keep the four original landing sites and the difficulty labels from the BASE 67 source material:

- Gale — EASY
- Arcadia — MEDIUM
- Deuteronilus — HARD
- Equatorial — EXTREME

Use the corrected GAME VALUE site-risk descriptions and risk effects in the extra data layer. Do not display any contradictory original description as if it overrides the selected risk classification.

## 14. Deterministic simulation

Use the existing deterministic RNG requirement and default seed from the source data. A retry of the same mission with the same seed and same inputs must produce the same result. Any intentional variation must be seeded and testable.

## 15. Motivation and rewards

- A visible next goal on the campaign map.
- Small early success in every level.
- 1–3 stars or equivalent clear performance feedback.
- Badges from the data pack where appropriate.
- Mars Notebook facts unlocked as the player encounters topics.
- A mission patch.
- A Junior Astronaut certificate after completing Level 15.
- No reward system that pressures children to return every day.

## 16. Project structure

Use a clean separation:

- `lib/app/` — routing, app state, persistence coordination.
- `lib/data/` — typed models, repository, validation.
- `lib/sim/` — pure Dart simulation engine, no Flutter imports.
- `lib/progression/` — construction, research, timers, campaign unlocks.
- `lib/ui/` — theme, widgets, maps, scenery, characters.
- `lib/prologue/` — existing prologue.
- `lib/game/` — level and mission presentation.
- `assets/data/` — original read-only data pack.
- `assets/data/extra/` — new GAME VALUE configuration.
- `docs/` — design, decisions, simulation model, QA and project documentation.
```

## C. Create the campaign and progression data architecture

Do not modify the original JSON files. Add new files under `assets/data/extra/` as needed. At minimum, plan and document:

- `campaign.json` — the 15-level campaign, chapter membership, unlock order, objectives, learning objectives, and new mechanics.
- `buildings.json` — facility definitions, construction requirements, upgrade levels, build durations, and unlock requirements.
- `research.json` — technology tree, prerequisites, durations, effects, and unlocks.
- `progression_rules.json` — campaign progression, base persistence, rewards, and unlock rules.
- `timer_rules.json` — timer categories, duration rules, timestamp handling, and offline completion rules.
- `resource_economy.json` — resource capacities, costs, production, and GAME VALUE assumptions.
- `crew_assignments.json` — role-based tasks, durations, skill effects, and assignment restrictions.
- `sim_params.json` — simulation-only assumptions and balance parameters.
- `site_risk.json` — corrected site risk levels, descriptions, and effects.
- `tutorial.json` — tutorial triggers and progressive hints.
- `scoring.json` — stars, mission ratings, and completion conditions.
- `fact_cards.json` — Notebook content templates linked to NASA fact IDs.

Every new configuration file must be versioned, validated, and documented. Do not create all files with invented final numbers if the source does not support them. Use clearly labelled provisional GAME VALUE defaults and record them in `docs/DECISIONS.md`.

## D. Project setup

- Keep dependencies minimal. Use `provider` for state and `shared_preferences` for simple local persistence unless the existing project already has a better compatible approach.
- If a robust timestamp, database, or migration requirement cannot be safely met with `shared_preferences`, explain why and choose the simplest reliable local-only option. Do not add a cloud backend.
- Declare all bundled data assets in `pubspec.yaml`.
- Create the folder layout from the brief.
- Move the existing prologue into `lib/prologue/` without changing its behaviour.
- Keep `lib/main.dart` small.

## E. Data layer

Create typed Dart models and a repository for all original and new data files.

Requirements:
- Load the bundled JSON once and expose typed data.
- Provide methods such as `repo.fact('rad_gale_surface')` and `repo.source('S02')`.
- Implement `DataClass { nasa, game, derived }` and a helper for displaying the correct chip.
- Implement a validator equivalent to the supplied `check_data.py`, including source references, NASA hosts, fact references, and data-class metadata.
- Add validation for the 15-level campaign, building prerequisites, research prerequisites, timer definitions, and unlock references.
- Add a debug-only Data Check screen.
- Never put scientific source values directly into UI or simulation code.

## F. Tests

Test:
- All original data files load and validate.
- Every NASA fact and source reference resolves.
- The original data pack has not been changed.
- All 15 campaign levels exist and are ordered correctly.
- All chapter references resolve.
- Every building, research project, crew task, and timer prerequisite resolves.
- The same seed produces deterministic simulation inputs.
- Persistent campaign state can be saved and restored.
- Real-world timers do not complete twice after restart.
- The prologue still works.

## Definition of done

`flutter analyze` is clean. Tests pass. The original prologue still runs. Original data files remain unchanged. Create `docs/GAME_BRIEF.md`, `docs/PROGRESS.md`, and `docs/DECISIONS.md`. Update progress and report what was created, test results, and any missing or ambiguous data. Do not start Prompt 2.
