# BASE 67 simulation and progression model

## Consolidation checkpoint (2026-11-12)

The complete M2-M10 owner assignment, exact M2 excerpt, M10 analyzer cleanup and final acceptance requirements now live in docs/BASE_67_Codex_Prompt_Sequence.txt. Existing historical text/order is preserved. This consolidation adds no simulation/gameplay/save/balance change. M1 is validated; M2-M9 implemented for review; M10 partial pending Android/final acceptance. Analyzer passed with zero issues in the prior cleanup session; full suite and successful 52.2 MB release APK are owner-reported. These commands were not rerun here. Starting damage is a separate design decision, not a new initial condition or recovery entitlement.

## M2-M10 integration boundary (2026-11-12)

No simulation formula, cost, capacity, timer, research bonus, recovery/refund rule, event catalogue, save schema or migration changed. New environment/building/menu imagery is original presentation code; fixed world coordinates, hulls, movement/navigation and simulation/progression ownership remain intact. Picture caches and dust animation have no game-state effect.

SettlementStatusPanel receives the canonical world plus saved generation, never an unsaved forecast. Home reads night from the source-configured sol/daylight lengths and current environment, and renders actual active-storm/dust state. SavedJobsPanel reads reconciled remaining/duration; an original wall deadline after clock correction is history, not a replacement countdown. Pause gates simulation UI actions but leaves real-time job policy unchanged.

Mission completion/retry/resupply remains the existing engine/controller path. Campaign and debrief show retained receipts, not new awards. Four site reference strategies now test real construction, costs, crew, solar preparation, Level 1-2 outcomes and a mid-L2 restart. The 85% battery buffer in the test is a chosen strategy, not a new objective or GAME VALUE. A restart legitimately adds one ordered observation token; all other saved fields must remain equal. These are deterministic automated examples, not proof for every state or a physical/scientific balance validation.

The owner chose to design starting damage separately. No initial occurrence, repair cost, spare grant or arbitrary entitlement is introduced here. Level 1 retains its construction-first start until that separate design is approved. All pre-existing GAME VALUE/provisional markings and scientific assumptions below remain.

## Integrated power milestone M1 (2026-11-11; original handoff, subsequently owner-validated)

Owner-approved sequencing change, GAME VALUE: introduce the existing heater switch in Level 2 as a local habitat control, requiring the installed habitat. Level 1 still has no load switching. Level 3 onward retains the existing Power Control Station prerequisite; greenhouse/miner loads keep their later unlocks. Controller and UI share MissionRuntime.canControlLoad. Costs, timers, essential-load priority, safe temperatures, reserve thresholds and all lib/sim formulas are unchanged. This is a control-access change, not a new source of power or a relaxed safety criterion.

PowerMissionReport is a detached read model. Current objective rows use actual working units, current battery quantity/capacity, saved mission evidence and configured duration/reserve. Its forecast uses the existing begin/step path on the same canonical snapshot and current environment/charge/disabled loads. Proposed output is discarded; no saved time, reserve, task, job clock, receipt, completion, reward or observation flag changes merely by rendering the panel. The forecast differs from the existing fully charged clear-sky powerPlan counterfactual and is labelled unsaved. It covers one normal step only, not guaranteed full-cycle survival. Preparation observations remain real spending actions through the existing controller, not forecasts.

All displayed quantities retain repository-derived inputs and data-class chips. No NASA value, balance amount, timer, capacity or independent energy formula is added. The original handoff left these checks unexecuted; the owner subsequently reported M1 validation passed. Current focused tests verify one real unassisted L1/L2 reference strategy at each site, not every strategy/history or final campaign balance.

## Combined campaign adapter and crew operations (2026-11-11; unvalidated)

The owner authorizes combined Prompts 5+6. The existing pure engine is unchanged. MissionRuntime projects the same canonical progression resources/facilities/research into each engine step; CrewOperations coordinates simulation tasks through the existing external assignment/target reservations. The same controller serialization and verified blob write commit outcomes, health/task metadata, event checkpoints, resource changes, completion/unlock and existing resupply receipts. Offline reconciliation never calls these simulation operations.

Late mission definitions and event profiles live in extra/campaign_operations.json; early definitions remain in tutorial.json. All added values are **GAME VALUE, provisional, unverified as final balance**. L8–15 durations are 3/6/3/3/4/4/20/36 hours. Water/food floors are 20% of configured initial stocks; finale also checks the existing oxygen floor. Actual engine safety pauses and unworkable crew cause an explanatory debrief, never death. Powered extraction/food production, surveys, care/rest/rally, forecast/readiness and repaired final damage provide observable goal evidence.

Crew policy is configured in extra/crew_assignments.json.mission_operations. Indicators are bounded 0–100; initial health/morale/fatigue = 100/80/0; safe condition = health >=25, morale >=20, fatigue <=90. Per simulation hour: work fatigue +4; rest fatigue -6 and health +2; cold health -5; shortage health -8. Specialist tasks take 1 hour versus 2 for backup, with 2-hour rest and 1-hour care/rally. Medic care adds health/morale 12/6 and reduces fatigue 10; Commander rally adds morale 12; backup effects are halved. These are game support rules, not human physiology or NASA thresholds. No voting/morale penalties, offline decay or role-based production bonus.

Tasks share canonical crew ownership with real jobs. Cleaning reserves the panels and cannot finish just because a nominal duration elapsed: the existing engine must emit panels_cleaned. Target/crew conflicts block activation; cancellation frees only the owned simulation reservation and grants no refund. Existing real-job payment/refund/clock/Engineer repair rules remain unchanged. Checklist jobs retain the normal service lane and duration when no specialist is assigned.

Event schedules use an explicitly seeded generator derived from campaign seed and level index. Configured events are announced before activation; any jitter is <=1 hour and negative events have >=4 hours after the previous event ends. Existing engine effects and profile durations apply. Stable script IDs survive retries and revisits. The final panel strike is admitted only through the validated L15 meteor occurrence and actual engine damage increment, then existing occurrence-bound repair accounting closes it exactly once. No new unseeded random events or arbitrary damage claims.

Explicit emergency support, after confirmation, tops survival stocks to 40% of initial values and batteries to 80% of installed capacity, with capacity caps; struggling crew receive health/morale floors 40 and fatigue ceiling 50. Nothing is delivered when already above the floors. No materials, parts, installations or job/mission completion. Support metadata records count/last receipt and outcomes record assisted play. These are supply/charging aid, not local production or construction recovery credits.

Radiation history has two labelled values: the engine's current GAME VALUE assessment-window dose and lifetime accumulated dose. Both increase only during simulation. At the configured assessment limit, explicit support may restart the game assessment counter while retaining lifetime exposure unchanged. It is not a claim that medical support removes radiation dose. Retry/revisit otherwise preserves environment, exposure, resources and weather. NASA baseline/evidence cards remain repository fact lookups; site ice tiers and model response are game choices.

All 15 levels and certificate gating are implemented for owner validation. No tests/analyzer/build/data checks/Git commands were run in this combined pass. Reference strategy, unassisted solvability across all sites, pacing, Android layouts and learning outcomes are not verified. No unconditional arbitrary-history no-soft-lock guarantee is claimed; assistance and existing restricted construction/repair recovery provide explicit routes to continue.

## Prompt 5 mission adapter (2026-11-11; unvalidated implementation)

`lib/missions/mission_runtime.dart` composes the existing pure engine; `lib/sim` is unchanged. It accepts immutable progression snapshots and repository-loaded configuration. Each action projects installed facilities through FacilityMapping, reads actual balances and writes resulting quantities through CampaignController and the verified store. Packed equipment never produces output or capacity. No IO, Flutter, wall-clock reads or random generator is added to the mission runtime.

The optional schema-3 mission checkpoint stores environment (absolute hours, RNG, temperature, dust, cleaning progress, radiation and event/script checkpoints), lesson/phase state, load switches and bounded historical measurements. It never owns spendable resources, facilities, research, crew or spare parts. Existing saves without a checkpoint retain all balances and initialize only first-use environment. Real-time reconciliation never runs the engine. Entry/retry cannot reset or refill the base.

All new thresholds are **GAME VALUE, provisional, unverified as final balance**, stored in extra/tutorial.json: initial time = half configured daylight; L1/3/4/6/7 durations = 1/3/2/2/6 simulation hours; L2 = source-derived sol; L5 = existing profile duration; L7 floor = 20% of configured initial oxygen. L2 uses the existing battery reserve and requires charging/discharging. Each trace boundary checks reserves; existing engine safety pauses fail observations. Floating-point termination tolerance is not balance. No NASA safety threshold is implied.

**GAME VALUE, provisional:** L4 settling dust uses the existing dust-gain rate for two hours. L5 warns before the existing stylized scripted storm and uses the engine cleaning action with a free Engineer. No random events/damage, new repair path or repair entitlement authority. Retry retains actual weather: active storms are not restarted, while an ended storm can be retried with the same profile/seed.

**GAME VALUE, provisional:** research presentation begins at L6; individual recipe prerequisites/effects and normal timers remain unchanged. While jobs run, children can review crew/lessons, compare hypothetical power plans or advance actual preparation. Preparation consumes real supplies; waiting does not. The hypothetical planner runs Engine for one clear-sky sol with proposed source-limited units and full proposed charge; it returns measurements only, never a spendable snapshot or storm guarantee.

Three hints, learned-interaction suppression, narrative crew advice and 64 historical samples are **GAME VALUE, provisional**. Debrief compares historical start/current quantities; retries retain the same seed and never reverse costs, cargo, completions, resupply or consumption. No unapproved survival refill. Full campaign solvability, pacing, layout and all tests remain for owner validation.

Mission commands reconcile job clocks through the existing captured-token/UTC path before saving, preventing frequent mission writes from postponing job completion. The already-configured required facility counts gate launch. Failure debrief can compare the actual last step with the same step starting from hypothetically charged existing batteries; the latter is a DERIVED estimate under a labelled GAME VALUE assumption, never a refill or stored alternate ownership state.

## Schema-3 app persistence boundary (2026-11-10; implementation pending owner validation)

The final owner authorization enables Prompt 4B-2. The service rules below remain unchanged. CampaignSave stores the complete progression aggregate once; presentation inventory/resources/tiers/jobs are derived views. CampaignMigration validates legacy input and ProgressionCodec validates restored/outgoing allocations, payments, receipts, crew/lane ownership, installed facilities and time checkpoints. Only absent approved initial reserve fields are initialized during legacy migration/setup; existing zero balances survive. Packed spares transfer through the existing explicit unpacking operation.

CampaignController supplies ordered UTC/token observations captured before queue delivery, commits one entire primary blob through the existing store, and publishes only after read-back verification. Preserve the prior verified blob as backup before replacement. Startup/resume and a nearest-job wake-up call the existing reconciliation function; no simulation step, survival consumption or automatic queued activation occurs. ProgressionClock.restore restores history/checkpoints without observing time or changing the approved rollback formula.

Legacy migration errors preserve the original bytes and block loading; no blank-save fallback. A corrupt/missing primary can recover a validated backup with a recovery notice. Ambiguous legacy jobs are archived terminal with crew released, IDs retained, no inferred effect/refund and a diagnostic log. Future unsupported schemas and unrecognized aggregate fields/recipes stop safely. The existing shared_preferences backend is retained; this is not an ACID or power-loss test claim. No validation commands were run in this implementation pass. The owner must validate before Prompt 4 can be marked verified complete.

## Approved audit corrections (2026-11-10; supersede affected service details below)

All gameplay policies remain GAME VALUE, provisional; no new balance values or simulation formulas are added. These corrections apply to the unwired progression layer only, not CampaignSave schema 2.

- Damage observation: admit a known catalogue occurrence only with the correct level and a count transition equal to its configured units, within installed capacity and consistent with existing allocations. Record the occurrence before confirmation. No aggregate positive count alone can identify a historical occurrence. Unknown existing damage receives a non-authoritative allocation when ordinarily repaired; it cannot acquire recovery authority later.
- Repair job snapshots repairDamageId independently of payment identity. Resolve one unit from that allocation on completion, including ordinary-funded completion. Confirmation after activation cannot change the bound identity. No second assistance payment for an active bound allocation. Final resolution removes unused restricted credit and retains historical receipts/tombstone. Other damage occurrences retain their own counts/credits. Cancellation leaves outstanding damage in the same allocation and returns actual assistance at 100%, ordinary payments at configured 50% with indivisible rounding down.
- recordFieldRepair is a pure report of an already-executed/paid external outcome: validate named open allocation, count decrement and absence of a reservation, then resolve that allocation. It is not a gameplay action or a second resource charge. Future integration must atomically coordinate the external payment/outcome. No field-repair or event simulation code changes here. Damage replaced outside this boundary is inconsistent, logged, and cannot silently complete a reserved repair.
- Construction: installedCount excludes pending units. First construction transitions lifecycle-only state to underConstruction, then operating/damaged on completion; first cancellation restores notBuilt. Preserve deliberate off/outOfResources states. Expansion never replaces the operating state of existing units and preserves damage/tier. Installed lifecycle-only/unknown states are invalid, not silently normalized. Pending units provide no output or capacity. Cargo/cost/refund rules are unchanged.
- Spares: resources['spare_part'] is the only available repair stock. Explicit unpacking removes packed spares and transfers them atomically into an empty/zero available balance. Repetition transfers nothing. Mixed positive representations are rejected as ambiguous; no inferred grants or automatic summation. Spares are not installation kits and never gain full ordinary cancellation refunds by being classified as cargo.
- Clock Option A: capture an immutable (UTC, token) pair before delivery. Token order is capture order across the aggregate, independent of UTC order. Reject duplicate/older tokens before any timed-request state mutation, including enqueue and pending delivery. For accepted observations only, the previously approved formula remains:

      elapsed = max(0, suppliedUTC - observedUTC)
      nextRemaining = max(0, previousRemaining - elapsed)
      nextObservedUTC = suppliedUTC  # also on an accepted rollback

  Original start/deadline history, terminal completions and receipts remain unchanged. New jobs use accepted current UTC, never a global historical UTC floor. Tokens must not be assigned to stale timestamps at delivery time. Genuine accepted forward jumps can still complete early. The service reads no clock; no coordinator or persistence is introduced. Future integration must preserve token ordering and damage ownership; raw snapshot replacement is not authoritative observation.

Local validation is recorded in PROGRESS and the live session log. Independent read-only review is required; no acceptance, disk durability or Prompt 4 completion claim.

The foundation introduced a pure Dart simulation boundary. Prompt 4A now implements that library independently from Flutter widgets; it is not wired into the playable app.

- The default deterministic random seed is read from `assets/data/game_constants.json` (`rng.default_seed`); its specified algorithm is Mulberry32. `SeededRng` implements the specified sequence generator.
- NASA values remain in `nasa_data.json`, with source links resolved through `sources.json`. Simulation code must obtain values using fact IDs.
- Existing assumptions and formulas remain in the original game pack. New balance choices belong in the versioned GAME VALUE files under `assets/data/extra/`.
- The Martian simulation clock and real-world progression timers are separate. Timer deadlines are stored as UTC timestamps and completion is idempotent. Clock corrections cannot reverse completion or increase remaining work; the current per-job policy is specified below.

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


## Historical 4B-1 real-time progression (unwired)

The service-policy section below supersedes this historical salvage and clock-floor behavior. Original numerical costs/resupply remain unchanged.

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


## Current service-policy follow-up (unwired, 2026-11-10)

Every new gameplay rule here is **GAME VALUE, provisional**. No NASA/scientific accuracy or final campaign balance is asserted. Original simulation formulas and lib/sim are unchanged.

### Authority and restricted recovery

- Mandatory construction identity = `construction:<known facility>:<configured required count>`. Required counts are validated against installed limits. Eligibility requires an unmet count, unlock level, building/research prerequisites and a known recipe. Optional additional units do not qualify under the current required count of one.
- Essential damage identity = `<known level>:<source event>:<positive sequence>`, derived from the repository configuration catalogue, not supplied as a new claim by UI code. Validate its target and maximum units against the original event definition. Confirm an occurrence only against observed, unclaimed damage not exceeding installed count. Retain the confirmation receipt after repair. Verify receipt kind/target/level/amount whenever selecting repair assistance. The current production occurrence catalogue is empty: no mission events are invented by this follow-up. Tests supply clearly synthetic catalogues. Future mission/controller code must provide trusted observations; no cryptographic save authentication is claimed.
- Restricted credit per target/resource is separate from ordinary balances. `shortfall = max(0, recipeCost - ordinaryAvailable - existingCredit)`, after pending ordinary deliveries. Add only this shortfall to the same entitlement; available credit cannot exceed its recipe cost. New required objectives can recover in the same level. Completed objectives and resolved occurrences cannot recover. Unrelated research is not a recovery gate. Existing active funded work cannot claim a second payment.
- On activation use matching restricted credit first, then ordinary funds. Snapshot the two payment sources independently. On cancellation, `ordinaryRefund = ordinaryPaid * refundFraction` (configured 0.5), floor materials/spares; `restrictedRestoration = assistancePaid` (100%). Do not refund assistance as ordinary inventory. Queued/blocked refunds are zero; due completion precedes cancellation. No elapsed work carries into a retry. Full-storage ordinary material refunds remain pending.

### Lanes, cargo and installed facilities

One engineering lane serves construction/upgrades/timed major repairs; one research lane serves research. Assigned or unattended jobs occupy their lane. Crew and target reservations are checked again on activation. Queued work reserves nothing, and offline time does not activate it. A pure external reservation input permits later cross-clock crew/facility coordination without running simulation code here.

An assigned Engineer's eligible timed repair uses `ceil(baseDurationMicroseconds * configuredMultiplier)` with multiplier 0.5; material/spare cost is unchanged. Snapshot the effective duration, never recompute it for active work.

Construction queue: no stock/cost change. Activation: reserve one matching packed item if available and deduct the existing material recipe once. Completion: installedCount += 1, reserved item consumed once. Cancellation: return reserved uninstalled items fully; material refunds follow their payment source. No packed item is a second purchase gate; the same existing material recipe constructs a unit when stock is absent. This is the approved simplified GAME VALUE accounting, not real manufacturing economics.

Equipment-backed limits come from the original equipment max_units through supplied configuration. Facilities without a mapped equipment limit retain the prior one-installation limit. Spare parts are consumable repair stock, not a maintenance-bay installation kit. Store installed counts, upgrade tiers, damaged counts and operating states separately. Simulation projection uses `tier = 1 + progressionUpgradeTier`, never adds packed stock, never initializes reserves, and leaves existing units operating while another is built. The original habitat is not replaced; later expansion remains undefined until its own approved plan.

### Per-job time checkpoints

Inputs are caller UTC and immutable job state. At activation store original startUTC, originalDeadlineUTC = startUTC + effectiveDuration, remaining = effectiveDuration, observedUTC = startUTC.

    elapsed = max(0, suppliedUTC - observedUTC)
    nextRemaining = max(0, previousRemaining - elapsed)
    nextObservedUTC = suppliedUTC  # also on rollback

Complete only once when remaining reaches zero, committing the effect/status/completion ID/receipt in one in-memory transition. Original deadline history remains unchanged, including when corrected-clock completion happens before its original wall deadline. Record actual observation/completion time and rollback diagnostics separately. Completed/cancelled jobs cannot reverse. Process simultaneous due jobs by original deadline then stable ID. New jobs never inherit an aggregate high-water timestamp. Countdown reads only a reconciled snapshot.

A future jump may complete timers early (accepted limitation); repeated forward/back changes cannot duplicate effects/refunds. No trustworthy offline elapsed time can be inferred during a negative clock jump: grant zero for that interval, move the checkpoint, then resume progress with later positive intervals. Persist all checkpoints/receipts together in 4B-2; this work proves pure-state continuation only. Real-time progression never advances sols or consumes survival reserves.

### Limits

Restricted assistance is not permission for arbitrary caller objectives, unidentified damage, optional upgrades or unapproved extra units. The production damage catalogue is intentionally empty pending mission definitions. No unconditional claim covers corrupt saves or every future scenario. Existing 80/200/+10 construction resupply, all construction/repair costs, original production rates, stocks/capacities and base timer ranges are unchanged. The Engineer multiplier is owner-approved GAME VALUE, provisional.
