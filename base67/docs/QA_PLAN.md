# QA plan

The foundation checks cover:

- Original NASA source/fact relationships and GAME VALUE metadata.
- All 15 campaign levels, ordering, and chapter references.
- Stable seeded random sequences.
- Campaign save serialization and idempotent offline timer completion.
- The prologue entry point and an unchanged-source SHA-256 manifest for the supplied data pack.

Further QA is needed for Android release builds, screen sizes and accessibility settings, offline restart behavior on device, migrations, and student usability. The game has not been tested with students.
