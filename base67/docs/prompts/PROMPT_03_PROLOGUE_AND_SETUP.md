<!-- Paste this prompt into Codex ONLY after the vault load message (docs/vault/00_START_HERE.md) and only when the previous prompt is verified complete in docs/PROGRESS.md. -->

# PROMPT 3 OF 8 — PROLOGUE, CREW CREATION, LANDING SITE AND FIRST BASE SETUP

First read `docs/GAME_BRIEF.md`, `docs/PROGRESS.md`, and `docs/DECISIONS.md`. This is step 3 of 8. Integrate the existing prologue with the new persistent-base campaign.

## A. Preserve the story

Use `docs/source/BASE_67.pdf` as the source for the eight original prologue scenes, if present:

1. The Last Year
2. The Calling
3. Your Crew
4. Four Possible Worlds
5. Every Kilogram Counts
6. The Final Goodbye
7. Departure
8. Touchdown

Preserve the agreed story wording and sequence. Do not invent a different story or remove the previous Mars mission mystery. Keep typewriter text, tap-to-continue, and Skip where already implemented. If the source PDF is unavailable, report that and preserve the existing working prologue rather than inventing exact source wording.

## B. Re-skin the eight scenes

Use the new theme, Dave bubble, vector scenery, and original astronaut art. Add restrained painted animations for news static, rocket launch, Mars approach, and touchdown. Reduced-motion mode must show still scenes.

## C. Crew creation

Provide four slots, one for each role:
- Commander
- Engineer
- Scientist
- Medic

Allow the player to choose:
- Name.
- Age, if this field remains in the approved story.
- Suit colour.
- Visor tint.
- Cosmetic face style.

Show a live CrewBean preview. Names must be validated. Provide a random-name option. Preserve the role traits and status-line templates from the original crew data. Do not change the crew's roles to generic classes.

## D. Landing site choice

Show all four sites:
- Gale — EASY
- Arcadia — MEDIUM
- Deuteronilus — HARD
- Equatorial — EXTREME

Show source-backed latitude/longitude and relevant science information with correct data chips. Show sunlight and ice information only where the data pack supports it. Show GAME VALUE terrain risk separately from NASA facts. Explain that the site choice affects the base's starting conditions and future resource strategy.

If the original story requires a countdown, preserve it as a narrative choice mechanic, but do not make the player lose progress or suffer a punitive outcome for taking time to read. A random selection on expiry is acceptable only if it is clearly explained and can be changed before confirmation.

## E. Cargo and initial base setup

Use cargo points, not kilograms, for the initial equipment budget. Keep original equipment costs and constraints read-only. The initial loadout should contain only items permitted by the original Level 1 equipment rules. Show unavailable equipment as locked and explain when it becomes available.

The player is establishing the first version of the persistent base. The starting equipment becomes part of the base inventory and is not discarded at the end of the prologue.

Show a live preview of any derived solar output and battery capacity with formula explanations.

## F. Mission state and save system

Create a persistent `MissionState` or equivalent containing:
- Crew and their chosen names/appearance.
- Selected landing site.
- Starting cargo and inventory.
- Persistent base facilities and upgrade levels.
- Resource stores and capacities.
- Research state.
- Construction and repair jobs.
- Campaign unlocks and completed levels.
- Mission patch and player display name.
- Deterministic seed and relevant event history.
- Save schema version.

Save locally and restore on app restart. Provide a safe reset with confirmation. The prologue can be replayed from Settings without erasing the campaign.

## G. First arrival

After touchdown, transition into the Home Base screen. Show the landing craft, initial habitat/landing equipment, crew, and the first available objective: **First Light**. The player must recognize that this is the beginning of one base that will grow throughout the game.

## H. Definition of done

- Mission state save/load round trip passes.
- Cargo over-budget validation works.
- Site selection persists.
- Prologue can be completed with fake taps in a widget/integration test.
- Completing the prologue lands on the persistent Home Base with Level 1 available.
- Replaying the prologue does not reset campaign data.
- `flutter analyze` clean.
- Update progress and decisions.
