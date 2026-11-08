<!-- Paste this prompt into Codex ONLY after the vault load message (docs/vault/00_START_HERE.md) and only when the previous prompt is verified complete in docs/PROGRESS.md. -->

# PROMPT 4 OF 8 — SIMULATION ENGINE, RESOURCE MODEL AND REAL-TIME PROGRESSION SERVICES

First read `docs/GAME_BRIEF.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`, and the existing data pack. This is step 4 of 8. Build the simulation and progression services. The simulation engine must be pure Dart and must not import Flutter.

## A. Separate the two clocks

Implement two independent clock systems:

1. `SimulationClock`: advances Martian simulation time in controlled ticks. It drives sunlight, day/night, resource consumption, production, weather, radiation, and mission events.
2. `RealTimeProgressionService`: calculates elapsed real-world time for construction, upgrades, research, and selected maintenance jobs.

Never use a construction timer to advance the Martian sol clock. Never assume that one real-world minute equals a fixed number of simulation hours unless a separate, documented gameplay rule explicitly says so.

## B. Simulation model

Use the original NASA facts and game configuration. Read all NASA values by fact ID. Do not hard-code them.

Implement the existing model where appropriate:
- Martian sol length from `sol_hours`.
- Daylight curve from the configured daylight hours.
- Solar generation from irradiance, panel area, efficiency, site factor, atmospheric dust, and panel dust.
- Battery charge and discharge, capacity, and safe reserve.
- Power loads and load shedding.
- Habitat temperature and heater behaviour.
- Crew oxygen, water, and food consumption.
- Greenhouse contribution to food and oxygen.
- Ice mining and water storage.
- Radiation accumulation, shielding, and shelter.
- Scripted and seeded random events.
- Repairs, panel cleaning, and crew actions.

Retain the original documented NASA/game assumptions where they remain applicable. If a model must change to support the 15-level design, explain the change in `docs/SIM_MODEL.md` and record it in `docs/DECISIONS.md`.

## C. Resource and facility model

Represent resources with:
- Current quantity.
- Maximum storage capacity.
- Production rate.
- Consumption rate.
- Source or process responsible for changes.
- Data class for displayed numeric values.

Facilities should have:
- Ownership/build state.
- Level or upgrade tier.
- Construction/upgrade status.
- Operating state.
- Power demand.
- Production or service effect.
- Maintenance/damage state.
- Unlock requirements.

The simulation must distinguish a facility that is not built from one that is built but switched off, damaged, under construction, or out of resources.

## D. Construction and upgrade timer service

Implement a persistent job system for:
- Initial construction.
- Building upgrades.
- Selected facility repairs.
- Major facility restoration.

Each job stores:
- Unique job ID.
- Facility ID.
- Job type.
- Start timestamp.
- Expected completion timestamp.
- Required materials/resources.
- Crew assignment, if any.
- Completion effect.
- Status: queued, active, completed, cancelled, or blocked.

The timer service must:
- Persist timestamps.
- Calculate remaining duration from real elapsed time.
- Complete jobs exactly once.
- Restore active jobs after app restart.
- Handle app backgrounding and offline time.
- Prevent duplicate resource deductions or duplicate unlocks.
- Handle invalid/backwards clock changes defensively.
- Show clear remaining-time information to the UI.

Use provisional GAME VALUE durations in configuration. Initial balancing suggestions, not final truths:
- Small solar panel installation: approximately 5–15 minutes.
- Battery installation: approximately 15–30 minutes.
- Greenhouse construction: approximately 30–60 minutes.
- Routine repair: approximately 5–20 minutes.
- Ice extraction facility: approximately 15–45 minutes.
- Oxygen/life-support upgrade: approximately 30–60 minutes.
- Habitat expansion: approximately 1–3 hours.
- Radiation shielding installation: approximately 2–4 hours.
- Rover construction: approximately 2–5 hours.

Do not make these exact numbers hard-coded. Put them in `buildings.json` or `timer_rules.json`, mark them GAME VALUE, and make them easy to balance.

These timers are pacing estimates, not real engineering estimates and not NASA data.

## E. Research service

Implement a technology/research tree with:
- Research ID and display name.
- Description in child-friendly language.
- Prerequisites.
- Duration.
- Optional crew assignment.
- Unlock/effect.
- Status and completion timestamp.

Initial suggested research topics and provisional durations:
- Solar Energy Fundamentals — 10 minutes.
- Advanced Battery Systems — 30 minutes.
- Dust Protection Technology — 45 minutes.
- Oxygen Production — 1 hour.
- Radiation Protection — 2 hours.
- Advanced Water Extraction — 2 hours.
- Sustainable Mars Agriculture — 3 hours.

These are GAME VALUE proposals. Do not present them as scientific facts. Research should unlock useful capabilities and explain the science behind them.

## F. Crew assignments

Each astronaut can perform one assigned task at a time. A task may use simulation time, real time, or immediate resolution depending on its design. The task definition must explicitly declare which clock it uses.

Roles:
- Commander: planning, priorities, morale, coordination, and mission readiness.
- Engineer: construction support, repair, maintenance, panel cleaning.
- Scientist: research, ice survey, weather observation, and data interpretation.
- Medic: health checks, recovery, safety drills, and crew wellbeing.

Crew assignments must not permanently lock a player out of essential controls. The player can reassign a crew member when safe and appropriate. Avoid excessive micromanagement.

## G. Deterministic simulation API

Provide immutable snapshots and a clean API, for example:
- `SimState`
- `SimConfig`
- `PlayerInputs`
- `Engine.step(...)`
- `Engine.run(...)`
- `Policy`
- `Trace`

Use seeded randomness. Same seed and same inputs must yield the same simulation trace.

## H. Balance tests

Create reference and naive policies for every level as the campaign is implemented. Reference policies should demonstrate a reasonable strategy. Naive policies should trigger understandable failure lessons, not random punishment.

Test:
- Solar formula and source fact references.
- Battery charge/discharge.
- Resource consumption.
- Crew needs.
- Storm and radiation events.
- Site differences.
- Facility construction and upgrades.
- Research prerequisites and unlocks.
- Real-time timer persistence.
- Offline completion.
- Duplicate completion prevention.
- Clock rollback handling.
- Crew task assignment and completion.
- Deterministic retry.

## I. Documentation

Create `docs/SIM_MODEL.md` with:
- Every formula.
- Every input and its class: NASA DATA, GAME VALUE, DERIVED.
- Simplifications and assumptions.
- The two clocks and their separation.
- Timer and offline progression behaviour.
- Resource production and consumption.
- Event rules.
- Balance limitations.

## Definition of done

The simulation engine has no Flutter imports. Tests pass. `flutter analyze` is clean. The timer service survives app restarts and offline intervals without duplicate completion. Update progress and decisions. Do not start Prompt 5.
