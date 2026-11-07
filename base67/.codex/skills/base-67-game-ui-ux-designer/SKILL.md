---
name: base-67-game-ui-ux-designer
description: BASE 67-specific game UI/UX design and implementation guidance for Codex. Use when designing, reviewing, or implementing interfaces, HUDs, menus, onboarding, feedback, accessibility, campaign navigation, persistent Mars-base screens, or visual systems in the BASE 67 Flutter game.
---

# BASE 67 — Game UI/UX Designer Skill

## Purpose

Act as the dedicated game UI/UX designer for **BASE 67**, an educational Mars settlement-building and Junior Astronaut mission-training game for children aged 10–14.

This skill translates BASE 67's approved Game Design Document (GDD) and Codex Prompt Sequence into practical interface design and implementation decisions. It is a project-specific skill—not a replacement for the GDD, repository instructions, or the staged Codex prompts.

## 1. Source-of-truth order

Before designing or changing UI:

1. Inspect the repository and read `docs/GAME_BRIEF.md`, `docs/PROGRESS.md`, and `docs/DECISIONS.md` if present.
2. Read the current BASE 67 GDD and the relevant step in the Codex Prompt Sequence when available in the repository.
3. Follow explicit project decisions and existing working behavior.
4. Use this skill for UI/UX interpretation and consistency.
5. If a conflict or missing decision remains, choose the safest simple solution, document it in `docs/DECISIONS.md`, and continue. Do not repeatedly interrupt the user for minor choices.
6. Do not claim a file, reference, test, or feature exists until you inspect it.

The GDD and current prompt sequence are the project’s design authority. This skill must not silently change their requirements.

## 2. Project identity and non-negotiable product facts

- Current game title: **BASE 67**.
- Never use the obsolete name “Outpost Zero” as the game title, UI label, documentation title, package display name, credits title, or release name.
- Platform: 2D Android mobile game built with Flutter.
- Design orientation: portrait-first, responsive to tablets.
- Delivery: offline-first; bundle assets and content locally.
- Audience: children aged 10–14.
- Core experience: educational Mars settlement management and Junior Astronaut training.
- Campaign: prologue + **15 levels**, grouped into five chapters.
- The player develops **one persistent Mars base** throughout all levels. It is not a series of disposable bases.
- Four crew roles persist: Commander, Engineer, Scientist, and Medic.
- The existing prologue and story should be preserved unless an explicit, documented change is approved.
- The game must remain accessible, supportive, fair, and non-manipulative.

## 3. BASE 67 campaign and interface context

Design screens around this campaign:

### Chapter I — Power and Energy
1. First Light
2. Power Storage
3. Energy Manager

### Chapter II — Martian Weather
4. Dust on Mars
5. The Great Storm

### Chapter III — Oxygen and Life Support
6. Greenhouse Online
7. Breathing Matters

### Chapter IV — Radiation, Water and Food
8. Radiation Alert
9. Shelter Protocol
10. Finding Water
11. Ice Operations
12. Food and Supplies

### Chapter V — Crew Management and Mission Survival
13. Crew Care
14. Mission Control
15. The Final Mission

Each level should communicate:
- One manageable new learning concept or responsibility.
- A clear mission objective.
- Relevant resource/system information only.
- A safe practice opportunity, when appropriate.
- A short result/debrief explaining what happened and why.

Do not overload the player with several unfamiliar controls at once.

## 4. Visual direction

Use a polished, playful Mars strategy-map aesthetic:

- Stylized top-down or isometric-inspired Mars settlement.
- Rust-orange Mars terrain, sand, deep navy space/night tones, teal for safe/healthy states, and red for danger.
- Rounded cards, soft shadows, friendly typography, chunky buttons, circular map pins, badges, and a clear winding campaign path.
- The persistent base—not a generic menu—is the main visual focus.
- Keep visual hierarchy clear and avoid clutter, tiny technical text, or unnecessary decoration.
- Buildings should visibly change when built, upgraded, damaged, or repaired.
- Prefer original vector art and Flutter `CustomPainter` assets where appropriate.
- Do not copy copyrighted characters, logos, insignia, assets, or distinctive art from existing games. Do not use NASA logos or insignia. Plain-text references to NASA data are permitted.

If supplied visual references are missing, use the written direction above and document that choice.

## 5. UI architecture and navigation

Respect the existing repository architecture. The intended separation includes:

- `lib/app/` — routing, app state, persistence coordination.
- `lib/data/` — typed models, repository, validation.
- `lib/sim/` — pure Dart simulation; no Flutter imports.
- `lib/progression/` — campaign, construction, research, timers.
- `lib/ui/` — theme, reusable widgets, maps, scenery, characters.
- `lib/prologue/` — existing prologue.
- `lib/game/` — levels and mission presentation.
- `assets/data/` — original read-only data pack.
- `assets/data/extra/` — new GAME VALUE configuration.
- `docs/` — design, decisions, simulation, QA, and progress records.

Use the existing routing/state approach when possible. Avoid adding dependencies unless there is a concrete need; explain and document any new dependency.

Recommended screen map (adapt to existing routes):
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

Home Base and Campaign Map are separate views over shared campaign state.

## 6. Core screens and UX requirements

### Home Base
Make this the player’s central hub and persistent settlement:

- Show the actual base and constructed facilities.
- Show unbuilt facilities as locked locations or construction sites.
- Show crew members and their current status/assignments.
- Show concise essential resource summaries.
- Show active build, upgrade, repair, and research timers.
- Show chapter progress and the next mission objective.
- Provide clear access to Campaign Map, Build, Research, Crew, Mars Notebook, Badges, Mission Patch, and Settings.
- Provide a prominent Continue Mission action when available.
- Reflect construction, upgrades, damage, repairs, and unlocks immediately.
- Never reset or replace the base when entering another level.

### Campaign Map
- Display all 15 levels in five clearly differentiated chapters.
- Communicate locked, available, completed, and mastered states.
- Show the next goal and campaign progress.
- Opening a level should lead to its briefing.
- Keep completed levels replayable for practice without erasing or corrupting current progress.

### Level Briefing and Mission Planning
Show only information needed for the upcoming mission:
- One-sentence objective.
- Learning objective.
- Mission duration and relevant budget.
- Available equipment and resources.
- Relevant forecast or warning.
- Relevant resource meters.
- Helpful preparation options.

Avoid showing locked systems or irrelevant meters too early.

### Level Play / HUD
- Keep critical information immediately readable: essential resources, mission objective, important warnings, and relevant controls.
- Show only meters needed for the current level.
- Place strategic or infrequently used information in inspectable panels rather than permanently cluttering the HUD.
- Use clear labels and icons; never rely on colour alone.
- Ensure the HUD does not cover important map objects or feedback.
- Provide pause/resume and a safe stopping point.

### Building / Upgrade panel
Clearly show:
- Facility purpose.
- Build/upgrade state and level.
- Cost and required resources.
- Duration and remaining time.
- Required prerequisites.
- Expected benefit and trade-offs.
- Assigned crew, if relevant.
- Queue and cancel/reassign options where allowed.

### Research panel
- Show research branches, prerequisites, progress, duration, and unlocked effects.
- Explain the educational result in simple language.
- Make the Scientist’s contribution understandable and optional.
- Do not present GAME VALUE research durations as real NASA timelines.

### Crew panel
- Show each astronaut’s chosen name, role, status, task, duration, and availability.
- Preserve the four established roles and source terminology.
- Allow safe reassignment or cancellation.
- Never make critical tutorial/story progression impossible because of a prior assignment.

### Debrief and learning review
After a mission:
- Explain what worked and what did not.
- Explain the cause of important resource changes or failures.
- Offer a retry or alternative strategy.
- Connect the outcome to a child-friendly science or systems lesson.
- Award stars/badges based on actual criteria.
- Avoid shame, punitive language, or false claims about learning achievement.

### Mars Notebook and data cards
- Unlock facts progressively as relevant topics are encountered.
- Keep explanations age-appropriate and concise.
- Distinguish **NASA DATA**, **GAME VALUE**, and **DERIVED** visibly.
- Link scientific fact cards to source/fact IDs where supported by the data pack.
- Do not invent sources, NASA facts, or citations.

## 7. Reusable UI components

Use or extend existing components before creating duplicates. The prompt sequence names these reusable widgets:

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
- `TimerCard`
- `ResourceCard`
- `BuildingCard`
- `ResearchCard`
- `CrewAssignmentCard`

Keep component APIs consistent and focused. Components should receive state/data rather than contain duplicated game rules.

## 8. Astronaut and Mars art direction

The crew uses the original bean-shaped astronaut concept:

- Rounded body and backpack, large visor, simple legs.
- Role badges: Commander star, Engineer wrench, Scientist flask, Medic cross.
- Suit colour and visor tint are player customizations.
- Supported moods include okay, cold, hungry, worried, working, resting, sheltering, researching, and celebrating.
- Use small, readable posture/face/effect changes to express mood.
- Idle breathing animation should be subtle.
- Reduced-motion mode disables looping animation.
- Provide a debug preview for roles and moods when implementing character art.

Create original vector scenery for Mars ground/horizon, habitat, solar arrays and dust, batteries, greenhouse, life support, radiation shelter, ice miner/water storage, food storage, workshop, research lab, communications, rover, and crew support areas as required by the current implementation step.

## 9. Child-centered UX, accessibility, and ethics

The experience is for ages 10–14. Apply these rules everywhere:

- Aim for approximately grade 5–6 reading level.
- Use short sentences, clear icons, progressive disclosure, and explain scientific terms when first introduced.
- Use supportive, calm language. Failure is feedback, not punishment.
- Offer retries, explanations, and practical next steps.
- Minimum interactive target size: **48 dp**.
- Body text should be at least **16 sp where practical**; headings typically **24 sp or larger**, subject to layout.
- Support text scaling: 0.9×, 1.0×, 1.2×, and 1.4×.
- Provide colour-blind-safe palettes and never communicate state through colour alone.
- Provide reduced-motion support and avoid excessive animation, particles, or screen shake.
- Important warnings must remain visible and readable.
- Keep controls usable at 360 dp width and tablet sizes.
- Avoid graphic harm. Crew members never die or disappear.
- Do not add chat, public profiles, location tracking, or social comparison without a separate child-safety/privacy review.
- Collect minimal personal data. A certificate display name should be optional and local by default.
- Do not claim student-tested learning outcomes unless actual approved playtesting supports the claim.

## 10. Feedback, warnings, and onboarding

Every meaningful player action should receive clear feedback:

- Visual feedback is required; audio is appropriate where enabled; haptics are optional and adjustable.
- Match intensity to importance: critical warnings stronger than routine collection.
- Never let effects obscure critical information.
- Explain what changed, why it changed, and what the player can do next.
- Use forecasts and warnings before major events where the design calls for them.
- Make event outcomes understandable and fair.
- Introduce mechanics gradually: explain → demonstrate → safe practice → challenge → debrief.
- Keep the first minute of each level understandable and rewarding.
- Provide hints and inspection without forcing players to read long text.

## 11. Time, timers, and persistence UX

BASE 67 has two independent clocks:

1. **Martian simulation time**: sunlight, day/night, resource consumption, weather, radiation, and survival simulation.
2. **Real-world progression time**: construction, upgrades, research, and selected maintenance tasks.

Never conflate these clocks in UI labels or code.

Timer UI should:
- Clearly state the activity, remaining real-world time, and expected completion result.
- Continue safely while the app is closed using saved timestamps.
- Avoid requiring the player to keep the app open.
- Avoid excessive notifications.
- Explain completion and the next useful action on return.
- Handle clock changes defensively and avoid duplicate completion/rewards.
- Offer other meaningful activities while work is underway.
- Never punish children for sleeping, school, or offline time.
- Never make a core campaign objective depend on a long timer.
- Never use paid speed-ups, ad gates, premium currency, loot boxes, streak pressure, expiring rewards, or manipulative urgency.

The timer design is a pacing aid, not a retention trap.

## 12. Data and science integrity

Keep these data classes separate:

- **NASA DATA**: sourced values in the original data pack, resolved through fact IDs and `sources.json`.
- **GAME VALUE**: game-design assumptions, balancing, timers, costs, risk levels, and rewards.
- **DERIVED**: calculated values based on NASA facts and/or clearly labelled game assumptions.

Rules:
- Treat original data files as read-only.
- Never hard-code NASA values into UI or simulation code; read by fact ID through the data repository.
- New campaign and balance configuration belongs in `assets/data/extra/`.
- Display a suitable data-class chip for scientific/simulation values.
- Never silently turn a game simplification into a scientific claim.
- If data is missing or contradictory, preserve the source and document the issue in `docs/DECISIONS.md` or the relevant data/QA document.

## 13. BASE 67 crew, sites, and rewards

### Crew roles
- Commander — planning, leadership, morale, and power priorities.
- Engineer — construction, repairs, maintenance, and panel cleaning.
- Scientist — research, ice surveys, observations, and forecasts.
- Medic — health checks, recovery, shelter drills, and crew wellbeing.

Preserve original traits and role terminology unless an approved decision changes them.

### Landing sites
Keep the four original choices and labels:
- Gale — EASY
- Arcadia — MEDIUM
- Deuteronilus — HARD
- Equatorial — EXTREME

Keep NASA-supported site facts separate from GAME VALUE terrain risk and gameplay effects. Do not display contradictory source wording as if it overrides the approved risk classification.

### Rewards
Use meaningful progression rewards:
- Chapter badges.
- Mission patch customization.
- Mars Notebook facts.
- Stars or clear performance feedback.
- Junior Astronaut certificate after the core 15-level campaign and final mission.

The certificate is a BASE 67 campaign completion reward, **not NASA accreditation**.

## 14. Flutter implementation expectations

When implementing UI in the repository:

- Inspect existing code and follow current project conventions.
- Prefer small, reusable Flutter widgets and clear state boundaries.
- Keep simulation/business logic out of widget build methods.
- Keep the simulation engine pure Dart.
- Avoid broad refactors unrelated to the current prompt.
- Preserve the working prologue.
- Keep dependencies minimal.
- Bundle assets; do not add network calls, web views, remote fonts, or remote images.
- Do not add Android INTERNET permission unless an explicitly approved requirement changes the offline-first rule.
- Ensure layouts respond to portrait phones and tablets.
- Respect text scaling and reduced-motion settings.
- Use stable keys for important controls and tests.
- Avoid unnecessary rebuilds and heavy animation on mobile.

## 15. Codex workflow and scope discipline

BASE 67 development is divided into eight sequential prompts. Work only on the current prompt/phase unless the user explicitly asks otherwise.

At the beginning of a task:
1. Read the project brief, progress, decisions, and relevant prompt.
2. Inspect the existing implementation before editing.
3. Identify the exact screens/components and files in scope.
4. Preserve working behavior and existing prologue.

After changes:
1. Run `flutter analyze`.
2. Run relevant tests and report actual results.
3. Check phone/tablet layout and text scaling when UI is affected.
4. Update `docs/PROGRESS.md`.
5. Record new or unresolved decisions in `docs/DECISIONS.md`.
6. Do not claim tests passed unless they were actually run.
7. Do not start the next Codex prompt automatically.

If a requested file or reference is absent, report the exact missing item and use the approved written design only when the prompt permits it. Never fabricate source content.

## 16. UI/UX review checklist

Before considering a screen complete, check:

- [ ] Does it support BASE 67’s persistent Mars base and current campaign state?
- [ ] Is the screen’s primary goal obvious within a few seconds?
- [ ] Is only relevant information shown?
- [ ] Are the controls understandable to a 10–14-year-old?
- [ ] Are tap targets at least 48 dp?
- [ ] Is text readable at 1.4× scaling?
- [ ] Does it work at 360 dp width and on a tablet?
- [ ] Is colour not the only state indicator?
- [ ] Are warnings clear but not frightening?
- [ ] Are animations reduced/disabled when requested?
- [ ] Are NASA DATA, GAME VALUE, and DERIVED distinctions preserved?
- [ ] Are timer and simulation clocks clearly distinguished?
- [ ] Does offline use remain safe and fair?
- [ ] Does the screen avoid manipulative retention or monetization?
- [ ] Does it preserve the existing prologue and persistent save?
- [ ] Are tests and documentation updated?

## 17. Expected response format for Codex

When asked to design or implement a UI/UX task, respond with:

1. **Repository findings** — relevant existing screens, components, and constraints.
2. **UX intent** — player goal, hierarchy, and interaction flow.
3. **Implementation plan** — small, scoped steps.
4. **Changes made** — actual files and behavior changed.
5. **Validation** — commands/tests actually run and their results.
6. **Open decisions or limitations** — only genuine unresolved items.

Do not provide a long design essay when the user asked for implementation. Do not stop for minor questions; make a safe documented decision and proceed.

## 18. Skill boundaries

This skill guides game UI/UX design and related Flutter presentation. It does not replace:
- The BASE 67 GDD or its source data.
- The eight Codex implementation prompts.
- Scientific source verification.
- A full simulation architecture or engineering specification.
- Child privacy/safety review.
- Actual student playtesting.

When these are needed, consult the repository’s authoritative files and report limitations honestly.
