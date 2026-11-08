# BASE 67 Context Vault

A small, stable set of documents that every AI (and every teammate) reads before and after working on the project. Its purpose is to stop **context drift** (the project slowly changing shape between sessions) and **hallucination** (inventing files, numbers, features or test results).

## How it is organised

| File | Purpose | Changes how often |
|---|---|---|
| `00_START_HERE.md` | Before-work and after-work checklists. The entry point. | Rarely |
| `01_PROJECT_IDENTITY.md` | What BASE 67 is, who it is for, what it is not | Rarely |
| `02_HARD_RULES.md` | Rules that are never broken | Rarely, only by the owner |
| `03_TRUTH_HIERARCHY_AND_SOURCES.md` | Which document wins in a conflict; where each fact lives | Rarely |
| `04_ARCHITECTURE_MAP.md` | Intended folder layout and layering | When architecture changes |
| `05_DATA_GOVERNANCE.md` | NASA DATA / GAME VALUE / DERIVED rules and file permissions | Rarely |
| `06_GAME_DESIGN_SNAPSHOT.md` | Short summary of the 15 levels, base, timers, crew | When design changes |
| `07_ANTI_HALLUCINATION_PROTOCOL.md` | How to avoid inventing things | Rarely |
| `08_VERIFICATION_AND_DONE.md` | Commands and evidence needed to call work done | Rarely |
| `09_KNOWN_PITFALLS.md` | Mistakes already made, so they are not repeated | Grows over time |
| `10_OPEN_QUESTIONS.md` | Unresolved items and provisional values | Every session |
| `11_GLOSSARY.md` | Terms and abbreviations | Rarely |
| `META_PROMPT.md` | One paste to bring any other AI fully up to speed | When project status changes |
| `templates/` | Session handoff and session log formats | Rarely |

## Golden rules of the vault
1. **The vault points, it does not copy.** Facts that live in a data file or in `docs/GAME_BRIEF.md` are not duplicated here. A copy would eventually disagree with the original.
2. **Status lives in `docs/PROGRESS.md`, never in the vault.** The only dated snapshot is inside `META_PROMPT.md`, and it says that `PROGRESS.md` overrides it.
3. **Only the project owner changes `02_HARD_RULES.md`.** Agents may propose a change in `docs/DECISIONS.md`.
4. **Everything an agent learns the hard way goes into `09_KNOWN_PITFALLS.md` or `10_OPEN_QUESTIONS.md`.**
