# GAME BRIEF: BASE 67

## 1. Game identity

BASE 67 is a 2D, offline-first, portrait-first Android Mars settlement and junior astronaut mission-training game for children aged 10–14.

Current owner-authorized assignment (2026-11-12): finish the M2-M10 visual/gameplay integration roadmap through Level 2, sequentially under one authorization. M1 is validated. M2-M9 are implemented for review; M10 remains PARTIAL pending Android/final acceptance. The analyzer passed with zero issues in the prior cleanup session; the owner now reports the full Flutter suite passed and a successful 52.2 MB release APK build. No new Level 3 or Prompt 7 work. The owner requested starting damage be designed separately, so the existing construction-first Level 1 opening is preserved.

Owner-approved Phase 1 presentation direction (2026-11-11): render the persistent colony with original 2.5D code art over a stable world coordinate system, a bounded follow/pan/zoom camera, readable contextual inspection and the existing hybrid astronaut movement. This is a presentation evolution of the Flutter game, not a replacement simulation, economy or save architecture. The implementation is pending owner validation. All 15 levels and existing task/resource authorities remain in place.

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
2. Power Storage: batteries, capacity, charging, stored energy and the existing habitat heater's local switch. Switching it off saves power but cools the habitat. Essential life support stays on; central management and its Power Control Station prerequisite remain in Level 3.
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


## 17. Owner-approved policy direction (2026-11-10)

These requirements supplement the brief; they do not claim that future screens or campaign systems are implemented.

- Retain crew opinions and individual votes before important choices; the commander can override them. Show educational reactions to consequences, initially without numerical morale penalties (Prompts 5-6). Preserve the original story, personalities, four-person crew and investigation objectives.
- Use one engineering lane for construction/upgrades/timed repairs plus one research lane. Crew cannot hold conflicting tasks; queues reserve neither resources nor crew. Keep essential recovery accessible.
- Replace once-per-level salvage with validated, restricted assistance for mandatory objectives/essential repairs. Restore assistance fully on cancellation; ordinary payments retain 50% refunds. Never convert assistance into optional purchasing funds.
- Starting equipment is packed stock. Transfer/reserve it exactly once into installed facilities; material installation costs are charged once with no second equipment purchase. Counts, tiers, damage and operating state are separate. Reuse original unit limits where defined.
- An assigned Engineer halves eligible timed repair duration without an additional spare discount. Immediate field repair and timed major repair are distinct.
- Existing-campaign prologue replay must become story-only; starting resources are granted once and reset requires explicit confirmation. Centralized save mutation must reject stale callbacks. These app safeguards are still pending 4B-2.
- Per-job clock checkpoints must prevent increasing remaining work, reversing completions or contaminating new job timestamps after corrections. Offline timers never advance survival time.
- Preserve the initial habitat; later expansion is a distinct milestone. The finale combines production with planned survival supplies, separate from construction-material resupply. Exact balance needs a proposal before Prompt 6; no silent refills.
- Keep chapter badges and topic badges separate. Add informative daily sol summaries and retain optional/post-campaign improvement goals. Define lab/rover dependencies before they are needed. Preserve Earth-day-to-sol source conversion. First guided construction must be short or free; its duration is not selected here.
- Evaluate transactional storage separately after the service-policy follow-up; no package is selected and schema 3/app wiring require their own approval.


## 18. Current visual/gameplay integration boundary (2026-11-12)

Original cream/rust/blue-grey modular code art sits on a sunlit Martian presentation world, with dark mission-control telemetry and menu/support screens. The stable world, camera, astronaut identities/assignments and actual progression/engine outcomes remain authoritative. Terrain and building drawings are cached separately from actors; decorative dust uses presentation time only and respects reduced motion. No decorative surface is a resource node, installation or collision change.

Home/mission telemetry reads actual reserves and saved generation. Saved job progress reads the reconciled remaining-work clock. Crew/facility inspection leads to real management routes; camera framing and walking never perform work. Existing Level 2 local heater trade-offs and unsaved preview remain. Successful debrief and campaign details distinguish configured future rewards from recorded one-time resupply. No new scoring/badge rules or lab/rover functions are inferred from the visual references.

Automated reference strategies now complete Levels 1 and 2 at each of the four sites, including a mid-mission restart. This is not acceptance of all loadouts/histories, timer pacing, physical-device durability, child usability or final visual quality. The original prologue story code and all data assets remain unchanged; the starting-damage scenario is a separate owner-requested design task. The analyzer/full-suite/release-build gates have now passed as attributed in PROGRESS; Android device, accessibility/performance and final owner art acceptance remain pending.


Current prompt authority: docs/BASE_67_Codex_Prompt_Sequence.txt includes historical prompts and the consolidated M2-M10/final-acceptance records. No standalone M2 historical source was found; its exact assignment excerpt is preserved. The latest consolidation task authorizes Git delivery only and changes no game rules. Starting damage remains a separate design decision.
