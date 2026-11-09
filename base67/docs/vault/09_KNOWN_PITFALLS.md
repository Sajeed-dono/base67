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
