<!-- Paste this prompt into Codex ONLY after the vault load message (docs/vault/00_START_HERE.md) and only when the previous prompt is verified complete in docs/PROGRESS.md. -->

# PROMPT 7 OF 8 — BASE PROGRESSION, RESEARCH, TIMERS, REWARDS, NOTEBOOK AND SETTINGS

First read `docs/GAME_BRIEF.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`, and `docs/SIM_MODEL.md`. This is step 7 of 8. Complete the long-term progression systems that make the persistent base meaningful.

## A. Base construction and upgrades

Implement a clear Build interface:
- Available buildings.
- Locked buildings and their unlock requirements.
- Construction cost.
- Construction duration.
- Required materials or resources.
- Facility purpose and benefit.
- Current level and next upgrade.
- Active construction queue.
- Crew member assignment if relevant.

Facilities may include:
- Solar arrays.
- Battery storage.
- Habitat modules.
- Greenhouse.
- Oxygen/life-support systems.
- Radiation shielding.
- Ice extraction facility.
- Water storage.
- Food storage.
- Workshop/maintenance bay.
- Research laboratory.
- Communications.
- Rover and charging station.
- Medical and crew-support facilities.

Only implement buildings that have a meaningful gameplay purpose. Avoid creating decorative facilities that add complexity without a learning benefit.

## B. Upgrade progression

Each upgrade must explain:
- What improves.
- What it costs.
- How long it takes.
- Whether it increases capacity, efficiency, resilience, or unlocks a feature.
- Whether it introduces a new trade-off.

Do not make upgrades mandatory merely to increase playtime. Balance each level so that the player has a fair path forward.

## C. Research tree

Build a visual research tree with clear prerequisites and outcomes. Suggested branches:
- Solar energy and batteries.
- Dust protection and maintenance.
- Life support and oxygen.
- Radiation protection.
- Water extraction.
- Sustainable agriculture.
- Crew health and settlement operations.

Use the research durations from configuration, not hard-coded values. Research can continue while the app is closed. Show the Scientist's contribution as a meaningful optional advantage.

## D. Timer and offline progression UI

Show:
- Current job.
- Progress.
- Remaining time.
- Expected unlock or result.
- Assigned crew member, if any.
- Queue position, if applicable.

When a job finishes while the app is closed, show a calm completion notice on the next visit. Do not use push notifications unless the user explicitly approves a local notification feature and its permissions are appropriate.

No paid speed-ups, ad gates, premium currency, loot boxes, daily streaks, or punitive deadlines. Never make children feel that they are losing their base by not returning.

## E. Crew management

Provide a Crew screen showing:
- Each astronaut's role and trait.
- Current assignment.
- Availability.
- Resting or recovery state.
- Relevant status indicators.
- Task options and durations.
- Simple explanations of role advantages.

Do not require constant tapping or micromanagement. Use sensible defaults and clear assignment feedback.

## F. Campaign map and rewards

Complete the 15-node map and five chapter progression. Implement badges from `badges.json` where applicable, and add new campaign badges only in the extra data layer.

Include:
- Level completion states.
- Stars or mission ratings.
- Chapter completion.
- Campaign progress indicator.
- Mission patch editor.
- Badge collection.
- Junior Astronaut certificate after Level 15.

The certificate must be a game completion reward, not a real-world qualification or NASA endorsement.

## G. Mars Notebook

Create progressive fact cards for:
- Sunlight.
- Solar power.
- Batteries.
- Dust and storms.
- Oxygen.
- Radiation.
- Shielding.
- Water ice.
- Food and greenhouse systems.
- Temperature.
- Gravity.
- A day/sol on Mars.
- Crew and settlement operations where reliable sources support the content.

Each card should:
- Use age-appropriate language.
- Pull NASA values by fact ID.
- Show the correct data chip.
- Show unit and source information.
- Include a Source button with source title and URL displayed as text for offline use.
- Never leave an unresolved template placeholder.

## H. Settings, About and Credits

Settings:
- Sound on/off.
- Text size.
- Colour-blind-safe palette.
- Reduce motion.
- Replay prologue.
- Reset campaign with confirmation.
- Hints always on.
- Optional simulation speed preference if supported.

About:
- Explain NASA DATA vs GAME VALUE vs DERIVED.
- Include “Not yet tested with students.”
- Explain that BASE 67 is an educational game project and not an official NASA product.
- Use credits from the source data.

Credits:
- Read team names and AI tools from a single editable team configuration file.
- Show TODO placeholders clearly in debug builds.
- Do not invent team member names or claim unverified contributions.

## I. Save system and migration

Persist:
- Campaign progress.
- Base facilities and upgrades.
- Resources.
- Construction and repair jobs.
- Research jobs and completed research.
- Crew and assignments.
- Level results.
- Badges and patch.
- Notebook unlocks.
- Settings.
- Timer timestamps.
- Save version.

Implement safe migrations. Test old-save compatibility or provide a safe reset path if no old save format exists yet.

## Definition of done

Tests cover every badge rule, research prerequisite, building unlock, timer persistence, offline completion, save migration, notebook template, settings persistence, and certificate unlock. `flutter analyze` clean. Update progress and documentation.
