# 10 Open questions and provisional values

Update this file every session. Remove an item only when it is resolved, and record the resolution in `docs/DECISIONS.md`.

| # | Item | Status | Owner | Safe default until resolved |
|---|---|---|---|---|
| 2 | Construction and research timer values | Provisional, not approved | Project owner | Keep short, documented GAME VALUES; never block all play |
| 3 | Mars Notebook fact cards (`fact_cards.json` has no entries yet) | Planned for the progression prompt | Agent | Show an empty-state message; never type NASA numbers by hand |
| 4 | Human check of each NASA page against `nasa_data.json` | Open | Team | Treat NASA values as unverified until ticked |
| 5 | Meridiani latitude read as 1.95 S from a page that prints -1.95 | Open | Team | Keep, flag in the UI notes |
| 6 | Team member names, tool credits and AI credit lines in `credits.json` | TODO | Team | Leave clear TODO markers; never invent names |
| 7 | Student playtest of the game | Not done | Team | Keep the "not tested with students" label |
| 9 | Anything an agent could not verify in a session | Add here | Agent | State it plainly in the handoff |
| 10 | Prompt 3 cites `docs/source/BASE_67.pdf`, which is not found; owner to correct the vault/source reference if another canonical file is intended | Open | Project owner | Keep using `docs/source/BASE_67_Prologue_Preview.pdf`, which contains the eight-scene prologue |
| 11 | The source gives no age range for the crew setup field | Open | Project owner | Keep a positive whole number with a one- or two-digit technical limit; do not invent an age range |
| 12 | 4B construction materials: mission resupply, production, or both? | Open for 4B | Project owner | Propose deterministic mission resupply initially; no material source, costs or refunds implemented in 4A; costs only for existing facility IDs |
| 13 | 4A balance and simplified temperature/event/protection models | Provisional, unverified | Project owner | Mark every new gameplay input and response rule GAME VALUE, provisional; tests establish numerical behavior, not physical accuracy or campaign balance |

- Owner may request a visual redesign pass after the game is feature complete; all styling must stay token-based so this stays cheap.
