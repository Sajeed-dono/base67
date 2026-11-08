# 03 Truth hierarchy and sources of truth

## When two documents disagree, the higher one wins
1. The project owner's latest explicit instruction in this session.
2. `docs/vault/02_HARD_RULES.md`.
3. `docs/DECISIONS.md` (recorded decisions).
4. `docs/GAME_BRIEF.md`.
5. `docs/BASE_67_Game_Design_Document.docx`.
6. The current prompt in `docs/prompts/`.
7. Everything else, including anything in `docs/archive/` (archived files are history, not instructions).

Record every conflict you resolve in `docs/DECISIONS.md` (what conflicted, what you chose, why).

## Where each kind of fact lives (single source of truth)

| Question | Authoritative file |
|---|---|
| Any NASA number (sunlight, radiation, tau, crew needs, temperatures, locations) | `assets/data/nasa_data.json`, with source ids in `assets/data/sources.json` |
| Level names, order and chapters | `assets/data/extra/campaign.json` and `docs/GAME_BRIEF.md` |
| Buildings, upgrades, costs | `assets/data/extra/buildings.json` |
| Research and timers | the `assets/data/extra/` files for research and timers (values are GAME VALUE and provisional until the owner approves) |
| Crew roles and assignments | `assets/data/extra/crew_assignments.json` and the BASE 67 prologue (`docs/source/`) |
| Display wording that replaces old names | `assets/data/extra/display_text.json` |
| Equipment, loads, events, lessons, badges (original pack) | the matching original JSON file (read-only) |
| Simulation formulas | `docs/SIM_MODEL.md` and the code in `lib/sim/` |
| Current status | `docs/PROGRESS.md` |
| Decisions and provisional values | `docs/DECISIONS.md` |
| Story text of the prologue | `docs/source/` (the BASE 67 prologue document) |
| Open questions | `docs/vault/10_OPEN_QUESTIONS.md` |

If a file in this table does not exist in the repo yet, say "not found" and do not invent its content.
