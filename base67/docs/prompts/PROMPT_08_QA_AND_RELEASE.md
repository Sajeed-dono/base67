<!-- Paste this prompt into Codex ONLY after the vault load message (docs/vault/00_START_HERE.md) and only when the previous prompt is verified complete in docs/PROGRESS.md. -->

# PROMPT 8 OF 8 — FULL QA, ACCESSIBILITY, OFFLINE PROOF, BALANCING AND ANDROID RELEASE

First read `docs/GAME_BRIEF.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/SIM_MODEL.md`, and all QA documents. This is the final development step.

## A. Full campaign review

Test the entire 15-level campaign from a fresh save:
- Complete the prologue.
- Establish the initial base.
- Complete each level in order.
- Verify the same base persists.
- Verify construction and research unlocks.
- Verify offline timer progress.
- Verify resource continuity and mission transitions.
- Complete the final mission.
- Unlock the certificate.

Record actual test results. Do not invent playtest results or claim that the game has been tested with children if it has not.

The older 30–45 minute estimate applied to the original six-level prototype and is no longer a valid target for the expanded game. Measure the new campaign honestly. Report:
- Active gameplay time.
- Real-world elapsed time including optional construction/research timers.
- Typical session length from internal test runs.
- Any level that is too short, too long, confusing, or blocked by a timer.

Do not inflate playtime with empty waiting. A longer campaign should contain meaningful learning and decisions, not artificial delay.

## B. Balance and fairness audit

Check:
- Every level has a clear objective.
- The player has a fair path to completion.
- No required facility or research is hidden behind an impossible timer.
- No resource can silently reach an unrecoverable state.
- The player can understand why a resource is rising or falling.
- Random events are seeded and fair.
- Crew roles are useful but not mandatory for every small action.
- Optional timers do not block all meaningful play.
- Returning after several days does not cause a disaster.
- The persistent base is never accidentally reset.
- Retry and replay do not corrupt campaign state.

Tune GAME VALUE files only. Never alter the original NASA data to make the game easier.

## C. Child-friendliness audit

- Review all on-screen text for reading level and clarity.
- Shorten long instructions.
- Avoid fear-based urgency.
- Avoid graphic harm and death language.
- Ensure that crew members are never permanently lost.
- Ensure there are no manipulative streaks or punitive absence mechanics.
- Explain timers and resource costs before confirmation.
- Confirm that the player can always find the next objective.
- Ensure the game does not claim official NASA endorsement or certification.

## D. Accessibility

- Tap targets at least 48 dp.
- Text scaling works at 1.4x without overflow.
- Colour-blind mode preserves meaning through icons and labels.
- Reduced motion disables looping and non-essential animation.
- Semantics labels exist for interactive controls, meters, timers, and map nodes.
- Ensure the game remains usable on small Android screens.

## E. Offline proof

- Search the codebase for network requests, WebViews, remote assets, and network dependencies.
- Confirm the release manifest does not request INTERNET permission.
- Test in airplane mode.
- Confirm all data, images, fonts, and game logic are bundled.
- Document the test in `docs/QA_REPORT.md`.

## F. Performance

- Profile on an Android emulator and, if available, a physical Android device.
- Target smooth 60 fps on the base and mission screens.
- Test fast simulation speeds and active weather effects.
- Cache painters and avoid rebuilding the entire base on every tick.
- Ensure timers and background/foreground transitions do not cause UI freezes.

## G. Data integrity

- Run the Dart data validator.
- Run the original `check_data.py`.
- Confirm all NASA fact IDs and source IDs resolve.
- Confirm all new design values are labelled GAME VALUE.
- Confirm all derived values have documented formulas.
- Use Git to verify that original files under `assets/data/` were not modified.
- Record the actual outputs in `docs/QA_REPORT.md`.

## H. Android release

- App display name: **BASE 67**.
- Do not use “Outpost Zero” in the app name or release identity.
- Use the approved package ID already in the project unless a documented change is necessary.
- Portrait-first layout.
- Appropriate minimum SDK for the installed Flutter stable version.
- Create an original app icon or use an owned vector asset.
- Document release signing steps without exposing signing secrets.
- Run `flutter build apk --release`.
- Report the real APK path and file size.

## I. Documentation and submission pack

Update:
- `README.md`
- `docs/GAME_BRIEF.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `docs/SIM_MODEL.md`
- `docs/QA_REPORT.md`
- `docs/KNOWN_LIMITATIONS.md`
- `docs/PLAYTEST_PLAN.md`
- `docs/SUBMISSION_CHECKLIST.md`

The playtest plan must include a script for children aged 10–14, tasks, observations, questions, and an empty results table. Do not invent results.

The submission checklist should include source verification, credits, screenshots to capture, team details still needing human input, and any remaining NASA data checks.

## J. Final report

At the end, report:
1. What is complete.
2. What tests were run and their actual results.
3. Whether the 15-level campaign was completed in testing.
4. Whether the persistent base and offline timers passed testing.
5. Whether the release APK built, with actual path and size.
6. Known limitations and unresolved decisions.
7. Any tasks that still require a human.

Do not claim a test passed unless it was actually run and passed.

## Final definition of done

`flutter analyze` is clean. All available automated tests pass. The full 15-level campaign has been tested as far as the current implementation allows. Offline behaviour is verified. The release APK builds. Documentation reports real results only.

---

# IMPORTANT GLOBAL RULES FOR CODEX

These apply to all eight prompts:

1. **BASE 67 is the only current game name.** Do not use the obsolete working title “Outpost Zero.”
2. **One persistent Mars base across all 15 levels.** Do not create a separate disposable base for every level.
3. **Keep the original data pack read-only.** New design values belong in `assets/data/extra/`.
4. **Separate NASA DATA, GAME VALUE, and DERIVED values.** Never present a design assumption as a NASA fact.
5. **Keep Martian simulation time separate from real-world construction/research timers.**
6. **Offline progression must be safe and fair.** No punishment for closing the app or not returning.
7. **Do not use monetisation pressure.** No paid speed-ups, ad gates, premium currency, loot boxes, or manipulative streaks.
8. **Keep the game suitable for ages 10–14.** Explain concepts simply and introduce them progressively.
9. **Preserve the existing prologue and story unless a specific, documented change is approved.**
10. **Do not silently invent NASA facts, sources, team names, test results, or student learning outcomes.**
11. **Use tests for every important mechanic.** Especially persistence, deterministic simulation, timers, offline completion, campaign progression, and resource balancing.
12. **Update project documentation after every prompt.** Codex must leave the repository in a state that the next prompt can understand.
