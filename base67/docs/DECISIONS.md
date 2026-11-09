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

- The supplied PDFs and story text were copied into `docs/source/`. The five visual references were supplied later in `docs/reference/` and reviewed during the Prompt 2 visual reference pass.
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

- The initial Prompt 2 implementation used its written visual direction because reference images were not yet present. Five style references were later added to `docs/reference/` and reviewed in the visual polish pass below. No external artwork or font was added.
- The UI uses bundled/platform Roboto typography and local vector drawing through Flutter painters. Text size settings use the four specified factors; reduced-motion mode disables the CrewBean breathing loop and removes route fades.
- Home Base and Campaign Map read the existing campaign save. Resource quantities, capacities, costs, and effects remain unset when no saved or approved value exists; this step does not add balance figures or simulation behavior.
- The prologue story and decision flow remain unchanged. Its scene text area can scroll on small screens at larger text sizes, and its app route provides a Home Base handoff after the final scene.
- Routes for later mission systems are present as presentation shells. This Prompt 2 work does not implement the simulation, mission outcomes, construction actions, or research effects.

## Prompt 2 visual polish pass

- References `dribbble_01.png.png` through `dribbble_05.png.png` were reviewed as style guidance only. Their angular navy frames, cream panels, orange highlights, and compact industrial control styling informed this pass; their artwork, icons, and characters were not copied. The owner reviewed and committed the pass as `43e15ac`; a separate browser screenshot comparison was not performed.
- Home Base and Campaign Map use angular navy-outlined panels, cream surfaces, bevels, and stronger shadows. The original vector Mars map now includes a subtle cartographic grid and corner markers.
- Campaign chapter headers use rust number plates and dark panels; the existing winding 15-node route uses a layered track and outlined circular nodes. The brief's chapter grouping and palette remain authoritative.
- Home Base navigation buttons use beveled high-contrast surfaces and rust icon accents. This pass changed presentation only; campaign data, original data-pack files, save schema, balance values, and simulation logic were not changed.
- `flutter analyze` found no issues and all 17 tests passed after the visual changes. The live browser-control host was unavailable, so a separate screenshot comparison of rendered screens remains for owner review.

## Prompt 3 — prologue and setup

- The Prompt 3 file names `docs/source/BASE_67.pdf`, which is not present. `docs/source/BASE 67.pdf` is present but is a different, earlier video script. The eight-scene source used for this work is `docs/source/BASE_67_Prologue_Preview.pdf`, because it contains the complete eight-scene prologue and the setup dialogue. The prompt file was left unchanged.
- Age is collected as a positive whole number using one or two digits. No age range is stated in the source, so no age range is enforced. This technical field limit is provisional pending owner review.
- Prologue setup now uses the existing `CampaignSave` with schema version 2. It stores crew names, ages, suit/visor/face appearance indices, selected site, starting cargo and inventory, initial habitat and landing craft, resource stores and capacities, research, jobs, campaign progress, settings, seed, and event history. Resource capacities remain empty until approved values exist.
- The Level 1 cargo budget and permitted equipment are read from the original `levels.json` and `equipment.json`. Those source files remain read-only. The initial loadout is read from the original Level 1 budget note. Cargo over-budget disables confirmation.
- The landing-site countdown remains 60 seconds. Expiry selects a site using the saved/default deterministic seed, explains the random choice, and leaves site cards editable until the player confirms. Site facts and all displayed site numbers are looked up through `GameDataRepository.fact` and carry NASA DATA chips; only source-backed ice facts are shown. Provisional site-risk descriptions are kept separate with GAME VALUE chips. No timer or research values were added.
- Story dialogue follows the eight-scene preview PDF. The scene 3, 4, and 5 Dave messages use the source wording. Original source data and status-line templates were not changed.
- Styling rule for all screens: every color, text style, spacing value, and corner shape must come from `lib/ui/theme.dart` or shared widgets in `lib/ui/game_widgets.dart`. `test/prompt3_prologue_test.dart` checks `lib/prologue/**` and `lib/game/**` for hard-coded `Color(0x...)` and numeric `fontSize` literals. Exemptions are `lib/ui/**`, which contains theme tokens, reusable widgets, `CustomPainter` scenery, and CrewBean character art.
- `CrewBean` suit color, visor tint, and face marks are cosmetic settings stored per role. The four BASE 67 roles and their story traits remain Commander, Engineer, Scientist, and Medic. Original `assets/data/crew.json` entries and status-line templates remain unchanged.
- Long landing-site and cargo dialogue uses a bounded, scrollable viewport sized by `GameSpacing.messageViewport` so small screens and enlarged text do not overflow; the source dialogue wording is preserved.
