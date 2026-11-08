# 08 Verification and definition of done

Run from the Flutter project folder (the one with `pubspec.yaml`).

## Commands
```
flutter analyze
flutter test
git status
git diff --stat
```
If data files were touched, also run `python check_data.py` inside `assets/data/` (expect `ALL OK`).
For a visual check: `flutter run -d chrome` with the window about phone width.

If Dart processes hang a test run on Windows: `taskkill /F /IM dart.exe` and `taskkill /F /IM flutter_tester.exe`, then run again.

## A prompt is DONE only if all of these are true
1. Every item in that prompt's own "Definition of Done" is met, with evidence.
2. `flutter analyze` reports no issues (real output).
3. `flutter test` passes (real count).
4. No original data file changed (checksum test passes; `git diff` shows nothing in `assets/data/` outside `extra/`).
5. The prologue still runs unless the prompt changed it on purpose.
6. `docs/PROGRESS.md` and `docs/DECISIONS.md` are updated honestly, including anything incomplete.
7. The work is committed and pushed by the owner.

## What tests do NOT prove
Passing tests at several screen sizes show that layouts do not break. They do not show that the screens look good or that kids understand them. A person must look at the screens. Say so in reports.

## Reporting format
State: what was done, what was not, files changed, real command output, open questions. Never present partial work as complete.
