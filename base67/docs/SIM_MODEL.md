# BASE 67 simulation model — Prompt 4A

The foundation introduced a pure Dart simulation boundary. Prompt 4A now implements that library independently from Flutter widgets; it is not wired into the playable app.

- The default deterministic random seed is read from `assets/data/game_constants.json` (`rng.default_seed`); its specified algorithm is Mulberry32. `SeededRng` implements the specified sequence generator.
- NASA values remain in `nasa_data.json`, with source links resolved through `sources.json`. Simulation code must obtain values using fact IDs.
- Existing assumptions and formulas remain in the original game pack. New balance choices belong in the versioned GAME VALUE files under `assets/data/extra/`.
- The Martian simulation clock and real-world progression timers are separate. Timer deadlines are stored as UTC timestamps and completion is idempotent. Backward device-clock changes do not cause early completion.

Detailed 4A assumptions and formulas follow. Mission balance remains unverified.

## 4A scope and provenance

4A is the pure Dart engine, repository-to-config adapter and simulation tests. It is not wired to the app, prologue, UI or campaign save. Owner commit/push gates 4B's progression services, costs, timers, cancellation/refunds, completion bookkeeping, app wiring and persistence.

Every new gameplay input/response rule below is **GAME VALUE, provisional**. Results combining facts and game assumptions are **DERIVED, unverified as physical models or final balance**. Existing NASA facts are read-only; the human source audit remains pending. No NASA number is added to Dart.

SimConfigLoader resolves repository fact IDs, units and config into immutable data. SimValue retains data class, fact IDs and provisional status. Resource snapshots record quantities, capacities, rates and source-labelled changes. New simulation config is limited to extra/resource_economy.json and extra/sim_params.json.

## API, time and determinism

Engine.step accepts immutable state, explicit player inputs and positive simulation hours up to the configured tick; excessive durations clamp with notices. Engine.run repeats ticks. The engine defines Policy and only one trivial BaselinePolicy; no level-specific policies.

Callers supply installed equipment, facility tiers and already-active research IDs. Plain-map snapshots support deterministic in-memory continuation; this is not app persistence. There is no purchase or research completion in 4A.

There are no Flutter, UI, audio, filesystem or wall-clock reads in lib/sim. Tick/daylight hours are original GAME VALUEs; sol length is read by fact ID sol_hours. Real-time jobs and offline elapsed time cannot advance this clock.

Mulberry32 uses the source default seed and carries RNG state in snapshots. Sixteen-bit limbs keep 32-bit products exact on native/browser backends. Masks, integer widths and standard unit conversions are technical arithmetic, not balance choices.

**GAME VALUE, provisional event schedule:** caller-enabled random IDs are sorted and sampled once per sol start, including sol zero. Scripts carry explicit simulation hours and unique occurrence IDs; fired script IDs prevent replay of those simulation events, not progression completion.

Steps split at sol boundaries, scheduled events and known event expiry boundaries. A technical 1e-10-hour tolerance prevents floating-point boundary stalls; it is not gameplay pacing.

## Input provenance

| Input | Source | Class / status |
|---|---|---|
| Sol length and irradiance | sol_hours, solar_irradiance | NASA DATA; human audit pending |
| Daily crew needs | crew_oxygen, crew_water, crew_food_packaged | NASA DATA; converted through hours |
| Background dose | rad_gale_surface | NASA DATA; used at all sites per legacy GAME VALUE assumption |
| Ambient | temp_mean | NASA DATA global mean; constant local use is GAME VALUE, provisional |
| Site latitude | each site's nasa_fact_ids.lat | NASA DATA; cosine is DERIVED |
| Equipment outputs, loads, control ranges, thresholds and actions | original equipment/loads/game_constants | Legacy GAME VALUE |
| Weather/chances/effects and ice tiers | original events/sites | GAME VALUE, not NASA forecasts |
| New stocks/capacities and bonuses | two extra simulation configs | GAME VALUE, provisional |

Earth-day needs and radiation divide by the standard 24 hours per day; per-sol equipment production divides by the source sol length. A sol is not treated as an Earth day.

## New inputs — all GAME VALUE, provisional

| Resource | Start | Base capacity | Reason |
|---|---:|---:|---|
| Oxygen | 30 kg | 60 kg | Initial planning buffer, expansion room |
| Water | 100 kg | 200 kg | Drinking-water buffer; excludes hygiene |
| Food | 100 kg | 200 kg | Packaged-food buffer |

Existing life_support_module adds 30 kg oxygen storage, ice_miner_water_storage adds 100 kg water storage, and food_storage adds 100 kg food storage per built undamaged unit. These additions are GAME VALUE, provisional. Passive storage remains when switched off; unbuilt/under-construction facilities grant nothing. Capacity expansions grant no stock.

Water conversion is **1 kg/L, GAME VALUE, provisional, unverified**, approved by the owner. The original battery GAME VALUE remains 20 kWh/unit; installed counts and spare parts are caller inputs, not invented starting cargo.

## Additive modifiers

**GAME VALUE, provisional:** effective stat = base × max(0, 1 + upgrade bonus + research bonus). Upgrade bonus is +25% once for an applicable built facility with an upgraded tier. Research IDs are a set, sorted before summation; acquisition order does not matter.

| Research | Stat | GAME VALUE, provisional bonus |
|---|---|---:|
| Solar Energy Fundamentals | solar output | +10% |
| Advanced Batteries | battery capacity | +25% |
| Dust Protection | dust accumulation | -25% |
| Oxygen Production | greenhouse oxygen | +25% |
| Radiation Protection | received dose after hardware protection | -10% |
| Advanced Water Extraction | miner water | +25% |
| Sustainable Agriculture | greenhouse food | +25% |

Upgradeable stats: solar output, battery capacity, greenhouse food/oxygen, life-support oxygen capacity, miner water output/storage, food capacity. Both battery bonuses produce base × 1.50, not base × 1.25 × 1.25. No research prerequisites or progression fields are written.

## Power and resource formulas

Legacy documented solar formulas produce DERIVED outputs:

    peak_kw = irradiance_W_m2 / 1000 × panel_area_m2 × panel_efficiency
    site_factor = abs(cos(latitude_degrees × pi / 180))
    daylight = max(0, sin(pi × hour_of_sol / daylight_hours)) during daylight, otherwise 0
    generation_kw = working_panels × peak_kw × daylight × site_factor
                    × exp(-tau) × (1 - panel_dust_fraction) × solar_modifier

The loader recomputes peak output and cosine factors from source facts rather than copying rounded legacy values. Small numerical differences from the original rounded figures are deliberate and DERIVED.

**GAME VALUE, provisional integration:** solar samples the midpoint of each interval. Available energy = generation × hours plus usable battery energy. Load priority is habitat life support, heater, greenhouse, miner, cleaning, repair. Optional loads can be shed; habitat life support cannot be shed through inputs.

Delivered fraction = delivered/requested energy with zero-demand handling. Unbuilt/off/disabled/under-construction/out-of-resources facilities do not produce. Partly damaged facilities use undamaged units; production scales with delivered power.

Battery capacity = undamaged installed units × source unit capacity × modifier. Disabled batteries retain charge but cannot charge/discharge. Physical capacity loss clamps charge and traces it; surplus energy spills. No efficiency losses or power-rate limits are modeled; these simplifications are GAME VALUE, provisional.

    crew_need_kg_hour = crew × source_kg_person_day / 24
    water_need_kg_hour = crew × source_L_person_day × water_kg_L / 24
    greenhouse_kg_hour = working_units × source_output_kg_sol / sol_hours
                         × delivered_light_fraction × output_modifier
    miner_kg_hour = working_units × source_ice_tier_output_kg_sol / sol_hours
                    × delivered_miner_fraction × water_modifier
    next_quantity = clamp(previous + (production - consumption) × hours, 0, capacity)

NASA rates plus GAME VALUE production give DERIVED balances. Changes include event grants, production, consumption, lost capacity and overflow. No recycling or hygiene usage is invented.

**GAME VALUE, provisional, unverified thermal model:**

    target = global_mean_ambient + (heater_set_point - global_mean_ambient) × delivered_heater_fraction
    next_temperature = target + (previous - target) × exp(-hours / legacy_cold_time_constant)

Use the source heater range; reuse the source cold time constant for warming and cooling. This is not detailed thermal physics.

## Events, actions and radiation

The original storm keyframes interpolate linearly and expire to clear sky after the last frame. Dust gain = legacy hourly fraction × hours × dust modifier, bounded to [0,1]. These compressed weather rules are GAME VALUE, provisional.

Cleaning requires power and unsheltered available crew. After the source simulation-hour duration, remaining dust multiplies by (1 - source restoration fraction); partial progress is snapshot state. The immediate legacy repair action consumes one existing spare part and restores one damaged unit when crew/power allow. Timed repair jobs are deferred to 4B.

Meteor damage counts, ice-tier requirements/water grants, clear-day tau/duration and SEP spikes use original event data. No new event probabilities are introduced.

    shield_factor = clamp(1 - working_shield_units × source_reduction_fraction, 0, 1)
    dose_increment = (source_background_per_hour × hours + SEP_spike × shelter_factor)
                     × shield_factor × research_dose_modifier

Shelter applies the original reduction to SEP spikes only. Hardware protection precedes the stat's research modifier. These protections are GAME VALUE, provisional; accumulated dose is DERIVED. The original dose game limit is never a NASA safety limit.

## Safety and balance limits

Runtime guards clamp non-finite state, negative quantities/counts and dust bounds with notices. Shortages, zero capacity and inactive facilities do not divide by zero; non-finite arithmetic uses finite fallbacks. Invalid configuration fails before simulation.

**GAME VALUE, provisional safety rule:** pause on essential power shortage, empty essential reserve, unsafe cold or the source dose game limit. Retain crew count; there is no death outcome. Resume is explicit. No offline time is inferred.

No-production reserve estimates at four crew are **DERIVED, unverified**:

- Oxygen: 30 / (4 × 0.89 × 24.6597/24) = 8.20 sols; crew_oxygen and sol_hours.
- Water: 100 / (4 × 2.5 × 1 × 24.6597/24) = 9.73 sols; crew_water, sol_hours and provisional water conversion.
- Food: 100 / (4 × 2.39 × 24.6597/24) = 10.18 sols; crew_food_packaged and sol_hours.

These are continuous depletion estimates, not survival guarantees. None is below five sols; other systems can pause earlier. Campaign balance, physical accuracy, NASA source verification and student testing remain unverified.

At the 4A boundary material sourcing, construction economy, timer selection and refunds were deferred. The approved 4B-1 rules below now resolve deterministic resupply; costs remain limited to existing facility IDs.


## 4B-1 real-time progression (unwired)

All new economy, prerequisite, timing, role and recovery rules here are **GAME VALUE, provisional**, not NASA facts or verified engineering/campaign balance. Pure lib/sim rules are unchanged. The service accepts immutable configuration/state and caller UTC; it reads no device clock, disk, Flutter, UI or audio. Repository document adaptation and persistent schema migration are 4B-2 work.

### Inputs and effects

Five extra documents define recipes: buildings, research, timer_rules, crew_assignments, progression_rules. Required baseline construction costs total 62 material units: solar 5, batteries 4, power control 4, maintenance 4, greenhouse 8, life support 6, shelter 7, miner/storage 6, food storage 4, habitat 8, mission control 6. All 11 are provisionally required from their existing introduction level; existing owned facilities need no repurchase. Upgrades for six existing 4A-supported facilities cost twice base, max one tier. Timed repair costs 2 materials + 1 spare, restoring one damaged unit. Research has zero cost, follows the prerequisite graph in research.json, and activates the existing additive-bonus ID. No output/rate/bonus is recomputed by progression.

Timer duration selects the configured lower bound, stored as duration_seconds; fixed research suggestions are unchanged. Previously missing support timers use 300-900 seconds, initially 300. Jobs snapshot recipe, cost and effect through their immutable recipe plus paid-resource record. Construction increments installed count once, upgrade sets its separate tier, repair decreases damaged count by one bounded at zero, and research inserts its ID in a set. Only existing facilities have recipes; rover remains a reference timer only.

### State transitions and clocks

- Enqueue: store unique job/recipe/optional crew ID, without cost or crew lock. Explicit activation rechecks introduction level, building/research prerequisites, role, crew/target exclusivity, ownership/tier/damage and funds; unmet requirements give a blocked reason without deductions.
- Activation: resources' = resources - snapshotted cost; create start receipt and UTC start/end. One astronaut ID has one active job; assignment is derived from active jobs and disappears on cancellation/completion.
- Effective UTC = max(caller UTC, lastObservedUtc); endUTC = effectiveStartUTC + configuredDuration. Remaining = max(0, endUTC - effectiveUTC). Saved deadlines are never recalculated on rollback. Device forward changes can finish work early (accepted limitation).
- Reconcile active jobs in deadline/ID order. The existing TimerCompletion guard requires active, due and absent completion ID. Apply effect + completed ID + job status + receipt as one aggregate transition. Queued work never starts retroactively. No simulation time advances and no oxygen/water/food is consumed offline.
- Cancel reconciles due work first. If still active, refund = paidCost * configuredFraction (0.5), floored for materials/spares; divisible resources keep their fractional amount. Lost time never carries into retries. Queued/blocked refund zero; completed/cancelled work cannot refund again. Material overflow is pending, not discarded. Restricted salvage refunds remain restricted.

These are in-memory transitions only; receipts, last observed UTC, payments and pending balances must all be persisted together in 4B-2. Replacement-service tests prove pure continuation, not app restart/disk durability. No 4B-1 CampaignSave schema or storage changes.

### Resupply, capacity and salvage

Resupply = 80 initial + 10 * number of first completions among levels 1-14. Start/per-mission receipts and one catch-up receipt make grants deterministic and nonrepeatable. Caller-confirmed campaign results are inputs; no mission rules are implemented. Delivery = min(pending, max(0, 200 - currentMaterials)); undelivered balance stays pending. Tests cover full storage, spending/refund delivery, catch-up and replay.

With no active job, find the cheapest eligible required unbuilt facility with built prerequisites; tie-break by ID. Shortfall = max(0, cost - currentMaterials). A salvage grant is min(shortfall, cap 8), once per current-level receipt. Earmark it for REQUIRED construction only; optional upgrades/research cannot consume the credit. Existing credits count toward material availability so moving levels without spending cannot create another grant. Required construction consumes restricted funds first, with deterministic credit-ID order. This recovery applies neither to optional work nor to repair parts or damaged-but-already-built facilities.

Affordability evidence: 80 - 62 = 18 without any mission rewards; 80 + 14*10 - 62 = 158 after baseline construction and all eligible rewards. Every configured baseline facility can be afforded before its level reward. This checks the current config, not future mission success, optional upgrades or arbitrary losses.

Bounded recovery limitations retained as tests: 26 solar cancellations yield 2 materials; salvage +3 restores affordability once. Cancelling a fully salvaged solar build leaves 2 and exhausts that level receipt. Several missing facilities with zero funds can require more than one recovery in one level, which is not allowed. Missing repair spares cannot be salvaged. Further owner policy is needed for an unconditional no-soft-lock guarantee; no unauthorized recovery is implemented.
