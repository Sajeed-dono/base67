# Session log (append newest entry at the bottom; never delete old entries)

| Date | Tool | Prompt | Result | Link to handoff notes |
|---|---|---|---|---|
| (start) | (owner) | Vault created | Vault files added to repo | n/a |
| 2026-11-08 | Codex | Prompt 2 visual reference pass | Updated Home Base and Campaign Map styling; analyzer clean; 17 tests passed | Handoff below |
| 2026-11-09 | Codex | Prompt 3 prologue and setup | Locally implemented and verified; analyzer clean; 24 tests passed; owner commit pending | Handoff below |
| 2026-11-09 | Codex | Interim Android Gradle note | Documented owner-reported cross-drive workaround and same-drive Pub-cache fallback; no build run | Handoff below |
| 2026-11-09 | Codex | Interim Android portrait lock | Added manifest and Flutter startup portrait requests; analyzer clean; 24 tests passed | Handoff below |

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
- `git diff` on original data: (to be checked after this handoff update).

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
