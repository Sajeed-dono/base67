<!-- Paste this prompt into Codex ONLY after the vault load message (docs/vault/00_START_HERE.md) and only when the previous prompt is verified complete in docs/PROGRESS.md. -->

# PROMPT 2 OF 8 — VISUAL DESIGN, ASTRONAUTS, PERSISTENT BASE MAP AND NAVIGATION

First read `docs/GAME_BRIEF.md`, `docs/PROGRESS.md`, and `docs/DECISIONS.md`. This is step 2 of 8. Build the visual system and navigation. Do not implement the full simulation yet.

## A. Visual direction

Use the supplied visual references if present. The visual language should feel like a polished, playful strategy-map game adapted to Mars:

- A stylized top-down Mars settlement map.
- Rounded cards, soft shadows, chunky buttons, circular map pins, badges, and a clear winding campaign path.
- Deep navy space/night tones, rust-orange Mars ground, sand, teal for safe systems, and red for danger.
- Clear visual hierarchy. Avoid clutter and tiny technical text.
- The base must be the main visual focus, not a generic menu screen.

If reference screenshots are missing, use the description above and record that the implementation used the written reference.

## B. Design system

Create `lib/ui/theme.dart` with:
- Colour tokens.
- Friendly rounded typography.
- Body text at least 16 sp where practical; headings 24 sp or larger.
- Spacing, corner radii, shadows, and animation durations.
- Text-size multiplier settings: 0.9, 1.0, 1.2, 1.4.
- Colour-blind-safe palette.
- Reduced-motion support.

Create reusable widgets:
- `GameButton`
- `InfoCard`
- `MapPin`
- `ProgressPath`
- `StarRating`
- `DataChip`
- `FactCard`
- `DaveBubble`
- `RadioBubble`
- `GaugeBar`
- `ModalSheet`
- `TimerCard` — shows activity, remaining real time, and completion outcome.
- `ResourceCard` — resource amount, capacity, production/consumption, and data chip.
- `BuildingCard` — facility state, level, upgrade, and construction progress.
- `ResearchCard` — research state, prerequisites, and progress.
- `CrewAssignmentCard` — astronaut, task, duration, and status.

All tappable controls must be at least 48 dp.

## C. Astronaut characters

Create `CrewBean` with Flutter `CustomPainter`:
- Original bean-shaped astronaut body.
- Rounded backpack, large visor, simple legs.
- 12 suit colours.
- Role badge: Commander star, Engineer wrench, Scientist flask, Medic cross.
- Moods: okay, cold, hungry, worried, working, resting, sheltering, researching, celebrating.
- Small posture/face/effect changes for mood.
- Idle breathing animation.
- Reduced-motion setting disables looping animation.

Do not copy any copyrighted character, name, logo, or asset from an existing game. Provide a debug preview for all roles and moods.

## D. Mars scenery and base facilities

Create reusable vector painters for:
- Mars ground and horizon.
- Habitat dome.
- Solar panel arrays, with visible dust.
- Battery storage.
- Greenhouse.
- Oxygen/life-support equipment.
- Radiation shielding.
- Ice miner and storage.
- Food storage.
- Workshop and maintenance bay.
- Research laboratory.
- Communications equipment.
- Rover and charging station.
- Crew rest and medical area.

Buildings should visually change when upgraded. Keep visual complexity manageable for mobile performance.

## E. Persistent base home screen

Build the Home Base screen as the central hub:

1. Show the player's actual persistent Mars base from a top-down or isometric-inspired map.
2. Place built facilities on the map. Unbuilt facilities appear as clearly marked construction sites or locked locations.
3. Show crew members at the base, with their current status or assignment.
4. Show essential resource summaries without overwhelming the player.
5. Show active construction and research timers.
6. Show current campaign chapter and next level objective.
7. Provide buttons for Campaign Map, Build, Research, Crew, Mars Notebook, Badges, Mission Patch, and Settings.
8. Provide a clear Continue Mission button when a mission is available.
9. The map must update when a building is constructed, upgraded, damaged, or repaired.
10. Do not reset or replace the base when the player opens another level.

## F. Campaign map

Create a 15-node campaign path grouped into five chapters. Each chapter has a clear title and visual identity. Show locked, available, completed, and mastered states. A level node opens its briefing. The map must show the player's current progress and next goal.

The campaign map and Home Base are separate views but share the same persistent state.

## G. Navigation

Create routes for:
- Splash
- Prologue
- Home Base
- Campaign Map
- Level Briefing
- Mission Planning
- Level Play
- Mission Debrief
- Build
- Research
- Crew
- Mars Notebook
- Badges
- Mission Patch
- Settings
- About
- Credits
- Debug Design Gallery
- Debug Data Check

Keep transitions short and respect reduced motion.

## H. Definition of done

- `flutter analyze` clean.
- Widget tests for core widgets, DataChip, CrewBean, TimerCard, BuildingCard, and ResearchCard.
- Smoke test for Home Base and Campaign Map.
- Verify all screens at 360 dp width and a tablet size.
- Verify 1.4x text size does not overflow.
- Update `docs/PROGRESS.md`.
- Report how to open the design gallery and any visual reference gaps.
