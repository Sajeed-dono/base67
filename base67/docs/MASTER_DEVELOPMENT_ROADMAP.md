# BASE 67 master development roadmap

Updated: 2026-11-12. Latest validation checkpoint: analyzer passed with zero issues in the prior cleanup session; full Flutter suite passed and release APK built at 52.2 MB per owner report. Android device/final acceptance is pending. No new test/analyzer/build execution is claimed by this consolidation update.

 Authority: the owner's MASTER DEVELOPMENT ASSIGNMENT covering M2-M10 as one sequential assignment. This replaces the earlier six-milestone proposal below M1. M1's focused/full/analyzer/original-pack checks are owner-reported passed, without supplied counts/logs; those are not checks reproduced in this session. Preserve existing later campaign content but implement no new Level 3/Prompt 7 mechanics. Focused tests are authorized; full suite, analyzer and builds remain manual. SESSION_LOG.md must remain untouched.

## Inspection and actual baseline

| Area | Evidence in the current repository | Status and limitation |
|---|---|---|
| UI foundation | lib/ui/theme.dart, game_widgets.dart, data_class_chip.dart; ui_design_system_test.dart | Semantic B1 colors, typography, cream/control surfaces and responsive controls exist. Wider responsive coverage was added previously; its latest execution results are not available. |
| Settlement | settlement_map.dart, mars_base_painter.dart, facility_architecture.dart, settlement_snapshot.dart | Shared original code-drawn scene, condition/job projections and inspection exist. Art remains a schematic 2.5D interpretation rather than the complete reference presentation. |
| World/camera | SettlementLayout; settlement_camera.dart | Shared fixed 900 x 700 presentation world, pan/zoom/follow and inverse picking exist. Camera is a 2D transform, not a 3D/ground-level camera. Ground, hulls and actor positions must remain stable. |
| Astronauts | crew_bean.dart, crew_movement.dart, settlement_crew_screen.dart | Four original roles, saved appearances/names, movement/gait, exterior routes, separation and assignment displays exist. Walking never performs simulation work. Detailed contextual character interaction still needs visual/interaction review. |
| Buildings | extra/buildings.json, FacilityMapping, progression_service.dart | Construction, upgrades, repairs, limits, packed reservations, crew lanes and refunds exist. Lab/rover visual reference sites have no construction recipes; medical presentation aliases the habitat. Do not represent these as new functioning facilities. |
| Energy/resources | lib/sim, sim_config_loader.dart, original/extra data | Pure engine calculates generation, power allocation, batteries, resources, temperature and safe pauses. No second model is needed. Configuration remains provisional; playability across sites and strategies is not proven by source inspection. |
| Missions | mission_runtime.dart, campaign_controller.dart, mission_screen.dart | Actual briefing/review/planning/play/debrief, engine observations, retry and persistent completion exist for the campaign. Level 2 requires charge/discharge evidence and its reserve across a sol. UI availability does not establish solvability or polished gameplay. |
| Progress/rewards | campaign_controller.dart, progression_service.dart, campaign_map_screen.dart | Fifteen nodes/five chapters, completion/unlocks and receipted material resupply exist. Stars/mastery/badge/patch presentation does not establish implemented award criteria; broader reward work remains outside this first milestone and must not drift into Prompt 7. |
| Persistence | campaign_save.dart, campaign_migration.dart, campaign_save_store.dart | Schema 3, legacy migration, one serialized aggregate, primary/backup and read-back verification exist. No database replacement is necessary. Physical-device failure durability is not verified here. |
| Menu/prologue | game_router.dart, prologue.dart, prologue_scenery.dart | Scrollable responsive Splash, Settings and eight-step source-cited prologue exist. Cinematic completeness and cohesive menu scenery are partial. Story wording was not re-compared with the source PDF in this inspection. |
| Tests | sim, progression, persistence, movement, mission and responsive test files | Substantial regression coverage exists. Owner previously reported a full-suite pass after the Splash correction; no result for these new edits is inferred. |

Inspection includes layer boundaries, shared ownership, rendering/input, source configuration, current screen composition and relevant tests/docs. It is not a claim that every line, NASA source, save history or device scenario has passed an independent audit. Original data remains read-only.

## Authorized M2-M10 sequence

Status vocabulary: COMPLETE = implemented and validated; IMPLEMENTED = source ready, validation pending; PARTIAL = work remains; BLOCKED = a specific decision/dependency; NOT STARTED = no implementation. Aesthetics, Android performance and physical-device acceptance cannot be inferred from widget tests.

| Milestone | Scope and reuse | Current status |
|---|---|---|
| M1 | Power panel, detached actual-engine preview, Level 2 local heater, canonical jobs/save | COMPLETE per owner report; current focused checks also pass, full suite/analyzer not reproduced here |
| M2 | Layered deterministic sunlit/night terrain, ridges, surface detail, same-clock atmospheric wisps and bounded caches | IMPLEMENTED; render/geometry tests pass; visual/device acceptance pending |
| M3 | Cream/rust modular architecture, raised roofs/decks/vents/airlocks, distinct facility silhouettes, scaffold/damage/off states; per-facility picture cache | IMPLEMENTED; render/state-refresh/inspection tests pass; final art/device review pending |
| M4 | Selected-astronaut inspection with real name/role/appearance/task/destination/saved remaining time and existing Crew navigation; reuse gait/activity/reservation art | IMPLEMENTED; enlarged-text inspection/assignment tests pass; Android interaction review pending |
| M5 | Accessible Show on map framing using existing bounded transform, with pan/pinch/zoom/follow and exterior visits preserved | IMPLEMENTED; framing/inverse/picking/movement tests pass; device gestures pending |
| M6 | Canonical telemetry, reconciled remaining-work HUD, actual Home night/storm/dust, pause feedback and Settings access | IMPLEMENTED; HUD/clock/weather/pause/responsive checks pass; final visual review pending |
| M7 | Existing real construction/crew/engine/evidence/retry/resupply/unlock/save chain, clearer successful debrief, same persistent base | IMPLEMENTED; real L1-to-L2 reference strategy succeeds at all four sites and restarts mid-mission; manual play/pacing pending |
| M8 | Next-mission details, goals, configured one-time reward vs recorded receipt, long-press completed-node details and existing briefing navigation | IMPLEMENTED; three-width persisted status/reward/navigation checks pass; visual acceptance pending |
| M9 | Original static menu artwork, dark mission-control route theme, same responsive Splash, richer touchdown lander/ridges, OS-level reduced-motion compliance | IMPLEMENTED; navigation/prologue/motion/responsive regressions pass; narrative-source and final aesthetic acceptance pending |
| M10 | Focused integration, original-pack hash checks, drawing-cache refresh, persistence/migration/restart regressions and honest final handoff | PARTIAL; analyzer/full suite/release APK passed as attributed below; Android and final acceptance remain pending |

Dependencies remain sequential. The existing lab and rover sites have no recipes; medical presentation aliases the habitat. No fictional facility function, starting damage or reward amount is authorized by a reference image.

## M1 decisions and boundaries

- The owner explicitly selected: introduce existing load switches in Level 2. Only the already-present heater is relevant there. It is exposed as the habitat's local control, requiring that habitat; essential habitat power cannot be disabled. Existing station requirements remain from Level 3, and greenhouse/miner controls retain their later unlocks. No recipe, capacity, price, timer or temperature formula changes.
- PowerMissionReport derives current checklist state from the canonical aggregate/session. Its next-step forecast calls the existing begin/step path on detached inputs, with actual charge, equipment, disabled loads and current environment. No replacement aggregate is published, no reward is granted, no clock is reconciled and no observation flag is saved by viewing it. The existing fully charged, clear-sky planning comparison remains separately labelled.
- Forecast warnings may include unmet mission evidence or safety failure; a favourable next step never promises full-cycle survival. The existing controller remains completion authority. Pending power jobs display saved remaining real time, never animation-derived completion.
- The UI introduces no literal color/font-size values; it consumes the B1 theme and shared panel/widgets. It is collapsed during briefing/review and opens for planning/play, preserving the pinned mission actions and map access.

## Current integration evidence (2026-11-12)

- First settlement group: 18 passed. A later cache-refresh test was added and the final integration group below reran that widget file.
- Initial existing power + mission-screen group: 24 passed before the expanded multi-site/restart cases and pause assertions.
- Final power/campaign/HUD/motion group: 17 passed (the HUD file subsequently gained one canonical Home-weather test, included in the 52-test group).
- Terrain + existing responsive/navigation/design-system/prologue/movement + original-pack group: 38 passed, including all 16 source hashes. Static day/night code-art captures were inspected; test-font glyph blocks are not production typography evidence.
- Final cache/widget/mission/HUD/persistence/runtime group: 52 passed. These overlapping groups are not a unique full-suite count.
- New integration fixtures initially failed on a legitimate restart observation-token increment, double-disposal in test teardown, and tapping before scroll layout. Those test fixtures were corrected without changing production clock/save behavior, dropping a mission assertion or removing an existing safeguard. Two intermediate runs had 12 passes/5 failures; the corrected group passed.
- Final power/campaign/HUD/motion recheck: 18 passed, exit 0. Full suite, analyzer and builds were not run. Tests needed access to the SDK lockfile outside the workspace; the first ordinary launcher was interrupted without output, and direct sandbox access failed before the tests started. Authorized SDK-access runs then succeeded.

## Boundaries and remaining acceptance

- The owner selected **Design starting damage separately**. Preserve the current construction-first Level 1 opening. No fabricated starting damage, entitlement, repair stock or balance change has been added. A separate design must define authoritative occurrence and funding before any implementation.
- Current L1/L2 tests use real existing recipes, configured limits and unassisted solar preparation; an 85%-capacity charging buffer is a test strategy, not a new objective/threshold. Restart is allowed exactly one new ordered real-clock observation; every other serialized field is compared unchanged. Normal mission completion and receipt checks remain strict.
- All four site reference strategies now pass automated checks. This does not establish every loadout/history is solvable, child usability, short pacing or physical-device durability. Existing lengthy timer values remain unchanged. No historical undocumented L11 defect is declared fixed.
- No new simulation formula, resource, cost, timer, research bonus, essential-load switch, schema, save backend, dependency or asset was introduced. lib/sim, mission runtime, progression policies, controller, codec/store/migration and prologue story code are unchanged in this assignment.
- Lab/rover sites still have no recipes and medical presentation still aliases the habitat. Existing source limits and later campaign IDs remain; no new Level 3 or Prompt 7 mechanics, sound, star thresholds or badge awards were added.
- Original buildings/characters are code-drawn interpretations, not copies of reference artwork. Final visual quality, actual phone readability/gesture feel, screen-reader flow, thermal/battery/CPU/GPU profiling and font appearance require owner review.
- Terrain and each facility drawing are cached separately. Actors, selection and dust overlay remain depth-interleaved using the original world. Caches invalidate on condition/count/tier/dust/progress/label/position changes and dispose removed/old pictures. No claim of measured Android performance is made.
- The unchanged prologue passed its existing setup/route/story-flow tests. Its wording was not freshly compared line-by-line to the source PDF; no story strings were edited.

## Manual finish line

Run the analyzer and complete suite, then a normal Android debug run/build at the owner's checkpoint. Inspect 360/800/1024 dp at 1.4x text and reduced motion, the real font, phone touch/pinch and background/resume. Play the original prologue, complete construction-first L1, enter L2 on the same base, build storage with the Engineer, charge it with actual preparation steps, compare the unsaved preview, test heater cooling/recovery and complete the day/night observation. Reload in planning, mid-job and mid-mission; confirm unchanged resources/evidence and no duplicate rewards. Review original-data checks and existing schema-2 migration/backup scenarios. M10 and the master assignment remain PARTIAL until these manual gates and visual acceptance are recorded.


## Consolidated prompt authority and updated acceptance gate

The authoritative sequence now includes the exact M2 terrain excerpt, complete verbatim M2-M10 assignment, targeted M10 analyzer cleanup and final-acceptance requirements. Historical prompts/order are intact. A separate standalone M2 source was not found; no historical text was invented. The index/META_PROMPT are pointers, not competing authorities. The owner's Git-delivery authorization supersedes historical no-Git restrictions only for packaging this existing work.

The previously pending analyzer/full-suite/release-build gates are now passed as attributed in PROGRESS. M10 remains PARTIAL because actual Android and final acceptance are pending. Starting damage is explicitly a separate design decision. Keep the source, original assets, schema, simulation and balance unchanged during packaging. The existing uncommitted SESSION_LOG.md and zero-byte stray file are intentionally excluded, not deleted.
