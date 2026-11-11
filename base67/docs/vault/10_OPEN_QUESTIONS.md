# 10 Open questions and provisional values

Update this file every session. Remove an item only when it is resolved, and record the resolution in `docs/DECISIONS.md`.

| # | Item | Status | Owner | Safe default until resolved |
|---|---|---|---|---|
| 2 | Construction and research timer values | Owner-approved provisional implementation; final balance unverified | Project owner | Keep short, documented GAME VALUES; never block all play |
| 3 | Mars Notebook fact cards (`fact_cards.json` has no entries yet) | Planned for the progression prompt | Agent | Show an empty-state message; never type NASA numbers by hand |
| 4 | Human check of each NASA page against `nasa_data.json` | Open | Team | Treat NASA values as unverified until ticked |
| 5 | Meridiani latitude read as 1.95 S from a page that prints -1.95 | Open | Team | Keep, flag in the UI notes |
| 6 | Team member names, tool credits and AI credit lines in `credits.json` | TODO | Team | Leave clear TODO markers; never invent names |
| 7 | Student playtest of the game | Not done | Team | Keep the "not tested with students" label |
| 9 | Anything an agent could not verify in a session | Add here | Agent | State it plainly in the handoff |
| 10 | Prompt 3 cites `docs/source/BASE_67.pdf`, which is not found; owner to correct the vault/source reference if another canonical file is intended | Open | Project owner | Keep using `docs/source/BASE_67_Prologue_Preview.pdf`, which contains the eight-scene prologue |
| 11 | The source gives no age range for the crew setup field | Open | Project owner | Keep a positive whole number with a one- or two-digit technical limit; do not invent an age range |
| 12 | Construction material source resolved for 4B-1 | Owner-approved GAME VALUE, provisional | Project owner | Deterministic resupply 80/200/+10 for first levels 1-14; receipts/catch-up; restricted recovery supersedes bounded salvage; implementation balance remains provisional |
| 13 | 4A balance and simplified temperature/event/protection models | Provisional, unverified | Project owner | Mark every new gameplay input and response rule GAME VALUE, provisional; tests establish numerical behavior, not physical accuracy or campaign balance |
| 14 | Recovery corrections: occurrence-bound allocations independent of payment, closure, full assistance restoration and ordinary 50% refunds | Owner-approved corrections locally verified (136 tests); independent read-only review REQUIRED, not accepted | Agent / owner | Keep allocations/receipts together; no retrospective binding or durability/solvability claim |
| 15 | 4B-2 persistence and migration | Implemented locally under prior owner authorization; validation remains pending per PROGRESS | Agent / owner | Preserve existing verified-write/backup behavior; do not claim tested device durability; synthetic f0a179f fixture is not a real player save |
| 16 | Authoritative essential-damage occurrence catalogue | Combined 5+6 defines one final-mission panel strike; implementation unvalidated | Agent / owner | Require actual engine increment and validated occurrence; retain unknown-ID, allocation and entitlement safeguards |
| 17 | Transactional storage, schema 3, centralized mutations and story-only replay | Existing schema-3 controller/store implementation retained; separate database evaluation remains deferred | Agent / owner | Do not add a competing backend or claim unexecuted migration/backup tests passed |
| 18 | Habitat expansion, lab/rover dependencies and initial pacing | Still deferred; finale has explicit provisional support under the combined scope | Agent / owner | Preserve the starter habitat and existing timers; add no fictional facility costs/bonuses; calibrate the documented support separately from material resupply |
| 19 | Observation producer and authoritative external outcomes | Controller clock observations and final mission damage boundary integrated; validation pending | Agent / owner | Keep ordered UTC/token capture and actual event evidence; never reconstruct damage authority from arbitrary IDs or old counts |
| 20 | Ambiguous packed/available spare representations during future import | Rejected unchanged; provenance resolution deferred to the separately approved migration plan | Agent / owner | No automatic addition, duplication, grants or assumption that mixed stock is distinct |
| 21 | Combined campaign durations, wellbeing benefits, emergency support floors and radiation assessment windows | GAME VALUE, provisional; owner calibration/manual tests required | Agent / owner | Use the explicit extra configuration; no offline decay, silent refill, NASA medical claim or lifetime-dose erasure; preserve original prices/timers |
| 22 | Hybrid movement device/layout, crowded routes and battery/CPU review | Implementation and tests added; NOT RUN or verified | Project owner | Keep movement presentation-only, conservative exterior collision, ephemeral positions and shared styling; validate 360/tablet, Android joystick, accessibility and reduced motion manually before acceptance |

| 23 | Phase 1 fixed-world/camera/2.5D inspection acceptance | Code and regression specifications added; no tests/analyzer/builds run in this phase | Project owner | Validate pan/pinch/picking, keyboard/joystick, enlarged text, safe navigation, reference-site labels, prologue and Level 1/2 on Android; profile scene repaint cost before claiming performance or visual acceptance |

- Owner may request a visual redesign pass after the game is feature complete; all styling must stay token-based so this stays cheap.


## Master assignment follow-up (2026-11-12)

| Item | Status | Safe boundary |
|---|---|---|
| Level 1 starting-damage scenario | Owner selected "Design starting damage separately" during M2-M10 | Preserve construction-first opening. Separate design must define the actual damaged unit/occurrence, ordinary/restricted payment authority, spare ownership, pacing, recovery/retry and save compatibility before implementation. No fabricated damage or assistance. |
| M2-M10 final acceptance | Focused automated groups pass; M10 PARTIAL | Owner runs full suite/analyzer/build and reviews Android font/art/accessibility/touch, offline job/mid-mission resume, GPU/CPU/memory and pacing. No device/student-test or complete-game claim. |
