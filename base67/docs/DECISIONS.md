# Design decisions

## Step 1 foundation

- The 15-level campaign in `assets/data/extra/campaign.json` is the campaign structure in `GAME_BRIEF.md`. The original `assets/data/levels.json` has six differently named planned levels. It remains unchanged as required; the new campaign supersedes it for campaign flow.
- `assets/data/sites.json` contains the legacy site descriptions and labels but does not encode the requested difficulty classification. `site_risk.json` is the authoritative provisional source for the requested EASY, MEDIUM, HARD, and EXTREME labels. Its descriptions and effects are game values; effects remain empty until balancing.
- The moved prologue keeps its inline landing-site cards to preserve behavior in this step. The new site-risk layer is authoritative for the campaign; connecting the prologue cards to the repository is still pending and must use the corrected GAME VALUE descriptions.
- Construction costs, research effects, resource rates, crew bonuses, and star thresholds lack approved design values. The GDD's suggested timer and research durations are now represented in extra config files as provisional GAME VALUE proposals; they are not final balances.
- Real-world timer policy uses UTC start/deadline timestamps. On rollback, elapsed time is clamped at zero and saved deadlines remain; completion is idempotent. A trustworthy monotonic clock across process/device restarts is unavailable in ordinary local app code, so this defensive policy favors no duplicate rewards or corrupted save over granting early completion.
- The app stays local-only. `provider` and `shared_preferences` are added for upcoming state and simple saves; no cloud service is used. A future save exceeding small key/value storage needs should move to a local database with an explicit migration.
- Android's main/release manifest contains no INTERNET permission. The debug manifest currently includes INTERNET for Flutter debugging; it is debug-only and does not enter the release manifest.

## Unresolved supplied-material gaps

- No repository `docs/source/` or `docs/reference/` existed. The two supplied PDFs and the supplied story text were copied into `docs/source/`; no visual-reference assets were supplied in the external pack, so `docs/reference/` is empty.
- The data pack did not contain a separate video script. `docs/source/Base 67 Game design and story.txt` is the only supplied story text and is retained as-is.
- The original starter had no deterministic RNG implementation. `lib/sim/seeded_rng.dart` now implements the configured Mulberry32 generator; the default seed remains read from `game_constants.json`. The playable simulation remains deferred.

## Prompt 1 foundation updates

- The Codex Prompt Sequence names `docs/SIM_MODEL.md` as the shared simulation document. The existing foundation note was renamed to that path without changing its content. The old filename is no longer referenced.
- `docs/GAME_BRIEF.md` is the canonical 15-level brief from Prompt 1. The previous copies of the brief and this decision log are preserved in `docs/archive/` before this update. No separate six-level brief or decisions version was present; the old six-level plan exists only in the read-only `assets/data/levels.json` data file.
- `assets/data/levels.json` remains unchanged and is treated as a migration reference only. The new campaign lives in `assets/data/extra/campaign.json`. The following crosswalk preserves old lesson and win intent while splitting broad levels into focused new levels. Legacy win thresholds are reference values, not automatically adopted as final campaign criteria.

| Legacy level | New campaign levels | Legacy lesson mapping | Legacy win-rule mapping |
| --- | --- | --- | --- |
| `L1_power` | `L01_first_light`, `L02_power_storage`, `L03_energy_manager` | `night_power_gap` supports the storage lesson in `L02`; panel generation begins in `L01`. | `survive_sols: 10` and `battery_never_below_pct: 20` are references for storage/reserve objectives, principally `L02`; retune per level before release. |
| `L2_storms` | `L04_dust_on_mars`, `L05_the_great_storm` | `storm_battery_drain` supports dust/power cause and response across both levels, with the storm debrief in `L05`. | `survive_sols: 15` and `battery_never_below_pct: 0` inform the storm scenario in `L05`; replace any zero-battery success rule with reviewed safety criteria. |
| `L3_air` | `L06_greenhouse_online`, `L07_breathing_matters` | `oxygen_shortfall` maps to oxygen balance and reserve learning in `L07`; greenhouse setup is taught in `L06`. | `survive_sols: 15` and `oxygen_never_below_kg: 10` are legacy references for `L07`, subject to science/data and balance review. |
| `L4_radiation` | `L08_radiation_alert`, `L09_shelter_protocol` | `radiation_over_limit` is introduced as monitoring in `L08` and applied to shelter response in `L09`. | `survive_sols: 20` and `dose_below_msv: 25` map to the combined monitoring/shelter objective, primarily `L09`; 25 mSv remains a GAME VALUE, not a NASA limit. |
| `L5_food_water` | `L10_finding_water`, `L11_ice_operations`, `L12_food_and_supplies` | `water_shortfall` maps to evidence, extraction, and reserve planning in `L10`–`L11`; `food_shortfall` maps to production and storage in `L12`. | `survive_sols: 25`, `water_never_below_kg: 20`, and `food_never_below_kg: 10` are reference goals split across `L11` and `L12`; retune with the new campaign economy. |
| `L6_commander` | `L13_crew_care`, `L14_mission_control`, `L15_the_final_mission` | `crew_too_cold` maps to wellbeing in `L13`; `storm_battery_drain` and `radiation_over_limit` return as integrated lessons in `L14`–`L15`. | `survive_sols: 30` and `crew_alive: 4` inform the final integrated challenge in `L15`. The updated requirement is to keep all four crew safe; crew death is never a game outcome. |

- The legacy title string is retained in original source data. `assets/data/extra/display_text.json` provides a GAME VALUE presentation replacement to `BASE 67`; repository callers must use `GameDataRepository.displayText` for source-provided text. Original NASA/source files are not edited.
- Timer and research durations now use only the updated GDD's suggested ranges/durations and remain marked `provisional` GAME VALUEs. They are pacing proposals, not validated balances or NASA facts. Original data-pack balance values remain unchanged.
- `lib/game/` contains the Home Base and Campaign Map presentation screens from Prompt 2; simulation and mission outcomes remain deferred.
- The site timeout's one-line conditional was wrapped in braces to satisfy the analyzer; its condition and action are unchanged. The first prologue title opens Data Check on long-press only when `kDebugMode` is true. Release builds have no active entry handler, and the Data Check widget also guards itself against release use. No lint ignore was needed.

## Prompt 2 visual and navigation decisions

- `docs/reference/` contains no visual files. Prompt 2 therefore uses its written Mars map direction: warm rust terrain, a deep dusk sky, a compact illustrated settlement, rounded cards, and clear campaign nodes. No external artwork or font was added.
- The UI uses bundled/platform Roboto typography and local vector drawing through Flutter painters. Text size settings use the four specified factors; reduced-motion mode disables the CrewBean breathing loop and removes route fades.
- Home Base and Campaign Map read the existing campaign save. Resource quantities, capacities, costs, and effects remain unset when no saved or approved value exists; this step does not add balance figures or simulation behavior.
- The prologue story and decision flow remain unchanged. Its scene text area can scroll on small screens at larger text sizes, and its app route provides a Home Base handoff after the final scene.
- Routes for later mission systems are present as presentation shells. This Prompt 2 work does not implement the simulation, mission outcomes, construction actions, or research effects.
