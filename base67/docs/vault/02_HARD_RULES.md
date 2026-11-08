# 02 Hard rules (never broken; only the project owner may change this file)

## Product rules
1. **Offline.** No network calls, web views, remote fonts or remote images at runtime. No INTERNET permission in the release manifest.
2. **Kid safe.** No crew death or graphic harm: if a crew member's health reaches zero the mission pauses and says they need help. Failure is information: always explain why and offer Retry.
3. **No manipulation.** No premium currency, paid speed-ups, ads, loot boxes, streaks or artificial urgency. No timer blocks all meaningful play. Players are never punished for being offline.
4. **One persistent base.** Buildings, research, crew, patch and progress carry across all 15 levels. A level never erases the base.
5. **Name.** The game is BASE 67.
6. **Original art.** Draw characters and scenery in code. Do not copy names, logos, characters or assets of any other game. Do not use the NASA logo or insignia; write "NASA data" as plain text.
7. **Honest labels.** The About screen says the game has not been tested with students. No outcome claims.

## Data rules
8. **Original data pack is read-only.** Do not edit any file in `assets/data/` outside `assets/data/extra/`. A checksum test guards it. New values go in new files under `assets/data/extra/` with `_meta.data_class = "GAME_VALUE"` where appropriate.
9. **No NASA number in Dart code.** Read NASA values by fact id from `nasa_data.json` through the repository.
10. **Three data classes, never mixed:** NASA DATA, GAME VALUE, DERIVED. Every displayed scientific or simulation number carries a chip with its class.
11. **Do not invent data.** If a number is missing, mark it GAME VALUE or provisional and log it in `docs/DECISIONS.md` and `10_OPEN_QUESTIONS.md`. Never present a guess as NASA data.

## Process rules
12. **One prompt at a time, in order.** Never start the next prompt. A prompt is complete only when its Definition of Done is met and `docs/PROGRESS.md` says so with real results.
13. **Evidence or silence.** Never claim tests, analysis, builds or checks passed unless you ran them in this session. Quote the real output. If a command hung or failed, say so.
14. **Prologue is preserved** until Prompt 3 explicitly changes it. Behaviour-neutral fixes only.
15. **Two clocks, never mixed.** Martian simulation time (sols, hours) and real-world progression time (construction and research timers using saved UTC timestamps) are separate.
16. **Documents are living.** `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/GAME_BRIEF.md` and `docs/SIM_MODEL.md` are updated by every prompt that changes them.
