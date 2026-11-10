# 09 Known pitfalls (mistakes already made; do not repeat)

| # | Pitfall | What to do |
|---|---|---|
| 1 | The Git root is `H:\projects`, not the Flutter project folder | Clones contain `base67\base67`. Keep other projects out of `H:\projects`. Check paths relative to the folder you are in |
| 2 | `git ls-files base67/...` printed nothing when run inside `base67` | Paths are relative to the current folder |
| 3 | Documents were saved with doubled extensions (`.docx.docx`, `.txt.txt`) | Use the clean names in `docs/` and delete the duplicates |
| 4 | A simulation doc existed as `SIMULATION_MODEL.md` while prompts expect `SIM_MODEL.md` | The authoritative name is `docs/SIM_MODEL.md` |
| 5 | A test run hung because stale Dart processes were running | Kill `dart.exe` and `flutter_tester.exe`, rerun, and report honestly if it still hangs |
| 6 | An analyzer info lint blocked "clean analyzer" and was in the preserved prologue | Behaviour-neutral fixes are allowed; record them in `docs/DECISIONS.md` |
| 7 | `docs/reference/` was empty, so the Dribbble style was not available | Add screenshots to `docs/reference/` before visual work. The agent cannot open Dribbble pages |
| 8 | First Prompt 2 result was clean code but looked like a form app (pale colours, list instead of map, words broken mid-word) | Passing tests is not visual approval. A person reviews screenshots |
| 9 | `git push` rejected because the remote had a commit | `git pull --no-rebase`, save the merge message (Vim: `Esc`, `:wq`, Enter), then push. Never force push |
| 10 | The Android emulator crashed with a preview system image (API 37 / 16 KB page size) | Use a stable image |
| 11 | The old six-level plan exists in the original `levels.json` | Keep it read-only as reference; the 15 levels live in `campaign.json` |
| 12 | The old project name exists inside original data files | Do not edit them; show BASE 67 through `display_text.json` and keep a test that no UI string contains the old name |
| 13 | Timer and research values are not approved | Keep them provisional and logged in `docs/DECISIONS.md` |
| 14 | Agents sometimes report plans as results | Follow `07_ANTI_HALLUCINATION_PROTOCOL.md` |
| 15 | Long exact-source dialogue can overflow setup screens on narrow phones with enlarged text | Keep the wording intact, place long dialogue in a bounded scroll viewport using a shared theme spacing token, and cover phone/tablet sizes with enlarged-text widget tests |
| 16 | Owner reported an Android Gradle “different roots” failure with the project on `H:` and Pub cache on `C:` | `kotlin.incremental=false` in `android/gradle.properties` is the reported workaround; if it persists, set `PUB_CACHE` to a directory on the same drive as the project. Build behavior has not been verified in this documentation session |
| 17 | Daily crew rates are not per sol; zero storage and unavailable facilities can break naive numerical models | Convert source units in the config adapter, keep clocks explicit, and test finite clamped shortages with trace notices. Treat spare inventory separately from installed facilities |
| 18 | A capped one-time recovery grant is not proof that arbitrary cancellation/spending can never soft-lock | Test the spent-receipt and multi-requirement counterexamples; report unrescued sequences and never silently add recovery outside owner policy |
| 19 | A global maximum UTC observation can strand newly scheduled jobs years ahead after clock correction | Use the approved per-job remaining/checkpoint algorithm; record rollback without using a historical global floor to schedule new jobs |
| 20 | Cargo inventory can be counted again by an initial simulation factory | Project installed counts only; reserve/consume packed stock once and never reset existing reserves |
| 21 | An arbitrary objective/damage string is not recovery authority | Validate config-derived requirements and catalogue identities, observed damage and confirmation receipts; the current production damage catalogue is empty pending missions |
| 22 | A passing pure continuation test is described as persistent app restart durability | Service-policy work has no codec/store/wiring; reserve those claims for 4B-2 storage and device validation |
| 23 | Payment identity is mistaken for the actual damage being repaired | Bind a separate damage allocation even for ordinary payments; confirm only recorded occurrences, resolve that exact unit, retain closure receipts and never relabel unidentified repairs |
| 24 | Construction count increments but an explicit unbuilt state survives | First completion clears lifecycle-only states; preserve deliberate shutdown and existing units during expansion; reject inconsistent installed states |
| 25 | A delayed UTC sample is mistaken for a real clock rollback | Capture token and UTC together before delivery; reject old/duplicate tokens before mutation; apply the approved rollback formula only to accepted observations |
| 26 | Packed spares and available repair spares are counted twice or cannot be spent | Explicitly unpack into the canonical consumable balance once; reject ambiguous mixed ownership; never reserve spares as installation cargo |
