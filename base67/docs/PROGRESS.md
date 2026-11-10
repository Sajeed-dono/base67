# BASE 67 Development Progress

Updated: 2026-11-10

## Current prompt and gate

- Prompt 2 status: **COMPLETE** — visual reference pass reviewed by the owner and committed as `43e15ac`.
- Prompt 3 status: **COMPLETE** — committed as `c61af76` (analyzer and 24 tests were recorded in the Prompt 3 handoff).
- Current activity: **Owner-authorized Prompt 4B-2 implementation is present locally: schema 3, aggregate codec, migration/backup, serialized controller and startup/resume wiring. Owner terminal validation and independent review are PENDING; no validation commands were run in this implementation pass; no commit/push.**
- Prompt 4 status: **IMPLEMENTATION READY FOR VALIDATION, NOT VERIFIED COMPLETE: 4A/4B-1 previously committed; reviewed service-policy work preserved; 4B-2 implemented locally but unvalidated. Prompt 5 NOT STARTED.**
- Prompts 2–3 provided presentation and setup; 4A adds the pure engine without app wiring or mission outcomes.

## Prompt 4B-2 final implementation authorization (2026-11-10)

- The owner's attached final authorization supersedes the previous 4B-2 implementation gate and reserves tests, analyzer, builds, Git diff checks and validation scripts for the owner. Earlier test results in this document are historical and do not validate this implementation.
- `CampaignSave` reads legacy schemas 1/2 and schema 3. Schema 3 stores one canonical progression object; overlapping inventory, resources, facility-level, research, completion and job presentation fields are computed views and are not stored twice. Historical schema-2 constructors/codecs remain available for the unchanged prologue and fixture tests.
- `CampaignMigration` adapts repository documents, preserves player metadata and existing balances (including zero), imports legacy facility presentation tiers as one installed unit plus its tier, initializes only absent approved reserve fields at setup/migration, and invokes existing receipted resupply/catch-up. Packed spare parts transfer through the existing canonical unpack operation; ambiguous mixed ownership stops migration unchanged.
- Readable legacy saves that fail migration are not replaced with a backup or a blank campaign. Unsupported versions stop unchanged. Legacy jobs lacking trustworthy effect/payment history are retained as terminal archived records, free their crew, reserve their IDs, and log their no-cost/no-effect retirement. The synthetic f0a179f fixture remains unchanged and is not a real player save.
- `ProgressionCodec` round-trips resources/pending deliveries, cargo reservations, installed counts/tiers/status/damage, immutable job recipes/payments, occurrence allocations, restricted entitlements/receipts, lanes/crew and clock checkpoints/tokens. It validates incoming and outgoing snapshots against current approved configuration. Restore entry points do not read time or grant progress; original service-policy transitions and Clock Option A are preserved.
- `CampaignSaveStore` retains the existing primary key/backend, backs up exact prior valid bytes before replacement, verifies the backup and complete primary read-back, and retains the previous backup after success. Primary-write/read-back failure attempts restoration, preserves the verified backup and requires reload. Corrupt/missing primary may load a valid backup with a visible recovery notice; two unusable blobs never become a blank save. This is not a claim of ACID transactions, cross-process locking or tested power-loss durability.
- `CampaignController` serializes state changes, captures UTC/token pairs before asynchronous command delivery, rejects stale observations and callbacks from a reset campaign, and publishes only after verified storage. Startup/resume reconcile existing active jobs; one wake-up at the nearest remaining job duration handles foreground completion. Queues do not start automatically; no simulation time or survival consumption advances offline.
- Router settings/reset/setup writes now use the coordinator. Existing campaign replay retains the original prologue presentation but discards setup edits and starting grants; no prologue source/story/layout was changed. The existing explicit reset confirmation remains the reset entry point. Presentation reads the canonical save views without redesigning screens.
- Added `test/progression_persistence_test.dart` with migration/fixture, failure/backup, malformed/future save, restart/rollback, occurrence/payment/shutdown serialization and controller coordination regressions. The only necessary existing-test adaptation is the prologue integration assertion: unpacked spare parts are now expected in resources, absent from packed inventory. Existing service-policy tests, including the latest ownership assertions, are preserved.
- **Not run in this pass:** focused/full Flutter tests, analyzer, builds, check_data.py, original checksum verification, git diff --check, automated validation scripts. Owner must run the commands in the final handoff and review real results. Prompt 4 is not marked verified complete. No Prompt 5, stage, commit or push.
- Remaining limits: strict current recipe/catalogue validation means future data/balance revisions require an explicit compatibility migration; production essential-damage catalogue remains empty pending mission definitions; rejected legacy ambiguity needs owner resolution; device restart/power-loss behavior and manual prologue replay/reset checks remain unverified.

## Historical Prompt 4A implementation

- Added the pure Dart engine, immutable configuration/snapshots/inputs, explicit simulation clock, power/resource/radiation/event models, restorable seeded RNG and repository adapter. No app wiring or progression service is included.
- Only extra/sim_params.json and extra/resource_economy.json receive new GAME VALUE, provisional inputs. Additive bonuses and all model simplifications are documented in SIM_MODEL and Decisions.
- New test/sim tests cover reserve estimates, formulas, finite shortages, inactive facilities, purity, immutable state, scripted/seeded events and deterministic snapshot continuation. Original assets, checksums and existing tests are preserved.
- Recorded 4A validation (prior implementation session): `flutter analyze` exited 0 (`No issues found!`, 19.2s); `flutter test --reporter expanded --concurrency=1` exited 0 (`All tests passed!`, 63 tests); `python check_data.py` exited 0 (`facts: 40 | sources: 24 | ALL OK`). The full suite includes the unchanged original-pack checksum test and all existing UI/prologue tests.
- 4A was subsequently approved and committed as `f0a179f`; at the historical 4A completion checkpoint, local HEAD and origin/main identified that commit. The earlier no-commit handoff is historical. Prompt 4 is incomplete; 4B-1 is tracked below, 4B-2 and Prompt 5 are unstarted. No Android-device verification of the engine is claimed.

## Prompt 4B-1 implementation (historical record)

Owner subsequently approved/committed/pushed this work as 6ddb2c3. The salvage limitations below describe that original version; the current service-policy follow-up supersedes them.

- Added an unwired pure Dart progression service with immutable job/config/state/receipt objects, explicit UTC inputs, construction, one supported upgrade tier, selected timed repairs, research prerequisites, crew exclusivity, queues and cancellation. Extended the existing timer completion guards; existing save/timer APIs and schema 2 are unchanged.
- New GAME VALUE, provisional data is restricted to five existing extra JSONs. Resupply is 80 start / capacity 200 / +10 once per first completion of levels 1-14, with deterministic catch-up receipts and retained overflow. Salvage is one required-construction shortfall per level, capped at 8 material units, receipted and restricted against optional spending.
- Added progression service/economy tests and `test/fixtures/pre_4b_f0a179f.json`. The fixture was generated using the unchanged current serializer at f0a179f; its settings contain the provenance note. It is synthetic, NOT a real player save, and has no timer jobs.
- Baseline configuration costs 62 materials for all 11 facilities, leaving 18 from the initial 80 even without mission rewards (including an initial habitat that existing prologue saves already own). With all 14 eligible rewards and baseline spending, final materials are 158. This is configuration affordability, not proof of future mission solvability.
- Recovery limits: cancelling salvage-funded work can leave a new shortfall after the level receipt is spent; one grant cannot cover multiple depleted requirements in one level; missing repair spare parts are outside required-construction salvage. Tests retain these counterexamples. An unconditional no-soft-lock claim is not made.
- No save schema/store/controller/router/UI/prologue/sim/original pack/checksum changes. Receipts exist in the service aggregate only; disk persistence, migration and real app restart verification belong to 4B-2. Owner review and commit/push of 4B-1 gate 4B-2. No Prompt 5, sound, commit or push.
- Final validation in this 4B-1 session: `flutter analyze` exit 0, `No issues found! (ran in 1.2s)`; `flutter test --reporter expanded --concurrency=1` exit 0, `00:08 +102: All tests passed!` (39 new, 63 existing); `python check_data.py` exit 0, `facts: 40 | sources: 24 | ALL OK`. Raw outputs are in the live session log. All unchanged original checksums/UI/prologue/sim tests ran. No Android build/device test was run.

## Service-policy follow-up (owner-approved specification)

- Push gate verified before edits: remote origin/main = 6ddb2c371476283427dd89c5d1e02aaf80b69bce. Local 4B-1 commit was not rewritten.
- Added unwired restricted recovery with config-derived mandatory objective IDs and validated/confirmed damage identities, full assistance restoration versus ordinary 50% refunds, two shared lanes, packed stock reservations/transfers, multiple installed units with source-backed limits, independent facility projection, per-job rollback correction and the assigned Engineer half-time timed-repair modifier.
- The production damage-occurrence catalogue is empty until missions define authoritative events. Test entries are synthetic. Unknown/unconfirmed damage cannot receive assistance. Pure continuation is not disk/app restart validation.
- No schema-2/save/store/controller/router/prologue/UI/lib/sim/original data/checksum/package/legacy fixture changes. Existing replay overwrite risk and durable save coordination are pending 4B-2, not fixed by the unwired service.
- Original costs, 80/200/+10 material resupply, survival stocks/production, source-unit conversion and base timers are unchanged. New policy rules remain GAME VALUE, provisional.
- Final validation: `flutter analyze` exit 0, `No issues found! (ran in 0.9s)`; `flutter test --reporter expanded --concurrency=1` exit 0, `00:09 +122: All tests passed!`; `python check_data.py` exit 0, `facts: 40 | sources: 24 | ALL OK`. The complete original-pack/UI/prologue/simulation suites ran. An intermediate new two-occurrence test failed constructing a typed fixture map; its type was corrected without changing assertions and the complete suite reran. Raw failed/final outputs are in the live session log. Original-pack SHA-256: 16/16 match; protected paths diff empty. No device build/test was run. Do not mark Prompt 4 complete. No commit/push; owner review is required. Storage evaluation/schema-3 plan follows this independent review; implementation requires separate approval.

## Owner-approved audit corrections (2026-11-10)

- The independent audit rejected the earlier 122-test implementation. Owner then approved the correction plan and Clock Option A. Historical validation is not acceptance evidence; independent review remains required.
- Damage allocations are independent of payment identity. Confirmation requires a validated occurrence observation, not merely current aggregate damage. Ordinary-funded repairs resolve their bound occurrence; final resolution closes restricted credits and retains receipts. Cancellation keeps the same allocation and payment-source rules. External field-repair reporting is pure and unwired; it does not execute/pay for a field action.
- First construction clears lifecycle-only states on completion; deliberate off states survive. Expansion preserves installed operation, damage and tier. Pending units remain in jobs and contribute no capacity. Reserved cargo returns once on cancellation. Invalid installed lifecycle states are rejected.
- Clock Option A bundles UTC and capture-order token. Old/duplicate timed requests return the original snapshot before mutation. Accepted rollback retains the original formula and moves the checkpoint. No clock reader, coordinator or persistence is added.
- Canonical repair spares live in resources['spare_part']. Explicit unpacking consumes packed stock atomically; repeats transfer nothing and mixed positive representations are rejected as ambiguous. Ordinary spare refunds remain floored 50%; assistance returns restricted at 100%; spares never become facilities.
- Final validation this correction session: flutter analyze exit 0, No issues found! (ran in 0.9s); flutter test --reporter expanded --concurrency=1 exit 0, 00:09 +136: All tests passed! (14 added regressions; prior tests retained); python check_data.py exit 0, facts: 40 | sources: 24 | ALL OK; original SHA-256 16/16 matching. Raw final outputs and final diff checks are appended to the live session log. Initial analysis had five brace-style infos, fixed before final analysis; an earlier complete run passed 131 tests before four further edge-case regressions were added (135 passed); final diff inspection then added the invalid-start observation-order regression and the complete suite passed 136.
- No schema/store/app/prologue/UI/sim/data/dependency/balance changes in this correction pass. Existing uncommitted JSON, timer-helper and GAME_BRIEF changes belong to the earlier follow-up and were preserved byte-for-byte. No stage/commit/push or device build/test. Next gate: independent review; no acceptance or Prompt 4 completion claim.

## Construction cancellation audit correction (2026-11-10)

- Lifecycle rollback now applies only to an active construction job. Cancelling queued or blocked work cannot reset the `underConstruction` state owned by another active first build.
- Added two regressions: cancelling a queued same-facility build and cancelling one blocked by `target_busy`; both assert the active build retains payment, Engineer assignment, clock progress, cargo reservation, and facility lifecycle state.
- Verification in this task: targeted ownership suite passed 14 tests; full Flutter suite passed 138 tests; `flutter analyze` reported no issues; `git diff --check` passed. This is a local correction only and awaits independent confirmation; Prompt 4 remains partial, 4B-2 and Prompt 5 remain not started.

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
- Prompt 3 is complete and committed as `c61af76`; the recorded validation is clean analysis and 24 passing tests. Current Prompt 4A status is tracked above.

## Interim Android portrait lock (not a numbered prompt)

- Android activity orientation is set to portrait in `android/app/src/main/AndroidManifest.xml`; Flutter also requests `DeviceOrientation.portraitUp` before `runApp` in `lib/main.dart`.
- `flutter analyze` exited 0 (`No issues found!`, 13.7s); `flutter test` exited 0 (`All tests passed!`, 24 tests).
- This earlier interim task verified Flutter analysis and tests only; it did not run an Android build or physical-device orientation check, or start sound or Prompt 4.

## Interim portrait-lock follow-up

- Launcher label is `BASE 67`. Decisions now record both debug and profile INTERNET permissions. The portrait-lock handoff is completed with fresh command evidence in the live `docs/vault/templates/SESSION_LOG.md`.
- Fresh follow-up validation: `flutter analyze` exited 0 (`No issues found!`, 22.6s); `flutter test` exited 0 (`All tests passed!`, 24 tests). Raw output is recorded in the live session log.
- The owner's existing `META_PROMPT.md` addition was retained unchanged in that follow-up. It included no Android build, device run, sound work or Prompt 4 implementation. The owner later approved its local commit.

## Sound scope agreed for Prompt 7 (not started)

- Android release; web development checks only. Initial sound scope is short UI/action effects; music later, no voice. There is no interim sound implementation.
- Audio sourcing is free-only: CC0, CC-BY or equivalent commercial-use licenses, excluding NC and ND. Owner approval is required before download and owner license confirmation before committing each file. Per-file credits include source URL, author, license and date in a new file under `assets/data/extra/`; original `credits.json` remains untouched.
- Persisted master mute applies everywhere. Default sound is on at low volume, with a visual equivalent for every cue. Duck/pause on focus loss, remain silent if focus is denied, and handle interruptions without crashing.
- Package selection and size budget await the Prompt 7 plan. Requirements are recorded in `docs/DECISIONS.md`; no sound code, package, or asset has been added. Sound remains unstarted; Prompt 4A is tracked above.
