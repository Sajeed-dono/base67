# 06 Game design snapshot (short; `docs/GAME_BRIEF.md` is the authority)

## Campaign: 15 levels in five chapters
| Chapter | Levels |
|---|---|
| 1 Power and Energy | 1 First Light, 2 Power Storage, 3 Energy Manager |
| 2 Martian Weather | 4 Dust on Mars, 5 The Great Storm |
| 3 Oxygen and Life Support | 6 Greenhouse Online, 7 Breathing Matters |
| 4 Radiation, Water and Food | 8 Radiation Alert, 9 Shelter Protocol, 10 Finding Water, 11 Ice Operations, 12 Food and Supplies |
| 5 Crew Management and Mission Survival | 13 Crew Care, 14 Mission Control, 15 The Final Mission |

Each level: one clear learning objective, one clear mission objective, one new concept, a short debrief. Later levels combine earlier systems. Level 15 combines everything.

## One persistent base
The Home Base screen is the actual base and campaign hub. New buildings appear on it. Buildings, upgrades, research, crew, patch and progress persist across all levels.

## Systems
Construction and upgrades, research and unlocks, crew assignments, resources (power, oxygen, water, food), repairs, forecasts and events, Mars Notebook (facts unlock gradually), badges, mission patch, Junior Astronaut certificate.

## Two clocks
- **Martian simulation time:** sols and hourly ticks. One sol length comes from the NASA fact `sol_hours`.
- **Real-world progression time:** construction, upgrades, research and repairs use saved UTC timestamps and continue while the app is closed. Timer values are GAME VALUES and provisional until the owner approves them.

## Crew roles (fixed)
Commander (Unshakable), Engineer (Technical Genius), Scientist (Keen Observer), Medic (Field Medic). The player names the crew. Role effects are game values; the exact numeric size of each effect is defined by the owner's data files, not by agents.

## Pacing and fairness
Timers never block all meaningful play. No pay-to-skip. No punishment for being offline. Failure shows what went wrong and why, then Retry.

## Prompt order (details in `docs/prompts/`)
1 Foundation, 2 Visual design, 3 Prologue and setup, 4 Simulation engine, 5 Levels 1 to 7, 6 Levels 8 to 15, 7 Progression and research, 8 QA and release.
