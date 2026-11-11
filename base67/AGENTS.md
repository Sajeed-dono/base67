# AGENTS.md: BASE 67 (read this first)

You are a coding agent working on **BASE 67**, a kid-friendly (ages 10-14), offline, portrait-first Android Mars settlement game built with Flutter for the NASA Space Apps 2026 challenge "Build a Junior Astronaut Mission Trainer".

## Before you do anything
1. Read `docs/vault/00_START_HERE.md` and follow its BEFORE-WORK checklist. Read the vault files in the order it gives.
2. Read `docs/PROGRESS.md` (current status), `docs/DECISIONS.md` (decisions), and `docs/GAME_BRIEF.md` (source of truth for design).
3. Read `docs/BASE_67_Codex_Prompt_Sequence.txt` as the authoritative master implementation sequence. Follow its global rules and supplemental prompts. Work on exactly ONE prompt or supplemental prompt explicitly named by the user. Never start the next prompt without authorization. Do not treat older prompt files in `docs/prompts/` as overriding this master document.

## Always
- Keep the working prologue unless the approved prompt says to change it.
- Never edit the original data pack in `assets/data/` (outside `assets/data/extra/`). New values go in `assets/data/extra/`.
- Never type a NASA number into Dart code. Read it by fact id.
- Never say tests, analysis or a build passed unless you actually ran them in this session. Quote real results.
- If something is not in the repo or the vault, say "not found". Do not guess or invent.
- The game name is BASE 67. Never use the old project name in the app, UI, docs titles or release.

## After you finish
Follow the AFTER-WORK checklist in `docs/vault/00_START_HERE.md`: update `docs/PROGRESS.md` and `docs/DECISIONS.md`, add a session entry using `docs/vault/templates/SESSION_HANDOFF_TEMPLATE.md`, and report honestly, including anything incomplete.
