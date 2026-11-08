<!-- Paste this prompt into Codex ONLY after the vault load message (docs/vault/00_START_HERE.md) and only when the previous prompt is verified complete in docs/PROGRESS.md. -->

# PROMPT 5 OF 8 — LEVELS 1–7: POWER, WEATHER, GREENHOUSE AND OXYGEN

First read `docs/GAME_BRIEF.md`, `docs/PROGRESS.md`, `docs/SIM_MODEL.md`, `docs/DECISIONS.md`, and the campaign data. This is step 5 of 8. Implement the shared mission gameplay screen and make Levels 1–7 playable.

## A. Shared mission flow

Every level follows this structure:

1. Briefing: introduce the new concept and explain the mission goal.
2. Base review: show the current persistent base, crew, resources, and relevant forecast.
3. Planning: allow only currently unlocked equipment and options. Do not reset the base.
4. Mission: run the simulation and let the player make decisions.
5. Debrief: show outcome, resource changes, what worked, what needs improvement, and a short lesson.
6. Return to the same Home Base with all legitimate progress retained.

The player must be able to access the base and other non-blocked activities while construction or research timers are running.

## B. Mission screen

Portrait layout:
- Top: level name, chapter, sol/time, forecast, pause.
- Center: live visual of the persistent base and relevant environment.
- Resource strip: only the values introduced so far, with progressive disclosure.
- Controls: available actions and system switches for the current level.
- Crew: visible status and current assignments.
- Dave: friendly hints and explanations.
- Mission Control: event warnings and radio messages.

Every number shown must carry the correct data chip. Use concise consequence text when the player changes a system.

## C. Tutorials and motivation

- Introduce only one new idea at a time.
- Provide a small early success in every level.
- Hints have three strengths: gentle nudge, stronger hint, direct suggestion.
- Hints do not remove the ability to learn or retry.
- Contextual prompts should stop appearing after the player has learned the interaction.
- Avoid long text blocks during active play.
- Explain failures with a relevant lesson and a clear alternative action.

## D. Level implementation

### Level 1 — First Light
Learning: sunlight can be converted into electrical energy.
New system: solar panels and initial power generation.
Teach the player to place/activate the first solar panel and observe energy generation.
Goal: establish a safe initial energy supply and understand the solar meter.
Keep the first interaction very simple.

### Level 2 — Power Storage
Learning: energy generated during daylight can be stored for later.
New system: batteries and storage capacity.
Teach charging during daylight and using stored energy at night.
Goal: maintain the configured safe battery reserve through a day/night cycle.

### Level 3 — Energy Manager
Learning: every powered system consumes energy, and priorities matter.
New system: switchable power loads and load priorities.
Teach the player to distinguish essential systems from optional systems.
Goal: keep essential life-support power running while managing optional loads.

### Level 4 — Dust on Mars
Learning: dust can reduce the sunlight reaching solar panels and reduce panel efficiency.
New system: panel dust accumulation.
Show a visual change to the panels and explain the effect on generation.
Goal: identify when dust is becoming a problem and understand the maintenance response.

### Level 5 — The Great Storm
Learning: a major dust storm can sharply reduce sunlight.
New systems: storm forecasts, panel cleaning, and load shedding.
Show a Mission Control warning before the storm. Let the player prepare.
Goal: survive the storm without losing essential power.
Use the NASA tau fact card accurately. Clearly distinguish measured NASA examples from the game storm profile.

### Level 6 — Greenhouse Online
Learning: a greenhouse can support food production and contribute to life support, but it needs resources and power.
New system: greenhouse construction and operation.
Construction may use a real-world timer, but the player must have other meaningful activities while waiting.
Goal: construct and activate the greenhouse, understand its power cost, and observe its contribution.

### Level 7 — Breathing Matters
Learning: oxygen is essential, is consumed by the crew, and must be managed as a reserve.
New system: oxygen monitoring and production/reserve management.
Show oxygen only when it becomes relevant. Explain the relationship between crew size, consumption, and production.
Goal: maintain the mission's oxygen safety reserve.

## E. Construction and research in Levels 1–7

Introduce the building and research systems gradually:
- Early levels teach the first facility build and battery installation.
- Later levels introduce greenhouse construction and the first research unlocks.
- Show the duration, requirements, and benefit before confirming a job.
- Never force a child to wait with no alternative activity.
- Do not make the mission unwinnable because an optional timer has not finished.
- Keep initial durations short and use the provisional configuration values.

## F. What-went-wrong and debrief

For failure or near-failure, show:
- What happened in simple language.
- A small graph comparing the player's result with a sensible alternative where useful.
- Up to three lesson points.
- Retry, return to base, or continue with an available alternative.
- Same seed on retry unless the player explicitly starts a new run.

## G. Definition of done

Levels 1–7 are playable from briefing to debrief and return to the same persistent base. Tests verify:
- Correct systems appear at the intended level.
- Previously unlocked facilities and research persist.
- A level does not reset the base.
- Tutorials trigger correctly.
- The timer service does not block unrelated gameplay.
- Resource and power systems work.
- Debrief and retry preserve the expected state.
- `flutter analyze` clean.
Update `docs/PROGRESS.md`, `docs/SIM_MODEL.md`, and `docs/DECISIONS.md`.
