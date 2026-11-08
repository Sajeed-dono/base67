# 00 START HERE

## BEFORE-WORK checklist (do all of it, in order)
1. Read this vault in this order: `01` to `08`, then `09`, `10`, `11` as needed.
2. Read `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/GAME_BRIEF.md`.
3. Confirm which single prompt (`docs/prompts/PROMPT_0N_*.md`) the user has asked for. If the user has not named one, ask. Do not guess.
4. Confirm the previous prompt is marked complete in `docs/PROGRESS.md` with real test results. If it is not, say so and stop.
5. Inspect the real repository. List the files you will touch. Do not assume a file exists because a document mentions it.
6. State in 5 lines or fewer: the prompt you will do, the files you expect to change, the rules most relevant to it, any conflict you found between documents, and anything you cannot verify.
7. Wait for the user's go-ahead if they asked for a plan first.

## DURING work
- Stay inside the prompt's scope. If you notice something outside it, add it to `docs/vault/10_OPEN_QUESTIONS.md` instead of fixing it.
- Preserve the prologue and the original data pack (see `02_HARD_RULES.md`).
- Make small, reviewable changes. Prefer extending existing code to rewriting it.
- When two sources disagree, use `03_TRUTH_HIERARCHY_AND_SOURCES.md`, record the conflict in `docs/DECISIONS.md`, and continue.

## AFTER-WORK checklist (do all of it, in order)
1. Run `flutter analyze` and `flutter test` (and `python check_data.py` from `assets/data/` if data files were touched). Copy the real output.
2. Run `git status` and `git diff --stat`. Confirm that no original data file changed and that only expected files changed.
3. Update `docs/PROGRESS.md`: what is done, what is partial, what is not started, with evidence. Mark the prompt complete only if its Definition of Done is met.
4. Update `docs/DECISIONS.md` with every choice you made and every provisional value you added.
5. Add anything unresolved to `docs/vault/10_OPEN_QUESTIONS.md`. Add any new lesson to `docs/vault/09_KNOWN_PITFALLS.md`.
6. Write a handoff using `templates/SESSION_HANDOFF_TEMPLATE.md` and append it to `docs/vault/templates/SESSION_LOG.md`.
7. Report to the user: done, not done, files changed, real test results, open questions. Do not start the next prompt.
