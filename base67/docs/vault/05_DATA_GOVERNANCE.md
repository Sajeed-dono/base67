# 05 Data governance

## The three classes
| Class | Meaning | Where it comes from | On-screen chip |
|---|---|---|---|
| NASA DATA | A value read on a NASA page | `nasa_data.json` with source ids from `sources.json` | NASA DATA |
| GAME VALUE | A design choice of the team | all other JSON files and `assets/data/extra/` | GAME VALUE |
| DERIVED | Our formula applied to NASA numbers (for example panel peak power, site sunlight from latitude) | computed in code or documented in `docs/SIM_MODEL.md` | DERIVED |

## Permissions
| Action | Allowed? |
|---|---|
| Read any data file | Yes |
| Edit an original data pack file | **No.** The checksum test must keep passing |
| Add a new file under `assets/data/extra/` | Yes, with a `_meta` block and the right `data_class` |
| Add a NASA fact | Only from a real NASA page: add a fact with value, unit and source ids, add the source to `sources.json`, and flag it for human verification in `10_OPEN_QUESTIONS.md`. **Never from memory.** |
| Type a NASA number in Dart | **No.** Use the fact id |
| Present a GAME VALUE as NASA data | **Never** |

## Known facts about the pack (verify before use)
- The pack has 40 NASA facts and 24 NASA sources; `python check_data.py` should print `ALL OK`.
- NASA pages were read through a summarising tool, so a human must open each page and confirm the numbers before submission.
- The game's radiation limit and the size of a solar particle event spike are game values, not NASA values. Never call the limit a NASA limit.
- Meridiani latitude is printed as -1.95 on its NASA page and read as 1.95 S. It is still to be confirmed on another NASA page.

## Credits and logos
Credits come from `credits.json`. Never use the NASA logo. Any AI use and any third-party asset must be recorded.
