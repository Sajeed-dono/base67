# Session log (append newest entry at the bottom; never delete old entries)

| Date | Tool | Prompt | Result | Link to handoff notes |
|---|---|---|---|---|
| (start) | (owner) | Vault created | Vault files added to repo | n/a |
| 2026-11-08 | Codex | Prompt 2 visual reference pass | Updated Home Base and Campaign Map styling; analyzer clean; 17 tests passed | Handoff below |
| 2026-11-09 | Codex | Prompt 3 prologue and setup | Locally implemented and verified; analyzer clean; 24 tests passed; owner commit pending | Handoff below |
| 2026-11-09 | Codex | Interim Android Gradle note | Documented owner-reported cross-drive workaround and same-drive Pub-cache fallback; no build run | Handoff below |
| 2026-11-09 | Codex | Interim Android portrait lock | Added manifest and Flutter startup portrait requests; analyzer clean; 24 tests passed | Handoff below |
| 2026-11-09 | Codex | Interim portrait-lock follow-up | Corrected launcher label and permission note; refreshed command evidence; awaiting review without commit | Handoff at bottom |
| 2026-11-09 | Codex | Prompt 4A pure simulation | Analyzer clean; all 63 tests passed; owner review/commit/push pending; 4B not started | Handoff at bottom |

(Paste each filled-in SESSION_HANDOFF_TEMPLATE below the table.)

**Date and tool:** 2026-11-08; Codex
**Prompt worked on:** Prompt 2 of 8 — visual reference pass, Home Base and Campaign Map only
**Read before starting:** `AGENTS.md`; `docs/vault/00_START_HERE.md`; vault files `01`–`11`; `docs/PROGRESS.md`; `docs/DECISIONS.md`; `docs/GAME_BRIEF.md`; `docs/prompts/PROMPT_02_VISUAL_DESIGN.md`; all five images in `docs/reference/`; `SESSION_HANDOFF_TEMPLATE.md`

## Done (with evidence)
- Clarified Prompt 2 and Prompt 3 status in `docs/PROGRESS.md`.
- Applied the five references as style guidance to Home Base and Campaign Map; their artwork, icons, and characters were not copied.
- Added angular navy-framed panels, rust chapter markers, a layered route, and a subtle cartographic grid over the original map art.
- Updated the reference gap and visual decisions in `docs/DECISIONS.md`; removed the resolved screenshot-availability question and retained owner visual review in `docs/vault/10_OPEN_QUESTIONS.md`.
- Added screen panel assertions to `test/prompt2_ui_test.dart`.

## Partly done
- The rendered screens still need owner visual review. The browser-control host was unavailable, so no live browser screenshot comparison was possible.

## Not done
- Prompt 3 was not started, as required.

## Files changed
- `docs/PROGRESS.md` — clarified prompt gate and recorded this pass.
- `docs/DECISIONS.md` — recorded reference usage and visual choices.
- `docs/vault/10_OPEN_QUESTIONS.md` — resolved reference availability and retained owner sign-off.
- `docs/vault/09_KNOWN_PITFALLS.md` — narrow-screen long dialogue overflow lesson.
- `docs/vault/templates/SESSION_LOG.md` — appended this handoff.
- `lib/game/home_base_screen.dart` — applied reference panel and control styling.
- `lib/game/campaign_map_screen.dart` — applied chapter, path, panel, and node styling.
- `lib/ui/game_widgets.dart` — added scoped angular panel and outlined campaign pin option.
- `lib/ui/mars_base_painter.dart` — added subtle map grid and corner markers.
- `test/prompt2_ui_test.dart` — asserted styled panels on both screens.

## Real command results
- flutter analyze: `No issues found! (ran in 0.9s)`
- flutter test: `All tests passed!` — 17 tests.
- check_data.py: not run; no data files were touched.
- git diff on original data: empty; `git diff --name-only -- assets/data` returned no paths.

## Decisions made and provisional values added
- Used the references for framing, palette emphasis, and compact industrial styling only; retained the BASE 67 palette and campaign layout. Recorded in `docs/DECISIONS.md`: yes. No provisional values added.

## Conflicts found between documents
- `docs/PROGRESS.md` still said visual references were absent after the owner added five images. The current user instruction took priority; the status and reference record were corrected.

## Open questions added to 10_OPEN_QUESTIONS.md
- Owner visual review of Home Base and Campaign Map remains open. The former missing-reference item was resolved and removed.

## Next safe step
- Owner reviews the updated Home Base and Campaign Map; Prompt 3 remains gated on explicit approval.

---

**Date and tool:** 2026-11-09; Codex
**Prompt worked on:** Prompt 3 of 8 — Prologue, Crew Creation, Landing Site and First Base Setup
**Read before starting:** `AGENTS.md`; `docs/vault/00_START_HERE.md`; vault files `01`–`11`; `docs/PROGRESS.md`; `docs/DECISIONS.md`; `docs/GAME_BRIEF.md`; `docs/prompts/PROMPT_03_PROLOGUE_AND_SETUP.md`; `SESSION_HANDOFF_TEMPLATE.md`; `SESSION_LOG.md`; `docs/source/BASE_67_Prologue_Preview.pdf`; BASE 67 UI/UX skill.

## Done (with evidence)
- Added schema version 2 setup state to `CampaignSave`, including crew names/ages/appearance, site, cargo/inventory, resource stores/capacities, and prologue completion. `test/prompt3_prologue_test.dart` verifies save/load and legacy schema migration.
- Connected Prologue completion to local save and Home Base routing in `lib/app/game_router.dart`. The fake-input widget test finishes all scenes, confirms Home Base, First Light availability, and preserved campaign state.
- Kept the 60-second landing-site countdown. The expiry test verifies a seeded random choice, explanation, and editable site selection before confirmation.
- Cargo validation reads original Level 1 equipment rules and points from the repository. The over-budget test confirms loadout confirmation is disabled.
- Added token enforcement for `Color(0x...)` and numeric `fontSize` literals under `lib/prologue/**` and `lib/game/**`. Its exemptions are `lib/ui/**`: theme tokens, shared widgets, CustomPainter scenery, and CrewBean character art.
- Added `GameSpacing.messageViewport` and scrollable dialogue bubbles for landing-site and cargo setup; these layouts pass at 360 dp and 1024 dp with 1.4× text without changing the dialogue.
- Added Settings replay and confirmed reset, reduced-motion-aware original scenery animation, and appearance preview controls.
- Updated the Prompt 2 status to owner-reviewed/committed and the Prompt 3 status to locally complete/verified with owner commit pending.
- No original `assets/data/` file changed; `git diff --name-only -- assets/data` returned no paths.

## Partly done
- Prompt 3 implementation is locally verified but not committed. The vault's completion gate requires owner commit/push before marking the prompt fully complete.
- Crew age has a positive one/two-digit technical constraint; the source specifies no age range. This remains provisional.

## Not done
- Prompt 4 was not started.
- `python check_data.py` was not run because no data files were touched.

## Files changed
- `docs/PROGRESS.md` — Prompt status and verified Prompt 3 implementation evidence.
- `docs/DECISIONS.md` — PDF source mismatch, age, persistence, site/cargo choices, styling token rule and test exemptions.
- `docs/vault/10_OPEN_QUESTIONS.md` — source-reference correction, age range question, requested redesign-pass line.
- `docs/vault/templates/SESSION_LOG.md` — appended this handoff.
- `lib/app/campaign_save.dart` — setup fields, resource capacities and schema migration.
- `lib/app/game_router.dart` — save-on-completion, replay and confirmed reset.
- `lib/prologue/prologue.dart` — source dialogue and crew/site/cargo setup.
- `lib/ui/prologue_scenery.dart` — original, reduced-motion-aware painted scene effects.
- `lib/ui/crew_bean.dart` — visor and cosmetic face customization.
- `lib/ui/theme.dart` — shared dialogue viewport spacing token.
- `lib/game/home_base_screen.dart` — initial habitat/lander, crew appearance and landing equipment display.
- `lib/game/campaign_map_screen.dart` — replaced the hard-coded node font size with theme typography.
- `test/prompt3_prologue_test.dart` — save, cargo, site timeout, integration, and token rule tests.
- `test/widget_test.dart` — updates for the first-run prologue route and returning-player Home Base flow.

## Real command results
- `flutter analyze`: `No issues found! (ran in 0.9s)`; exit code 0.
- `flutter test`: `All tests passed!`; 24 tests; exit code 0.
- `python check_data.py`: not run; no data files were touched.
- `git diff --name-only -- assets/data`: empty.
- `git diff --check`: no whitespace errors; Git emitted line-ending normalization warnings for the repository's LF/CRLF settings.

## Decisions made and provisional values added
- Used `docs/source/BASE_67_Prologue_Preview.pdf` because the Prompt 3 path `docs/source/BASE_67.pdf` is not found; `docs/source/BASE 67.pdf` is a different earlier script. Prompt files were not changed.
- Kept age as a positive one/two-digit whole number without inventing an age range.
- Kept the existing 60-second countdown and deterministic random pick, still changeable before confirmation.
- Kept all NASA site values in repository lookups and data chips. No NASA number was added to Dart.
- Added no timer or research values.
- Recorded in `docs/DECISIONS.md`: yes. The exact owner visual-redesign line and open source/age questions are in `10_OPEN_QUESTIONS.md`.

## Conflicts found between documents
- Prompt 3 names `docs/source/BASE_67.pdf`, which is absent. Used `docs/source/BASE_67_Prologue_Preview.pdf`, whose contents include all eight scenes. Recorded this and left the prompt unchanged.
- The prior status text still showed Prompt 2 owner review in progress despite owner review and commit `43e15ac`; corrected it.

## Open questions added to 10_OPEN_QUESTIONS.md
- Owner may correct the Prompt 3 source PDF path if another canonical document was intended.
- Owner may define an age range; until then the field has only a technical one/two-digit positive whole-number limit.
- Added the exact requested visual redesign/token-based styling line.

## Next safe step
- Owner reviews and commits Prompt 3; Prompt 4 remains not started.

---

**Date and tool:** 2026-11-09; Codex
**Prompt worked on:** Interim Android portrait lock; not a numbered prompt
**Read before starting:** `AGENTS.md`; `docs/vault/00_START_HERE.md`; vault files `01`–`11`; `docs/PROGRESS.md`; `docs/DECISIONS.md`; `docs/GAME_BRIEF.md`; `SESSION_HANDOFF_TEMPLATE.md`; `SESSION_LOG.md`

## Done (with evidence)
- Added `android:screenOrientation="portrait"` to the main Android activity in `android/app/src/main/AndroidManifest.xml`.
- Updated `lib/main.dart` to request `DeviceOrientation.portraitUp` before starting the app.
- Recorded the interim task and its scope in `docs/DECISIONS.md`; updated `docs/PROGRESS.md` without starting sound or Prompt 4.

## Partly done
- Portrait is requested in the Android manifest and Flutter startup, but real-device behavior remains unverified because no Android build or device run was part of this step.

## Not done
- Sound integration and Prompt 4 were not started.
- No package, asset, visual redesign, or test file was added.

## Files changed
- `android/app/src/main/AndroidManifest.xml` — lock the main activity to portrait.
- `lib/main.dart` — request portrait orientation before `runApp`.
- `docs/DECISIONS.md` — record this as an interim, non-numbered task.
- `docs/PROGRESS.md` — record the verified interim status and preserve the Prompt 4 gate.
- `docs/vault/templates/SESSION_LOG.md` — append this handoff.

## Real command results
- `flutter analyze`: `No issues found! (ran in 13.7s)`; exit code 0.
- `flutter test`: `All tests passed!`; 24 tests; exit code 0.
- `check_data.py`: not run; no data files were touched.
- Follow-up check on 2026-11-09: `git diff --name-only -- assets/data` returned no paths. This is fresh working-tree evidence, not a reconstruction of the original session. Raw `git status` and `git diff --stat` follow-up output is appended below with the other command output.

## Decisions made and provisional values added
- Apply portrait orientation both natively and before Flutter's first frame. No new provisional values. Recorded in `docs/DECISIONS.md`: yes.

## Conflicts found between documents
- None for this task.

## Open questions added to 10_OPEN_QUESTIONS.md
- None. Physical-device orientation remains unverified.

## Next safe step
- Owner may verify portrait behavior on an Android phone; sound and Prompt 4 remain gated.

---

**Date and tool:** 2026-11-09; Codex
**Prompt worked on:** Interim Android build workaround documentation; no numbered prompt
**Read before starting:** `AGENTS.md`; `docs/vault/00_START_HERE.md`; vault files `01`–`11`; `docs/PROGRESS.md`; `docs/DECISIONS.md`; `docs/GAME_BRIEF.md`; `SESSION_HANDOFF_TEMPLATE.md`; `SESSION_LOG.md`

## Done (with evidence)
- Recorded the owner-reported “different roots” Android Gradle failure and the existing `kotlin.incremental=false` setting in `android/gradle.properties` in `docs/DECISIONS.md` and `docs/vault/09_KNOWN_PITFALLS.md`.
- Recorded the fallback of setting `PUB_CACHE` to a directory on the project drive.
- Corrected `docs/PROGRESS.md` to reflect the committed Prompt 3 HEAD `c61af76`; Prompt 4 remains not started.

## Partly done
- The Android Gradle workaround was documented but not verified by running a build.

## Not done
- No Flutter analysis, tests, or Android build were run; this was a documentation-only request.
- No numbered prompt was started.

## Files changed
- `docs/DECISIONS.md` — recorded the workaround as owner-reported and unverified.
- `docs/vault/09_KNOWN_PITFALLS.md` — added the cross-drive troubleshooting entry.
- `docs/PROGRESS.md` — aligned Prompt 3 status with the committed HEAD and noted Prompt 4 remains unstarted.
- `docs/vault/templates/SESSION_LOG.md` — logged this documentation-only handoff.

## Real command results
- `flutter analyze`: not run.
- `flutter test`: not run.
- `check_data.py`: not run; no data files were touched.
- `git diff` on original data: not run; no data files were touched.

## Decisions made and provisional values added
- Document the user's reported workaround without claiming a successful build. Add a same-drive `PUB_CACHE` as fallback. Recorded in `docs/DECISIONS.md`: yes.

## Conflicts found between documents
- The previous `docs/PROGRESS.md` line said Prompt 3's owner commit was pending, but the user reported it committed and Git showed `c61af76` at `main` and `origin/main`; aligned the status with that evidence.

## Open questions added to 10_OPEN_QUESTIONS.md
- None.

## Next safe step
- If the cross-drive Gradle error recurs, try a same-drive Pub cache and verify by running an Android build in an approved implementation session.

---

**Date and tool:** 2026-11-09; Codex
**Prompt worked on:** Interim portrait-lock follow-up; not a numbered prompt
**Read before starting:** `AGENTS.md`; `docs/vault/00_START_HERE.md`; vault files `01`–`11`; `docs/PROGRESS.md`; `docs/DECISIONS.md`; `docs/GAME_BRIEF.md`; `SESSION_HANDOFF_TEMPLATE.md`; `SESSION_LOG.md`

## Done (with evidence)
- Confirmed this is the live session log: START_HERE explicitly directs entries here, existing completed handoffs are present, and no other live session log was found. The blank form is `SESSION_HANDOFF_TEMPLATE.md`.
- Changed the Android launcher label from `base67` to `BASE 67`.
- Corrected Decisions to document INTERNET permissions in both debug and profile manifests; the main manifest has none.
- Replaced the portrait-lock entry's pending original-data diff placeholder with a dated follow-up result and a reference to the fresh raw command output below.
- Retained the owner's existing `META_PROMPT.md` addition unchanged.

## Partly done
- A merged release manifest, Android build, and physical-device portrait behavior were not verified here. The emulator-test claim in META_PROMPT is owner-provided evidence.

## Not done
- No commit or push was made. Sound and Prompt 4 remain unstarted.

## Files changed
- `android/app/src/main/AndroidManifest.xml` — launcher label.
- `docs/DECISIONS.md` — debug/profile permission note and interim follow-up decision.
- `docs/PROGRESS.md` — interim review status and fresh validation.
- `docs/vault/templates/SESSION_LOG.md` — completed portrait evidence and appended this handoff.
- `docs/vault/META_PROMPT.md` — existing owner addition included in the review diff; not edited by Codex.

## Real command results
These are raw outputs captured in this follow-up, not reconstructed historical results. Git output snapshots are taken before embedding those snapshots into this log, so the final log insertion changes the subsequent diff-stat totals.

Command: `flutter analyze` (exit code 0)
```text
Analyzing base67...                                             
No issues found! (ran in 22.6s)
```

Command: `flutter test` (exit code 0)
```text
00:00 +0: loading H:/projects/base67/test/data_integrity_test.dart
00:00 +0: H:/projects/base67/test/display_text_test.dart: legacy source display text resolves to the current game title
00:00 +1: H:/projects/base67/test/data_integrity_test.dart: all bundled source and campaign data loads and validates
00:00 +2: H:/projects/base67/test/original_pack_test.dart: original data pack files match supplied source checksums
00:00 +3: H:/projects/base67/test/original_pack_test.dart: original data pack files match supplied source checksums
00:00 +4: H:/projects/base67/test/progression_test.dart: same seed produces the same deterministic sequence
00:00 +5: H:/projects/base67/test/progression_test.dart: campaign save round-trips its persistent state
00:00 +6: H:/projects/base67/test/progression_test.dart: campaign save store restores through local key-value storage
00:00 +7: H:/projects/base67/test/progression_test.dart: offline timer completion is due and reward completion is idempotent
00:00 +8: H:/projects/base67/test/prompt3_prologue_test.dart: (setUpAll)
00:00 +8: H:/projects/base67/test/prompt2_ui_test.dart: (setUpAll)
00:00 +8: H:/projects/base67/test/prompt2_ui_test.dart: Home Base and Campaign Map fit 360dp at 1.4x text
00:00 +9: H:/projects/base67/test/prompt2_ui_test.dart: Home Base and Campaign Map fit 360dp at 1.4x text
00:00 +10: H:/projects/base67/test/prompt2_ui_test.dart: Home Base and Campaign Map fit 360dp at 1.4x text
00:01 +11: H:/projects/base67/test/prompt2_ui_test.dart: Home Base and Campaign Map fit 360dp at 1.4x text
00:01 +12: H:/projects/base67/test/prompt2_ui_test.dart: Home Base and Campaign Map fit 360dp at 1.4x text
00:01 +13: H:/projects/base67/test/prompt3_prologue_test.dart: crew, site and cargo setup fit 360dp at 1.4x text
00:01 +14: H:/projects/base67/test/widget_test.dart: Home Base and Campaign Map routes open
00:01 +15: H:/projects/base67/test/widget_test.dart: Home Base and Campaign Map routes open
00:01 +16: H:/projects/base67/test/widget_test.dart: Home Base and Campaign Map routes open
00:01 +17: H:/projects/base67/test/widget_test.dart: Home Base and Campaign Map routes open
00:01 +18: H:/projects/base67/test/widget_test.dart: Home Base and Campaign Map routes open
00:01 +19: H:/projects/base67/test/prompt3_prologue_test.dart: crew, site and cargo setup fit 1024dp at 1.4x text
00:01 +20: H:/projects/base67/test/prompt2_ui_test.dart: all navigation screens open at 360dp with 1.4x text
00:01 +21: H:/projects/base67/test/prompt2_ui_test.dart: all navigation screens open at 360dp with 1.4x text
00:02 +22: H:/projects/base67/test/prompt3_prologue_test.dart: fake taps finish prologue and arrive at the persistent base
00:02 +23: H:/projects/base67/test/prompt2_ui_test.dart: all navigation screens open at 1024dp with 1.4x text
00:02 +24: H:/projects/base67/test/prompt2_ui_test.dart: (tearDownAll)
00:02 +24: All tests passed!
```

Command: `git -c safe.directory=H:/projects status` (exit code 0)
```text
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   android/app/src/main/AndroidManifest.xml
	modified:   docs/DECISIONS.md
	modified:   docs/PROGRESS.md
	modified:   docs/vault/META_PROMPT.md
	modified:   docs/vault/templates/SESSION_LOG.md

no changes added to commit (use "git add" and/or "git commit -a")
```

Command: `git -c safe.directory=H:/projects diff --stat` (exit code 0)
```text
warning: in the working copy of 'base67/docs/DECISIONS.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'base67/docs/PROGRESS.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'base67/docs/vault/META_PROMPT.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'base67/docs/vault/templates/SESSION_LOG.md', LF will be replaced by CRLF the next time Git touches it
 base67/android/app/src/main/AndroidManifest.xml |  2 +-
 base67/docs/DECISIONS.md                        |  6 +-
 base67/docs/PROGRESS.md                         |  8 ++-
 base67/docs/vault/META_PROMPT.md                |  6 ++
 base67/docs/vault/templates/SESSION_LOG.md      | 86 ++++++++++++++++++++++++-
 5 files changed, 104 insertions(+), 4 deletions(-)
```

Command: `git -c safe.directory=H:/projects diff --name-only -- assets/data` (exit code 0; empty output)
```text
```

- Initial `git diff --check`: failed (exit code 1). It flagged trailing spaces in the verbatim analyzer output and a new blank line at EOF. The EOF blank line is removed below; the analyzer output is retained verbatim as requested, including its trailing spaces.

- `check_data.py`: not run; no data files were edited.

## Decisions made and provisional values added
- Use the existing live log, correct the launcher name and build-variant documentation, and preserve the owner's META_PROMPT addition. Recorded in Decisions: yes. No new provisional values.

## Conflicts found between documents
- Decisions described INTERNET as debug-only despite the profile manifest also requesting it; corrected the note.

## Open questions added to 10_OPEN_QUESTIONS.md
- None. The existing device-verification limitation is retained above.

## Next safe step
- Owner reviews the full diff and raw outputs; wait for approval before committing.

---

**Date and tool:** 2026-11-09; Codex
**Prompt worked on:** Sound decision documentation for future Prompt 7; no numbered prompt started
**Read before starting:** `AGENTS.md`; `docs/vault/00_START_HERE.md`; vault files `01`–`11`; `docs/PROGRESS.md`; `docs/DECISIONS.md`; `docs/GAME_BRIEF.md`; `META_PROMPT.md`; `SESSION_HANDOFF_TEMPLATE.md`; live `SESSION_LOG.md`

## Done (with evidence)
- Recorded the owner's Android/web scope, short effects first, music later, no voice, free-only audio sourcing, per-file extra-layer credits, persisted master mute defaulting on at low volume, visual cue equivalents, and interruption/focus rules in Decisions and Progress. The owner subsequently specified commercial-use CC0, CC-BY or equivalent licenses (no NC/ND), source URL/author/license/date credits, approval before downloads, and license confirmation before each audio file is committed.
- Updated the META_PROMPT sound line: requirements agreed, implementation deferred to Prompt 7, no interim sound work; package and size budget await that plan.

## Partly done
- Package choice and size budget remain undecided for the Prompt 7 plan.

## Not done
- No sound code, package, audio asset, or credits data file added. Prompt 4 and Prompt 7 remain unstarted. No commit or push made.

## Files changed
- `docs/DECISIONS.md`, `docs/PROGRESS.md`, `docs/vault/META_PROMPT.md` — owner-approved sound decisions and scheduling.
- `docs/vault/templates/SESSION_LOG.md` — this required handoff.

## Real command results
- `flutter analyze`: `No issues found! (ran in 2.4s)`; exit code 0.
- `flutter test`: `All tests passed!`; 24 tests; exit code 0.
- `check_data.py`: not run; no data files were edited.

## Decisions made and provisional values added
- Owner's sound decisions recorded in `docs/DECISIONS.md`: yes. No numeric volume, package, or size budget selected.

## Conflicts found between documents
- META_PROMPT's former pending sound-plan line now distinguishes agreed requirements from the future Prompt 7 implementation plan.

## Open questions added to 10_OPEN_QUESTIONS.md
- None; the pending package and size decisions are recorded for the Prompt 7 plan in Decisions and Progress.

## Next safe step
- Owner reviews the documentation diff; wait for approval. No interim sound implementation.

---

**Date and tool:** 2026-11-09; Codex
**Prompt worked on:** Prompt 4A only — pure simulation, config adapter and simulation tests
**Read before starting:** AGENTS.md; START_HERE; vault 01–11; PROGRESS; DECISIONS; GAME_BRIEF; SIM_MODEL; PROMPT_04_SIMULATION_ENGINE; original data/config; existing repository, RNG, save/timer and tests; SESSION_HANDOFF_TEMPLATE.

## Done (with evidence)
- Implemented immutable SimConfig/SimState/PlayerInputs, SimulationClock, Engine.step/run/Policy/Trace and one trivial BaselinePolicy. No level-specific policies.
- Implemented source-backed power, batteries, loads/shedding, crew needs, greenhouse/miner output, storage, simplified temperature/radiation, scripted/seeded events and simulation actions.
- SimConfigLoader resolves fact IDs and units outside lib/sim. Extra config contains only approved GAME VALUE, provisional simulation inputs and modifiers; same-stat bonuses add.
- Added test/sim/config_test.dart, model_test.dart and determinism_test.dart. They cover prohibited imports/APIs, immutable snapshots, malformed config, shortages/inactive facilities/non-finite state, source units, 8.20/9.73/10.18-sol reserves, additive modifiers, event boundaries, conservation and deterministic restoration.
- Existing tests, original assets/checksums, prologue, app wiring, progression services, UI and dependencies were not modified. Original-pack checksums passed in the full suite; the original-data checker passed.

## Partly done
- 4A is locally verified and awaits owner review/commit/push. Prompt 4 as a whole is incomplete until 4B is approved and completed.
- Balance and thermal/event/protection simplifications remain GAME VALUE, provisional and physically unverified. NASA human source audit and student testing remain outstanding.

## Not done
- No app/persistence wiring, real-time services, material source, costs, research prerequisites, timer selections, cancellation/refunds or completion ledger written. No sound, Prompt 5, commit or push.
- No Android build/device execution of the new engine; the engine is not connected to screens.

## Files changed
- lib/sim/: extended seeded_rng.dart; added sim_config.dart, sim_state.dart, player_inputs.dart, simulation_clock.dart, power_model.dart, resource_model.dart, radiation_model.dart, event_model.dart and engine.dart.
- lib/data/sim_config_loader.dart; the three new test/sim files.
- assets/data/extra/resource_economy.json and sim_params.json only.
- docs/SIM_MODEL.md, DECISIONS.md, PROGRESS.md, vault/09_KNOWN_PITFALLS.md, vault/10_OPEN_QUESTIONS.md and this live log.

## Real command results
- flutter analyze: exit 0, `No issues found! (ran in 19.2s)`.
- flutter test --reporter expanded --concurrency=1: exit 0, `00:07 +63: All tests passed!`.
- python check_data.py (assets/data): exit 0, `facts: 40 | sources: 24 | ALL OK`.
- Git data diff lists only the two extra simulation JSONs; protected original-data and existing-test/application diffs are empty. New files remain untracked pending owner review; ordinary git diff --stat omits them.
- Initial focused tests failed during configuration setup because a nested unmodifiable map had dynamic typing; fixed production typing, without weakening or skipping tests. Initial analyzer style findings were fixed. Final analysis/full suite are clean.

## Decisions made and provisional values added
- Recorded in Decisions and SIM_MODEL: scope split, approved reserve/capacity/storage/water inputs, additive modifiers, source-unit conversion, exact source-derived solar values, finite guards/safe pauses, explicit clock/RNG and provisional model responses.

## Conflicts found between documents
- Prompt 4 includes progression, but the owner's explicit 4A/4B split defers those parts. SIM_MODEL already existed; extended it rather than creating a second document. Corrected Progress's obsolete current Prompt 4 gate without altering prompt files.

## Open questions added to 10_OPEN_QUESTIONS.md
- 4B material source: propose deterministic mission resupply initially; owner to choose resupply, production or both. Any costs require existing facilities.
- Simulation balance/response assumptions remain provisional and unverified.

## Next safe step
- Owner reviews 4A, then commits and pushes if accepted. 4B stays gated on that commit/push and approval.


---

**Date and tool:** 2026-11-09; Codex
**Prompt worked on:** Prompt 4B-1 only — unwired progression service, configuration and tests
**Read before starting:** AGENTS.md; START_HERE; vault 01–11; PROGRESS; DECISIONS; GAME_BRIEF; Prompt 4; SIM_MODEL; existing campaign save, timer completion, original progression tests and extra configuration; SESSION_HANDOFF_TEMPLATE. The earlier 4A log is historical; current HEAD and local origin/main both identify f0a179f (no fetch).

## Done (with evidence)
- Added immutable progression configuration, jobs, state and receipts in lib/progression/progression_service.dart; extended the existing TimerCompletion guards. Explicit UTC input and observed-time floor; no simulation calls, disk, UI, audio or wall-clock reads. Construction, one existing-effect upgrade tier, selected timed repairs, research prerequisites, queues, crew exclusivity, payments/refunds and deterministic resupply/recovery are covered by new tests.
- Added five extra JSON updates only, all new numbers/rules marked GAME VALUE, provisional. Baseline facilities cost 62, initial 80 leaves 18 without rewards; with first-completion rewards the baseline ends at 158. Tests verify affordability before each level reward.
- Generated test/fixtures/pre_4b_f0a179f.json with the unchanged CURRENT CampaignSave serializer at commit f0a179f before any schema change. It is synthetic, NOT a real player save; this note is inside settings. Schema 2 round-trips exactly; timerJobs is empty. Current app creates no jobs; installed/older/manual saves cannot be verified here.
- Added 39 tests; unchanged existing tests also ran. No test skipped or assertion weakened. Initial focused test failure was a new test setup using the last campaign level while expecting level-1 cheapest-facility recovery; corrected its fixture to level 1 without changing assertions. Added separate cheapest-facility, per-level and multi-requirement counterexamples. Initial 17 analyzer brace-style findings were fixed in production code.
- Sandbox Flutter batch wrappers stalled without output while acquiring the SDK cache lock and were interrupted; direct cached Dart generated the fixture. Subsequent approved SDK-access analysis/tests actually ran with the raw results below.

## Partly done
- 4B-1 locally verified; owner review and commit/push pending. Prompt 4 as a whole is incomplete. Recipe/state receipts are in memory only, ready for the 4B-2 persistent aggregate; replacing a service in tests is not a physical app-restart persistence test.
- Salvage rescues the 26-cancellation level-1 sequence (80 → 2, shortfall grant 3 → 5) once. Repeatedly requesting recovery cannot farm a receipt; changing level while enough funds remain does not grant; optional work cannot spend restricted credit.

## Not done
- Unrescued sequences: cancel a fully salvage-funded 5-unit build (refund 2, receipt exhausted); exhaust funds with multiple missing required facilities in one level (one recovery builds cheapest battery but leaves solar/control unpaid); lack repair spare parts (outside construction salvage). Cap remains one grant/level, at most 8 units, as documented. No unconditional no-soft-lock claim; owner must decide whether to extend policy.
- No schema 3, migration, storage/controller/router wiring, UI/prologue/sim changes, package, sound, Prompt 5, commit or push. No Android build/device check. 4B-2 is gated on owner commit/push of 4B-1 and its approval.

## Files changed
- lib/progression/progression_service.dart (new); lib/progression/timer_completion.dart.
- assets/data/extra/buildings.json, research.json, timer_rules.json, crew_assignments.json, progression_rules.json only.
- test/progression_service_test.dart and progression_economy_test.dart (new); test/fixtures/pre_4b_f0a179f.json (new).
- docs/SIM_MODEL.md, DECISIONS.md, PROGRESS.md; vault/09_KNOWN_PITFALLS.md, vault/10_OPEN_QUESTIONS.md and this live log.

## Real command results

`flutter analyze` — exit 0:
```text
Analyzing base67...                                             
No issues found! (ran in 1.2s)
```

`flutter test --reporter expanded --concurrency=1` — exit 0:
```text
00:00 +0: loading H:/projects/base67/test/data_integrity_test.dart
00:00 +0: H:/projects/base67/test/data_integrity_test.dart: all bundled source and campaign data loads and validates
00:00 +1: loading H:/projects/base67/test/display_text_test.dart
00:00 +1: H:/projects/base67/test/display_text_test.dart: legacy source display text resolves to the current game title
00:00 +2: H:/projects/base67/test/display_text_test.dart: no Dart UI source contains the obsolete game name
00:00 +3: loading H:/projects/base67/test/original_pack_test.dart
00:00 +3: H:/projects/base67/test/original_pack_test.dart: original data pack files match supplied source checksums
00:01 +4: loading H:/projects/base67/test/progression_economy_test.dart
00:01 +4: H:/projects/base67/test/progression_economy_test.dart: resupply start 80, capacity 200, +10 once for levels 1-14; level 15 and replays grant nothing
00:01 +5: H:/projects/base67/test/progression_economy_test.dart: one-time catch-up is deterministic, receipted and compatible with partially claimed missions
00:01 +6: H:/projects/base67/test/progression_economy_test.dart: all 11 baseline facilities are affordable before each mission reward; total cost 62
00:01 +7: H:/projects/base67/test/progression_economy_test.dart: starting materials alone cover the baseline without mission rewards
00:01 +8: H:/projects/base67/test/progression_economy_test.dart: full storage retains grants and refunds and releases overflow when materials are spent
00:01 +9: H:/projects/base67/test/progression_economy_test.dart: repeated cancellation counterexample is rescued once at level 1 without farming
00:01 +10: H:/projects/base67/test/progression_economy_test.dart: salvage is earmarked: optional upgrades cannot spend the grant
00:01 +11: H:/projects/base67/test/progression_economy_test.dart: salvage requires no active job; queued or blocked jobs hold no crew or materials
00:01 +12: H:/projects/base67/test/progression_economy_test.dart: once-per-level salvage cannot be farmed by cancelling salvage-funded work; reports remaining dead end
00:01 +13: H:/projects/base67/test/progression_economy_test.dart: per-level salvage cap cannot rescue multiple requirements after resources were exhausted
00:01 +14: H:/projects/base67/test/progression_economy_test.dart: salvage never grants for optional research/upgrades once required facilities exist
00:01 +15: H:/projects/base67/test/progression_economy_test.dart: earmarks reject even affordable optional upgrade and research costs
00:01 +16: H:/projects/base67/test/progression_economy_test.dart: salvage reaches the configured 8-unit cap for a greenhouse shortfall
00:01 +17: H:/projects/base67/test/progression_economy_test.dart: required-construction salvage does not rescue missing repair parts
00:01 +18: H:/projects/base67/test/progression_economy_test.dart: each later level has a distinct receipt but returning to an old level does not reset it
00:01 +19: loading H:/projects/base67/test/progression_service_test.dart
00:01 +19: H:/projects/base67/test/progression_service_test.dart: provisional configuration resolves only existing facility IDs and sim research effects
00:01 +20: H:/projects/base67/test/progression_service_test.dart: config rejects non-finite, negative, fractional and over-capacity costs
00:01 +21: H:/projects/base67/test/progression_service_test.dart: config rejects unknown prerequisites, cycles, and unavailable future prerequisites
00:01 +22: H:/projects/base67/test/progression_service_test.dart: config rejects invalid timers, refunds and salvage caps
00:01 +23: H:/projects/base67/test/progression_service_test.dart: queue costs nothing, reserves no crew and starts only through explicit activation
00:01 +24: H:/projects/base67/test/progression_service_test.dart: duplicate requests and activation never deduct twice or reuse a cancelled ID
00:01 +25: H:/projects/base67/test/progression_service_test.dart: construction completes once across a replacement service and repeated completion attempts
00:01 +26: H:/projects/base67/test/progression_service_test.dart: crew exclusivity, wrong roles and target conflicts are rechecked on activation
00:01 +27: H:/projects/base67/test/progression_service_test.dart: locked, missing prerequisites and unknown facilities are blocked without costs
00:01 +28: H:/projects/base67/test/progression_service_test.dart: insufficient resources leave a blocked job unpaid and crew free
00:01 +29: H:/projects/base67/test/progression_service_test.dart: offline interval completes jobs without changing survival quantities or running simulation
00:01 +30: H:/projects/base67/test/progression_service_test.dart: rollback cannot increase remaining duration, shift deadlines or repeat completion
00:01 +31: H:/projects/base67/test/progression_service_test.dart: forward clock completes early as the accepted device-clock limitation
00:01 +32: H:/projects/base67/test/progression_service_test.dart: cancellation floors indivisible refunds, loses time and frees crew immediately
00:01 +33: H:/projects/base67/test/progression_service_test.dart: queued and blocked cancellation refund nothing; completed and missing jobs cannot cancel
00:01 +34: H:/projects/base67/test/progression_service_test.dart: research prerequisites, single activation and duplicate completion use existing IDs
00:01 +35: H:/projects/base67/test/progression_service_test.dart: upgrade applies a single tier without changing installed unit count
00:01 +36: H:/projects/base67/test/progression_service_test.dart: timed repair restores one damaged unit once and floors spare-part refund
00:01 +37: H:/projects/base67/test/progression_service_test.dart: receipts, config, jobs and collections are immutable and repeatable
00:01 +38: H:/projects/base67/test/progression_service_test.dart: shared completion guard preserves legacy ledger and rewardApplied protection
00:01 +39: H:/projects/base67/test/progression_service_test.dart: queued work rechecks changed crew membership before charging costs
00:01 +40: H:/projects/base67/test/progression_service_test.dart: fractional divisible resources refund exactly and invalid balances are rejected
00:01 +41: H:/projects/base67/test/progression_service_test.dart: completion at a shared deadline is ordered by stable job IDs
00:01 +42: H:/projects/base67/test/progression_service_test.dart: synthetic fixture was encoded by unchanged pre-4B serializer and has no app-created jobs
00:01 +43: loading H:/projects/base67/test/progression_test.dart
00:02 +43: H:/projects/base67/test/progression_test.dart: same seed produces the same deterministic sequence
00:02 +44: H:/projects/base67/test/progression_test.dart: campaign save round-trips its persistent state
00:02 +45: H:/projects/base67/test/progression_test.dart: campaign save store restores through local key-value storage
00:02 +46: H:/projects/base67/test/progression_test.dart: offline timer completion is due and reward completion is idempotent
00:02 +47: loading H:/projects/base67/test/prompt2_ui_test.dart
00:02 +47: H:/projects/base67/test/prompt2_ui_test.dart: (setUpAll)
00:02 +47: H:/projects/base67/test/prompt2_ui_test.dart: Home Base and Campaign Map fit 360dp at 1.4x text
00:03 +48: H:/projects/base67/test/prompt2_ui_test.dart: Home Base and Campaign Map fit 800dp at 1.4x text
00:03 +49: H:/projects/base67/test/prompt2_ui_test.dart: reusable cards and controls build with accessible targets
00:03 +50: H:/projects/base67/test/prompt2_ui_test.dart: CrewBean draws all roles and moods without motion when requested
00:03 +51: H:/projects/base67/test/prompt2_ui_test.dart: ModalSheet opens as a focused bottom panel
00:03 +52: H:/projects/base67/test/prompt2_ui_test.dart: all navigation screens open at 360dp with 1.4x text
00:04 +53: H:/projects/base67/test/prompt2_ui_test.dart: all navigation screens open at 1024dp with 1.4x text
00:04 +54: H:/projects/base67/test/prompt2_ui_test.dart: (tearDownAll)
00:04 +54: loading H:/projects/base67/test/prompt3_prologue_test.dart
00:04 +54: H:/projects/base67/test/prompt3_prologue_test.dart: (setUpAll)
00:04 +54: H:/projects/base67/test/prompt3_prologue_test.dart: screen and game files use shared color and typography tokens
00:04 +55: H:/projects/base67/test/prompt3_prologue_test.dart: prologue setup round-trips saved crew, site, cargo, and campaign
00:04 +56: H:/projects/base67/test/prompt3_prologue_test.dart: cargo points reject a loadout above the Level 1 budget
00:05 +57: H:/projects/base67/test/prompt3_prologue_test.dart: crew, site and cargo setup fit 360dp at 1.4x text
00:05 +58: H:/projects/base67/test/prompt3_prologue_test.dart: crew, site and cargo setup fit 1024dp at 1.4x text
00:05 +59: H:/projects/base67/test/prompt3_prologue_test.dart: expired site countdown picks randomly and stays editable
00:05 +60: H:/projects/base67/test/prompt3_prologue_test.dart: fake taps finish prologue and arrive at the persistent base
00:06 +61: H:/projects/base67/test/prompt3_prologue_test.dart: (tearDownAll)
00:06 +61: loading H:/projects/base67/test/sim/config_test.dart
00:06 +61: H:/projects/base67/test/sim/config_test.dart: (setUpAll)
00:06 +61: H:/projects/base67/test/sim/config_test.dart: simulation source excludes platform, audio, wall time and unseeded RNG
00:06 +62: H:/projects/base67/test/sim/config_test.dart: loader resolves source facts, units and provisional inputs
00:06 +63: H:/projects/base67/test/sim/config_test.dart: invalid config fails at load rather than corrupting a running engine
00:06 +64: H:/projects/base67/test/sim/config_test.dart: missing facts and incompatible units are rejected by the adapter
00:06 +65: H:/projects/base67/test/sim/config_test.dart: snapshots, config and modifier collections cannot be mutated
00:06 +66: H:/projects/base67/test/sim/config_test.dart: spare inventory does not construct a maintenance facility
00:06 +67: H:/projects/base67/test/sim/config_test.dart: (tearDownAll)
00:06 +67: loading H:/projects/base67/test/sim/determinism_test.dart
00:07 +67: H:/projects/base67/test/sim/determinism_test.dart: (setUpAll)
00:07 +67: H:/projects/base67/test/sim/determinism_test.dart: same seed, configuration and inputs give exactly the same complete trace
00:07 +68: H:/projects/base67/test/sim/determinism_test.dart: RNG state restores exactly after a split sequence
00:07 +69: H:/projects/base67/test/sim/determinism_test.dart: sol boundaries advance without drift and random checks consume a stable sequence
00:07 +70: H:/projects/base67/test/sim/determinism_test.dart: immutable snapshot continuation matches uninterrupted stepping
00:07 +71: H:/projects/base67/test/sim/determinism_test.dart: scripted event fires at its sub-tick boundary only once
00:07 +72: H:/projects/base67/test/sim/determinism_test.dart: run uses the baseline policy and stops safely instead of simulating absence
00:07 +73: H:/projects/base67/test/sim/determinism_test.dart: (tearDownAll)
00:07 +73: loading H:/projects/base67/test/sim/model_test.dart
00:07 +73: H:/projects/base67/test/sim/model_test.dart: (setUpAll)
00:07 +73: H:/projects/base67/test/sim/model_test.dart: four crew reserves last about 8.20, 9.73 and 10.18 sols without production
00:07 +74: H:/projects/base67/test/sim/model_test.dart: consumption is crew-scaled and uses source Earth-day hours
00:07 +75: H:/projects/base67/test/sim/model_test.dart: one engine tick deducts source-backed crew needs without production
00:07 +76: H:/projects/base67/test/sim/model_test.dart: partial power serves essential loads first and safely reports the deficit
00:07 +77: H:/projects/base67/test/sim/model_test.dart: heater uses source control range and cooling traces a safe pause
00:07 +78: H:/projects/base67/test/sim/model_test.dart: radiation threshold pauses without removing crew
00:07 +79: H:/projects/base67/test/sim/model_test.dart: resource trace accounts for event water and bounded storage overflow
00:07 +80: H:/projects/base67/test/sim/model_test.dart: invalid tick durations return a finite unchanged-time trace
00:07 +81: H:/projects/base67/test/sim/model_test.dart: disabled batteries retain charge but cannot discharge into a shortage
00:07 +82: H:/projects/base67/test/sim/model_test.dart: an unbuilt upgraded storage facility grants no capacity bonus
00:07 +83: H:/projects/base67/test/sim/model_test.dart: solar equation uses irradiance, area, efficiency, site, tau and dust
00:07 +84: H:/projects/base67/test/sim/model_test.dart: battery drains at night and never overcharges at noon
00:07 +85: H:/projects/base67/test/sim/model_test.dart: upgrade and research bonuses add and their order does not matter
00:07 +86: H:/projects/base67/test/sim/model_test.dart: existing storage facilities expand capacity without granting resources
00:07 +87: H:/projects/base67/test/sim/model_test.dart: powered greenhouse and miner produce at repository rates
00:07 +88: H:/projects/base67/test/sim/model_test.dart: facility state notBuilt remains finite and respects availability
00:07 +89: H:/projects/base67/test/sim/model_test.dart: facility state operating remains finite and respects availability
00:07 +90: H:/projects/base67/test/sim/model_test.dart: facility state off remains finite and respects availability
00:07 +91: H:/projects/base67/test/sim/model_test.dart: facility state damaged remains finite and respects availability
00:07 +92: H:/projects/base67/test/sim/model_test.dart: facility state underConstruction remains finite and respects availability
00:07 +93: H:/projects/base67/test/sim/model_test.dart: facility state outOfResources remains finite and respects availability
00:07 +94: H:/projects/base67/test/sim/model_test.dart: empty storage and shortages clamp, trace, pause and retain every crew member
00:07 +95: H:/projects/base67/test/sim/model_test.dart: corrupt numeric state is clamped and never escapes as NaN or infinity
00:07 +96: H:/projects/base67/test/sim/model_test.dart: load shedding disables optional production and spares essential life support
00:07 +97: H:/projects/base67/test/sim/model_test.dart: storm interpolation, dust buildup and completed cleaning use configured values
00:07 +98: H:/projects/base67/test/sim/model_test.dart: shelter reduces SEP dose, shielding reduces exposure and disabled shielding does not
00:07 +99: H:/projects/base67/test/sim/model_test.dart: repair consumes one spare once and sheltered crew cannot repair
00:07 +100: H:/projects/base67/test/sim/model_test.dart: (tearDownAll)
00:07 +100: loading H:/projects/base67/test/widget_test.dart
00:08 +100: H:/projects/base67/test/widget_test.dart: (setUpAll)
00:08 +100: H:/projects/base67/test/widget_test.dart: splash opens the preserved prologue route
00:08 +101: H:/projects/base67/test/widget_test.dart: Home Base and Campaign Map routes open
00:08 +102: H:/projects/base67/test/widget_test.dart: (tearDownAll)
00:08 +102: All tests passed!
```

`python check_data.py` from assets/data — exit 0:
```text
facts: 40 | sources: 24 | ALL OK
```

## Decisions made and provisional values added
- Recorded in DECISIONS and SIM_MODEL: approved split, economy, prerequisites, cost/timer/refund rules, 8-unit per-level salvage cap and tested limits, required-only credit accounting, explicit clocks/crew, and synthetic fixture provenance. Every new gameplay value/rule is GAME VALUE, provisional.
- Moving the device clock forward can complete timers early; accepted limit. No retroactive simulation, consumption or queued-job activation offline.
- For 4B-2 only: each state change writes one whole blob under the existing key, last good backup retained until read-back verifies; failed migration must leave the original untouched and never create a blank save. Ambiguous legacy jobs must free crew with no cost/effect and a logged exit, not silent removal.

## Conflicts found between documents
- PROGRESS still said 4A commit/push pending; corrected based on f0a179f HEAD/local origin/main and owner's instructions. Original 4A session entry retained as history. Owner split supersedes broader Prompt 4 integration in this phase.

## Open questions added to 10_OPEN_QUESTIONS.md
- Bounded salvage counterexamples and future recovery choice; 4B-2 storage/migration verification. Material source decision recorded as resolved provisionally, final balance still unverified.

## Next safe step
- Owner reviews 4B-1 and the recovery limitations, then commits/pushes if accepted. Do not start 4B-2 or Prompt 5 without approval.


## Git evidence snapshot

Captured after code, documentation, full analysis/tests and handoff content, immediately before appending these Git output blocks. Appending this evidence changes SESSION_LOG's diff-stat count; final Git output is also reported to the owner. Untracked files are listed by status but omitted by ordinary diff --stat.

`git status` — exit 0:
```text
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   assets/data/extra/buildings.json
	modified:   assets/data/extra/crew_assignments.json
	modified:   assets/data/extra/progression_rules.json
	modified:   assets/data/extra/research.json
	modified:   assets/data/extra/timer_rules.json
	modified:   docs/DECISIONS.md
	modified:   docs/PROGRESS.md
	modified:   docs/SIM_MODEL.md
	modified:   docs/vault/09_KNOWN_PITFALLS.md
	modified:   docs/vault/10_OPEN_QUESTIONS.md
	modified:   docs/vault/templates/SESSION_LOG.md
	modified:   lib/progression/timer_completion.dart

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	lib/progression/progression_service.dart
	test/fixtures/
	test/progression_economy_test.dart
	test/progression_service_test.dart

no changes added to commit (use "git add" and/or "git commit -a")
```

`git diff --stat` — exit 0:
```text
warning: in the working copy of 'base67/docs/vault/templates/SESSION_LOG.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'base67/lib/main.dart', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'base67/lib/progression/timer_completion.dart', LF will be replaced by CRLF the next time Git touches it
 base67/assets/data/extra/buildings.json         | 322 +++++++++++++++++++++++-
 base67/assets/data/extra/crew_assignments.json  | 111 +++++++-
 base67/assets/data/extra/progression_rules.json | 151 +++++++++--
 base67/assets/data/extra/research.json          | 137 +++++++++-
 base67/assets/data/extra/timer_rules.json       | 171 +++++++++++--
 base67/docs/DECISIONS.md                        |  17 ++
 base67/docs/PROGRESS.md                         |  18 +-
 base67/docs/SIM_MODEL.md                        |  33 ++-
 base67/docs/vault/09_KNOWN_PITFALLS.md          |   1 +
 base67/docs/vault/10_OPEN_QUESTIONS.md          |   7 +-
 base67/docs/vault/templates/SESSION_LOG.md      | 187 ++++++++++++++
 base67/lib/progression/timer_completion.dart    |  34 ++-
 12 files changed, 1106 insertions(+), 83 deletions(-)
```

`git diff HEAD -- assets/data ':(exclude)assets/data/extra/**'` — exit 0; raw stdout is empty:
```text

```

No untracked original-pack files were found either. Protected application/prologue/UI/sim/config-loader/dependency/existing-test diff is empty (Git prints only a line-ending warning for lib/main.dart; no change is listed). New file line counts: progression_service.dart 848; progression_service_test.dart 604; progression_economy_test.dart 383; pre_4b_f0a179f.json 1. TimerCompletion is 77 lines. All 4 new files remain untracked for owner review. No commit or push.

