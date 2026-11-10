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
| 15 | 4B-2 persistence and migration | Not started; 4B-1 push verified; gated on follow-up review and separate architecture approval | Agent / owner | One whole primary blob write, preserve last good backup until verified; failed migration leaves original untouched; synthetic f0a179f fixture is not a real player save |
| 16 | Authoritative essential-damage occurrence catalogue | Empty in production; synthetic entries tested | Agent / owner | Define mission-owned occurrences before eligible repair scenarios; unknown caller IDs and unidentified damage grant nothing |
| 17 | Transactional storage, schema 3, centralized mutations and story-only replay | Separate evaluation/plan authorized, implementation not authorized | Agent / owner | Keep current schema/store/app/prologue untouched; retain known replay risk until 4B-2 |
| 18 | Habitat expansion effects, finale supply mechanics, lab/rover dependencies and tutorial duration | Approved directions; numerical/content details pending their prompt plans | Agent / owner | No arbitrary bonuses, new costs, silent reserves or invented mission content |
| 19 | Future observation producer and authoritative external outcomes | Unwired contract only; integration not authorized | Agent / owner | Capture ordered UTC/token pairs before delivery; retain ordering across future restores; submit actual occurrence transitions and already-paid field outcomes; never reconstruct authority from raw counts |
| 20 | Ambiguous packed/available spare representations during future import | Rejected unchanged; provenance resolution deferred to the separately approved migration plan | Agent / owner | No automatic addition, duplication, grants or assumption that mixed stock is distinct |

- Owner may request a visual redesign pass after the game is feature complete; all styling must stay token-based so this stays cheap.
