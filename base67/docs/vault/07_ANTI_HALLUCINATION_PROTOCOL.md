# 07 Anti-hallucination protocol

## The seven rules
1. **Look before you claim.** Before saying a file, class, function, route or test exists, open it or search for it. If you did not find it, write "not found". Do not describe code you have not read.
2. **Quote with a location.** When you rely on a document or code, name the file (and section or line). If you cannot point to it, you do not know it.
3. **No invented numbers.** NASA numbers come only from `nasa_data.json`. Game numbers come only from `assets/data/extra/` files or are added there as new provisional GAME VALUES with a note. Never write a number into prose or code from memory.
4. **No invented results.** Never state that `flutter analyze`, `flutter test`, a build, a data check or a run passed unless you ran it in this session. If something hung or you interrupted it, report exactly that.
5. **Separate fact, inference and guess.** Mark each clearly. A guess must say it is a guess and why.
6. **When sources disagree, do not blend them.** Use `03_TRUTH_HIERARCHY_AND_SOURCES.md`, record the conflict, and say which one you followed.
7. **Missing context means ask or park it.** If the answer is not in the repo or vault, ask the owner or add it to `10_OPEN_QUESTIONS.md` with a safe default. Do not fill the gap with a plausible story.

## Red-flag phrases (stop and re-check if you are about to write them)
- "As expected, the tests pass" (without running them)
- "This should already exist" (check)
- "NASA says ..." (cite the fact id and source id)
- "Everything is complete" (list the evidence)
- "I updated the docs" (name the files and the lines)

## Anti-drift rules
- Do not rename, move or restructure files unless the prompt says to.
- Do not change the game's scope, level count, name, audience or tone.
- Do not "improve" game balance silently. Balance values are provisional and owner-approved.
- Do not reintroduce anything from `docs/archive/`.
- Each session starts by re-reading the vault, because memory of earlier sessions is not trustworthy.
