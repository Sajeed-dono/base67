<!-- Paste this prompt into Codex ONLY after the vault load message (docs/vault/00_START_HERE.md) and only when the previous prompt is verified complete in docs/PROGRESS.md. -->

# PROMPT 6 OF 8 — LEVELS 8–15, CREW SPECIALISATION, EVENTS AND FULL SETTLEMENT MANAGEMENT

First read `docs/GAME_BRIEF.md`, `docs/PROGRESS.md`, `docs/SIM_MODEL.md`, `docs/DECISIONS.md`, and all relevant campaign data. This is step 6 of 8. Implement the remaining campaign and integrate all previously learned systems.

## A. Crew role specialisation

Create or complete the GAME VALUE crew assignment configuration. Each crew member can perform one assigned task at a time. Unassigned crew members rest or remain available.

### Commander — Unshakable
- Set power and mission priorities.
- Coordinate crew tasks.
- Rally the crew and support morale.
- Review mission readiness.

### Engineer — Technical Genius
- Construct and upgrade facilities.
- Repair damaged systems.
- Clean solar panels.
- Perform maintenance.
- Any speed bonus must be a documented GAME VALUE and must not make other crew roles irrelevant.

### Scientist — Keen Observer
- Research technology.
- Scan for ice.
- Study weather and storm forecasts.
- Interpret scientific readings.
- Survey actions must have understandable time/cost trade-offs.

### Medic — Field Medic
- Check crew condition.
- Support recovery.
- Run shelter and safety drills.
- Help manage health and morale.

Every role must matter in the campaign. No role should be permanently required for every action. Provide alternatives when a crew member is busy.

## B. Crew wellbeing

Track only the crew indicators that contribute meaningfully to gameplay, such as:
- Health.
- Morale.
- Temperature comfort.
- Fatigue or workload.

These are GAME VALUE simulation systems, not NASA medical claims. Keep the UI understandable. Do not overcomplicate the game with too many simultaneous bars.

If a crew member needs help:
- Use clear, non-graphic language.
- Pause or soften the relevant challenge if needed.
- Explain the cause and possible response.
- Never show death or permanent crew loss.
- Never punish the player because the app was closed.

## C. Remaining levels

### Level 8 — Radiation Alert
Learning: Mars has a radiation environment that must be monitored.
New system: radiation meter and exposure awareness.
Goal: understand accumulated exposure and identify when precautions are needed.
Use NASA data with clear source labels. Do not present game thresholds as NASA safety limits.

### Level 9 — Shelter Protocol
Learning: shielding and shelter can reduce radiation exposure.
New systems: shielding facility/upgrades and shelter procedure.
Goal: prepare the base and respond correctly to a radiation warning or solar particle event.

### Level 10 — Finding Water
Learning: water ice is not equally accessible everywhere; site selection and scientific surveys matter.
New system: ice survey and evidence-based site/resource planning.
Goal: use the Scientist's survey and available site information to identify a viable water strategy.
Do not claim certainty beyond the source data.

### Level 11 — Ice Operations
Learning: finding ice is different from extracting, storing, and managing water.
New system: ice miner, extraction capacity, and water storage.
Goal: establish a water supply and maintain the required reserve.

### Level 12 — Food and Supplies
Learning: food must be produced, stored, and consumed over time.
New system: food storage and supply planning, integrated with greenhouse production.
Goal: maintain a suitable food reserve and understand the limits of local production.

### Level 13 — Crew Care
Learning: a settlement depends on both machines and people.
New system: crew wellbeing, work/rest assignments, temperature comfort, and medical support.
Goal: keep all crew members in a safe, workable condition while maintaining the base.

### Level 14 — Mission Control
Learning: long missions require forecasting, maintenance, research, and planning ahead.
New system: integrated forecasts, maintenance planning, research priorities, and multi-system coordination.
Goal: prepare the base for a sequence of known and possible challenges.
Do not introduce an unrelated new science concept; combine existing systems.

### Level 15 — The Final Mission
Learning: apply the full set of junior astronaut skills to manage a functioning Mars base.
New system: no major new mechanic. This is the integrated final assessment.
Combine:
- Energy generation and storage.
- Load management.
- Dust and storms.
- Greenhouse and oxygen.
- Radiation and shelter.
- Water and ice extraction.
- Food and storage.
- Crew health, morale, and assignments.
- Construction, research, repair, and forecasts.
- Event response and resource planning.

The final mission should be challenging but fair. Provide enough warning and information for a thoughtful player to prepare. Do not make success depend on random luck.

## D. Events

Each event must:
- Have a warning where appropriate.
- Have an understandable visual cue.
- Explain what changed.
- Explain one way the player could prepare or respond.
- Be reproducible with the same seed.
- Avoid unfair clustering of negative events.
- Never cause permanent crew loss.

Use the existing event data where it applies. Add new event definitions only in the extra data layer. Keep NASA measurements separate from stylized game events.

## E. Persistent base integration

Verify that all 15 levels operate on the same base state:
- Facility ownership and upgrade levels persist.
- Research unlocks persist.
- Resource stores persist or are adjusted by explicitly documented mission transitions.
- Crew and assignments persist.
- Site conditions persist.
- Damage and repairs persist.
- Campaign progress persists.
- The player can revisit completed levels for practice without destroying current campaign progress.

If a level uses a special scenario snapshot, store it separately and merge only explicitly defined rewards or consequences back into the persistent base. Never silently overwrite the live base.

## F. Final mission and Junior Astronaut progression

Completing Level 15 unlocks the final certificate. The certificate should reflect campaign completion, not claim official NASA accreditation. Use wording such as “BASE 67 Junior Astronaut Mission Trainer — Campaign Completed.” Do not imply that NASA has certified the player.

## Definition of done

All 15 levels are playable and integrated with the persistent base. Tests cover crew actions, events, level unlocks, state persistence, revisiting levels, and the final mission. Reference strategies can complete the campaign. Naive strategies produce understandable feedback. `flutter analyze` clean. Update all design and progress documentation.
