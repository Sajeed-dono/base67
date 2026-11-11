import 'dart:async';

import 'package:flutter/material.dart';

import '../app/campaign_controller.dart';
import '../data/models/data_class.dart';
import '../data/repositories/game_data_repository.dart';
import '../sim/simulation_clock.dart';
import '../ui/crew_bean.dart';
import '../ui/crew_movement.dart';
import '../ui/game_widgets.dart';
import '../ui/theme.dart';
import '../ui/settlement_snapshot.dart';
import '../ui/settlement_status_panel.dart';
import 'settlement_crew_screen.dart';
import 'power_mission_panel.dart';

/// One shared, portrait-first flow. No wall clock drives simulation steps.
class MissionScreen extends StatefulWidget {
  const MissionScreen({
    super.key,
    required this.controller,
    required this.repository,
    required this.levelId,
    required this.navigate,
    this.movement,
  });
  final CrewMovement? movement;
  final CampaignController controller;
  final GameDataRepository repository;
  final String levelId;
  final ValueChanged<String> navigate;
  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  bool _busy = false, _paused = false;
  String? _feedback;
  int? _plannedPanels, _plannedBatteries;
  Map<String, Object>? _powerPlan;
  double? _lightPreview;
  CampaignController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_act('open')),
    );
  }

  Future<void> _act(String action, {String? value}) async {
    if (!mounted || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await c.missionAction(
        widget.levelId,
        action,
        value: value,
      );
      if (mounted) {
        setState(
          () => _feedback = const {'saved', 'resumed'}.contains(result)
              ? null
              : result,
        );
      }
      if (mounted && !const {'saved', 'resumed'}.contains(result)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result)));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _feedback = 'The change could not be saved. Reopen BASE 67 before continuing.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final runtime = c.missions;
    final supported = runtime.supports(widget.levelId);
    final session = c.mission;
    if (!supported || session == null || session['level'] != widget.levelId) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mission')),
        body: Padding(
          padding: const EdgeInsets.all(GameSpacing.page),
          child: Column(
            children: [
              GameCopy(_feedback ?? 'Opening the mission…'),
              if (session != null)
                GameButton(
                  label: 'Resume current mission',
                  onPressed: () => widget.navigate('/resume-mission'),
                ),
              GameButton(
                label: 'Return to base',
                onPressed: () => widget.navigate('/home'),
              ),
            ],
          ),
        ),
      );
    }
    final level = (widget.repository.campaign['levels'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((r) => r['id'] == widget.levelId);
    final chapter = (widget.repository.campaign['chapters'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((r) => r['id'] == level['chapter_id']);
    final def = runtime.definition(widget.levelId);
    final p = c.progression, world = c.missionWorld;
    final phase = session['phase'] as String;
    final number = runtime.order(widget.levelId);
    final hour = SimulationClock.hourOfSol(
      world.elapsedHours,
      runtime.config.number('sol_hours'),
    );
    final night = hour >= runtime.config.number('daylight_hours');
    final storm = world.activeEvents['dust_storm'];
    final inStorm = storm != null && storm.endHour > world.elapsedHours;
    final hasStorm =
        number == 5 ||
        (((runtime.operations['event_profiles'] as Map)[widget.levelId]
                    as List?) ??
                [])
            .any((event) => (event as Map)['event_id'] == 'dust_storm');
    final learned = (session['learned'] as List).contains(def['interaction']);
    final preview =
        phase == 'planning' &&
            runtime.forecasts(session).isEmpty &&
            (runtime.settlement(p, session)['actions'] as List).contains(
              'forecast',
            )
        ? runtime.eventPlan(widget.levelId, world, session['seed'] as int)
        : <Map<String, Object>>[];
    Widget gap() => const SizedBox(height: GameSpacing.md);
    Widget button(String label, String action) => GameButton(
      label: label,
      onPressed: _busy ? null : () => unawaited(_act(action)),
    );
    Widget metric(String label, String value, DataClass provenance) => InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [GameCopy('$label: $value'), DataChip(provenance)],
      ),
    );
    final battery = world.resources['battery_kwh']!;
    final oxygen = world.resources['oxygen_kg']!;
    final hints = (def['hints'] as List).cast<String>();
    final hint = session['hint'] as int;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          level['name'] as String,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Mission settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => widget.navigate('/settings'),
          ),
          IconButton(
            tooltip: _paused ? 'Resume decisions' : 'Pause decisions',
            onPressed: () => setState(() => _paused = !_paused),
            icon: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
          ),
        ],
      ),
      bottomNavigationBar: phase == 'briefing'
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(GameSpacing.md),
                child: GameButton(
                  label: 'Review this base',
                  expand: true,
                  onPressed: _busy ? null : () => unawaited(_act('review')),
                ),
              ),
            )
          : const {'review', 'planning', 'play'}.contains(phase)
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(GameSpacing.md),
                child: GameButton(
                  expand: true,
                  label: phase == 'review'
                      ? 'Plan together'
                      : phase == 'planning'
                      ? 'Start mission'
                      : 'Advance one step',
                  onPressed: _busy || _paused
                      ? null
                      : () => unawaited(
                          _act(
                            phase == 'review'
                                ? 'plan'
                                : phase == 'planning'
                                ? 'begin'
                                : 'step',
                          ),
                        ),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: GameSpacing.contentMaxWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.all(GameSpacing.page),
              children: [
                if (_paused) ...[
                  const RadioBubble(
                    speaker: 'Mission paused',
                    message: 'Simulation advances only when you choose a step. Real-time jobs keep their own clocks. Settings and your base remain available.',
                  ),
                  GameButton(
                    label: 'Resume decisions',
                    onPressed: () => setState(() => _paused = false),
                  ),
                  gap(),
                ],
                GameCopy('${chapter['name']} • ${phase.toUpperCase()}'),
                GameCopy(
                  'Level $number • Sol ${SimulationClock.solIndex(world.elapsedHours, runtime.config.number('sol_hours')) + 1} • ${hour.toStringAsFixed(1)} simulation hours',
                ),
                const Wrap(
                  spacing: GameSpacing.sm,
                  children: [
                    DataChip(DataClass.game),
                    DataChip(DataClass.derived),
                  ],
                ),
                if (number <= 2) ...[
                  gap(),
                  SettlementStatusPanel(
                    world: world,
                    generationKw: (session['generation'] as num?)?.toDouble(),
                    showStorage: number == 2,
                    showReserves: false,
                  ),
                  gap(),
                  InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GameCopy(
                          number == 1
                              ? 'FIRST LIGHT / Sunlight to electricity'
                              : 'POWER STORAGE / Save daylight for night',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        GameCopy(level['mission_objective'] as String),
                        GameCopy(
                          phase == 'briefing'
                              ? 'Review your existing base, then make a plan.'
                              : number == 1
                              ? 'Inspect Solar, review its Build plan, then compare daylight and night.'
                              : 'Inspect Power storage. Check capacity and charge before observing a full day and night.',
                        ),
                        const GameCopy(
                          'Walking explores the base. Advance one step is the control that uses simulation time.',
                        ),
                      ],
                    ),
                  ),
                  if (phase != 'debrief') ...[
                    gap(),
                    PowerMissionPanel(
                      key: ValueKey('power-guidance-$phase'),
                      report: runtime.powerReport(
                        p,
                        session,
                        site: world.siteId,
                        seed:
                            c.save.deterministicSeed ??
                            runtime.config.defaultSeed,
                      ),
                      storageLesson: number == 2,
                      expanded: phase == 'planning' || phase == 'play',
                      jobs: [
                        for (final job in p.jobs.values.where(
                          (j) =>
                              j.status == 'active' &&
                              const {
                                'solar_array',
                                'battery_bank',
                              }.contains(j.recipe.targetId),
                        ))
                          '${job.recipe.targetId.replaceAll('_', ' ')}: ${job.recipe.kind.replaceAll('_', ' ')}; ${job.crewId ?? 'checklist'}; ${job.clock!.remaining.inSeconds} real seconds at last check.',
                      ],
                      onBuild: _busy ? null : () => widget.navigate('/build'),
                      onCrew: _busy ? null : () => widget.navigate('/crew'),
                    ),
                  ],
                ],
                if (number >= 5) ...[
                  gap(),
                  RadioBubble(
                    speaker: 'Mission Control',
                    message: number == 5
                        ? inStorm
                              ? 'Storm active. Sunlight is reduced; protect essential power.'
                              : phase == 'play' || phase == 'debrief'
                              ? 'Review stored power and panel dust.'
                              : 'Storm warning BEFORE launch. Charge storage and plan loads. The game storm begins only when you start.'
                        : 'Review the same base before each decision. Construction can continue while you plan.',
                  ),
                  if (hasStorm)
                    metric(
                      'Game storm duration',
                      '${runtime.config.stormFrames.last.$1.toStringAsFixed(0)} simulation hours',
                      DataClass.game,
                    ),
                ] else ...[
                  gap(),
                  GameCopy(
                    night
                        ? 'Forecast: night; panels need daylight.'
                        : 'Forecast: clear daylight.',
                  ),
                ],
                for (final event in runtime.forecasts(session)) ...[
                  gap(),
                  RadioBubble(
                    speaker: 'Mission Control',
                    message: '${event['warning']} ${event['effect']}',
                  ),
                  GameCopy(
                    'Scheduled at simulation hour ${(event['at'] as num).toStringAsFixed(1)}. ${world.firedScriptIds.contains(event['script_id']) ? 'Event occurred.' : 'Preparation time remains until this event.'}',
                  ),
                  const DataChip(DataClass.game),
                ],
                if ((phase == 'briefing' || phase == 'planning') &&
                    runtime.forecasts(session).isEmpty)
                  for (final event
                      in ((runtime.operations['event_profiles']
                                      as Map)[widget.levelId]
                                  as List? ??
                              [])
                          .where(
                            (row) => !world.firedScriptIds.contains(
                              '${widget.levelId}:${(row as Map)['id']}',
                            ),
                          )) ...[
                    gap(),
                    RadioBubble(
                      speaker: 'Forecast plan',
                      message:
                          '${(event as Map)['warning']} ${event['effect']}',
                    ),
                  ],
                for (final event in preview) ...[
                  GameCopy(
                    'Weather study: ${event['event_id']} about ${((event['at'] as num) - world.elapsedHours).toStringAsFixed(1)} simulation hours after starting now. This is a game scenario estimate.',
                  ),
                  const DataChip(DataClass.game),
                ],
                gap(),
                MissionBaseView(
                  units: p.facilities,
                  dust: number >= 4 ? world.dust : 0,
                  night: night,
                  storm: inStorm,
                  crew: MapCrew.fromSave(c.save),
                  movement: widget.movement,
                  reducedMotion: c.save.settings['reduceMotion'] == true,
                  facilities: settlementFacilities(c.save),
                  onManage: widget.navigate,
                ),
                gap(),
                if (p.damagedUnits.values.any((count) => count > 0)) ...[
                  RadioBubble(
                    speaker: 'Mission Control',
                    message: 'Installed equipment needs repair. Open Build to review the existing repair recipe. Required recovery can help if repair supplies are missing.',
                  ),
                  for (final damaged in p.damagedUnits.entries.where(
                    (e) => e.value > 0,
                  ))
                    metric(
                      'Damaged ${damaged.key.replaceAll('_', ' ')} units',
                      '${damaged.value}',
                      DataClass.game,
                    ),
                  GameButton(
                    label: 'Review repairs',
                    onPressed: () => widget.navigate('/build'),
                  ),
                ],
                if (number >= 13 &&
                    !runtime.crew.safe(runtime.settlement(p, session)))
                  const RadioBubble(
                    speaker: 'Medic',
                    message: 'The crew needs help. Review warmth, rest and care, or request emergency support. Nobody is permanently lost.',
                  ),
                if (phase == 'briefing') ...[
                  FactCard(
                    title: 'Your mission',
                    body:
                        '${level['learning_objective']} ${level['mission_objective']}',
                    dataClass: DataClass.game,
                  ),
                  gap(),
                ] else ...[
                  metric(
                    'Solar generation',
                    session['generation'] == null
                        ? '—; take an observation step'
                        : '${(session['generation'] as num).toStringAsFixed(2)} kW',
                    DataClass.derived,
                  ),
                  if (number >= 2) ...[
                    gap(),
                    metric(
                      'Battery energy',
                      '${battery.quantity.toStringAsFixed(2)} / ${battery.capacity.toStringAsFixed(2)} kWh',
                      DataClass.derived,
                    ),
                    metric(
                      'Safe battery reserve',
                      '${(battery.capacity * runtime.config.number('battery_safe_fraction')).toStringAsFixed(2)} kWh',
                      DataClass.game,
                    ),
                  ],
                  if (runtime.introduced(widget.levelId, 'loads')) ...[
                    gap(),
                    metric(
                      'Last observed power demand',
                      session['demand'] == null
                          ? '—; observe a step'
                          : '${(session['demand'] as num).toStringAsFixed(2)} kW',
                      DataClass.derived,
                    ),
                    metric(
                      'Habitat temperature',
                      '${world.temperature.toStringAsFixed(1)} °C',
                      DataClass.derived,
                    ),
                  ],
                  if (number >= 4) ...[
                    gap(),
                    metric(
                      'Panel dust',
                      '${(world.dust * 100).toStringAsFixed(1)}%',
                      DataClass.game,
                    ),
                    metric(
                      'Clean-panel estimate under current sky',
                      '${runtime.cleanGeneration(p, session, site: world.siteId, seed: world.rngState).toStringAsFixed(2)} kW',
                      DataClass.derived,
                    ),
                  ],
                  if (number >= 6) ...[
                    gap(),
                    metric(
                      'Food production',
                      session['food_rate'] == null
                          ? '—; observe a step'
                          : '${(session['food_rate'] as num).toStringAsFixed(3)} kg/hour',
                      DataClass.derived,
                    ),
                    metric(
                      'Greenhouse lights per unit',
                      '${runtime.config.loads['greenhouse_lights']} kW',
                      DataClass.game,
                    ),
                  ],
                  if (number >= 7) ...[
                    gap(),
                    metric(
                      'Oxygen reserve',
                      '${oxygen.quantity.toStringAsFixed(2)} kg',
                      DataClass.derived,
                    ),
                    metric(
                      'Oxygen safety reserve',
                      '${(runtime.config.initial['oxygen_kg']! * (runtime.rules['oxygen_safe_fraction'] as num)).toStringAsFixed(2)} kg',
                      DataClass.game,
                    ),
                    metric(
                      'Oxygen production / crew use',
                      '${session['oxygen_rate'] == null ? '—' : (session['oxygen_rate'] as num).toStringAsFixed(3)} / ${(runtime.config.number('oxygen_per_person_hour') * world.crewCount).toStringAsFixed(3)} kg/hour',
                      DataClass.derived,
                    ),
                    if (phase == 'review' || phase == 'planning') ...[
                      metric(
                        'Crew oxygen budget',
                        '${world.crewCount} people × ${runtime.config.number('oxygen_per_person_hour').toStringAsFixed(3)} kg/person/hour',
                        DataClass.derived,
                      ),
                      const GameCopy(
                        'More people use more oxygen. Greenhouse production offsets some use; when use is greater than production, the reserve falls. More storage holds more oxygen but cannot create it.',
                      ),
                    ],
                  ],
                  if (number >= 8) ...[
                    gap(),
                    metric(
                      'Current assessment exposure',
                      '${world.radiation.toStringAsFixed(3)} mSv',
                      DataClass.derived,
                    ),
                    metric(
                      'Lifetime recorded exposure',
                      '${(((session['environment'] as Map)['radiation_total'] as num?) ?? world.radiation).toStringAsFixed(3)} mSv',
                      DataClass.derived,
                    ),
                    metric(
                      'Game assessment limit',
                      '${runtime.config.number('radiation_limit')} mSv',
                      DataClass.game,
                    ),
                    _scienceCard('rad_gale_surface'),
                    const GameCopy(
                      'The game uses the Gale measurement as a common baseline. Its assessment limit is a teaching rule, not a NASA safety limit. Recovery support retains lifetime exposure history.',
                    ),
                  ],
                  if (number >= 10) ...[
                    gap(),
                    _scienceCard('ice_best_regions'),
                    const GameCopy(
                      'A survey combines source information with this site’s game ice tier. It does not confirm accessible ice at the settlement.',
                    ),
                  ],
                  if (number >= 11) ...[
                    gap(),
                    metric(
                      'Water reserve / capacity',
                      '${world.resources['water_kg']!.quantity.toStringAsFixed(2)} / ${world.resources['water_kg']!.capacity.toStringAsFixed(2)} kg',
                      DataClass.derived,
                    ),
                    metric(
                      'Game water reserve floor',
                      '${(runtime.config.initial['water_kg']! * (runtime.rules['water_safe_fraction'] as num)).toStringAsFixed(2)} kg',
                      DataClass.game,
                    ),
                    metric(
                      'Last water production / crew use',
                      '${session['water_rate'] ?? '—'} / ${session['water_use'] ?? '—'} kg/hour',
                      DataClass.derived,
                    ),
                    metric(
                      'Site mining capacity per installed unit',
                      '${runtime.config.miningPerSol[runtime.config.sites[world.siteId]!.iceTier]} kg/sol',
                      DataClass.game,
                    ),
                  ],
                  if (number >= 12) ...[
                    gap(),
                    metric(
                      'Food reserve / capacity',
                      '${world.resources['food_kg']!.quantity.toStringAsFixed(2)} / ${world.resources['food_kg']!.capacity.toStringAsFixed(2)} kg',
                      DataClass.derived,
                    ),
                    metric(
                      'Game food reserve floor',
                      '${(runtime.config.initial['food_kg']! * (runtime.rules['food_safe_fraction'] as num)).toStringAsFixed(2)} kg',
                      DataClass.game,
                    ),
                    metric(
                      'Last crew food use',
                      '${session['food_use'] ?? '—'} kg/hour',
                      DataClass.derived,
                    ),
                  ],
                  gap(),
                  Wrap(
                    spacing: GameSpacing.sm,
                    runSpacing: GameSpacing.sm,
                    children: [
                      for (final role in CrewRole.values)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CrewBean(
                              role: role,
                              size: GameSpacing.missionCrewSize,
                              suitColorIndex:
                                  c.save.crewAppearance[_roleName(
                                    role,
                                  )]?['suit'] ??
                                  0,
                              visorTintIndex:
                                  c.save.crewAppearance[_roleName(
                                    role,
                                  )]?['visor'] ??
                                  0,
                              faceStyleIndex:
                                  c.save.crewAppearance[_roleName(
                                    role,
                                  )]?['face'] ??
                                  0,
                              reducedMotion:
                                  c.save.settings['reduceMotion'] == true,
                              mood:
                                  p.crewAssignments[_roleName(role)] ==
                                      'mission:rest'
                                  ? CrewMood.resting
                                  : session['shelter'] == true
                                  ? CrewMood.sheltering
                                  : p.crewAssignments.containsKey(
                                      _roleName(role),
                                    )
                                  ? CrewMood.working
                                  : session['result'] == 'retry'
                                  ? CrewMood.worried
                                  : session['result'] == 'success'
                                  ? CrewMood.celebrating
                                  : CrewMood.okay,
                            ),
                            Text(_roleName(role), softWrap: false),
                            Text(
                              p.crewAssignments.containsKey(_roleName(role))
                                  ? 'Assigned'
                                  : 'Available',
                              softWrap: false,
                            ),
                          ],
                        ),
                    ],
                  ),
                  gap(),
                  if (phase == 'review') ...[
                    for (final opinion in def['advice'] as List) ...[
                      GameCopy(opinion as String),
                      gap(),
                    ],
                    const GameCopy(
                      'Crew recommendation: prepare before advancing. Commander, you make the final choice.',
                    ),
                  ],
                  if (phase == 'planning' || phase == 'play') ...[
                    if (!learned)
                      InfoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GameCopy(def['question'] as String),
                            GameButton(
                              label: def['answer'] as String,
                              onPressed: _busy
                                  ? null
                                  : () => unawaited(
                                      _act(
                                        'learn',
                                        value: def['answer'] as String,
                                      ),
                                    ),
                            ),
                            GameButton(
                              label: def['alternative'] as String,
                              secondary: true,
                              onPressed: _busy
                                  ? null
                                  : () => unawaited(
                                      _act(
                                        'learn',
                                        value: def['alternative'] as String,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    if (runtime.introduced(widget.levelId, 'loads')) ...[
                      const GameCopy(
                        'Habitat: essential, always on. Optional does not mean consequence-free.',
                      ),
                      if (number == 2)
                        const GameCopy(
                          'The habitat heater has a local switch. Watch temperature as well as energy; life support stays on.',
                        ),
                      if (number >= 3 &&
                          (p.facilities['power_control_station'] ?? 0) == 0)
                        const GameCopy(
                          'Build the Power Control Station to operate load switches.',
                        ),
                      for (final load in [
                        'heater',
                        if (number >= 6 &&
                            (p.facilities['greenhouse'] ?? 0) > 0)
                          'greenhouse_lights',
                        if (number >= 11 &&
                            (p.facilities['ice_miner_water_storage'] ?? 0) > 0)
                          'ice_miner',
                      ])
                        SwitchListTile(
                          contentPadding: const EdgeInsets.all(
                            GameSpacing.none,
                          ),
                          title: GameCopy(
                            load == 'heater'
                                ? 'Heater'
                                : load == 'ice_miner'
                                ? 'Ice miner'
                                : 'Greenhouse lights',
                          ),
                          subtitle: GameCopy(
                            load == 'heater'
                                ? 'Off saves power but cools the habitat.'
                                : 'Off stops this system’s production.',
                          ),
                          value: !(session['disabled'] as List).contains(load),
                          onChanged:
                              _busy ||
                                  !runtime.canControlLoad(
                                    p,
                                    widget.levelId,
                                    load,
                                  )
                              ? null
                              : (_) => unawaited(_act('toggle', value: load)),
                        ),
                    ],
                    if (number >= 9) ...[
                      GameButton(
                        label: session['shelter'] == true
                            ? 'Leave shelter'
                            : 'Enter shelter',
                        secondary: true,
                        onPressed: _busy
                            ? null
                            : () => unawaited(_act('shelter')),
                      ),
                      GameCopy(
                        session['shelter'] == true
                            ? 'Shelter procedure active. Cleaning pauses; indoor planning remains available.'
                            : 'Prepare shelter before the forecast particle event.',
                      ),
                    ],
                    if (number >= 3)
                      ExpansionTile(
                        title: const GameCopy('Crew activities and wellbeing'),
                        children: [MissionCrewPanel(controller: c)],
                      ),
                    gap(),
                    DaveBubble(
                      message: hint == 0
                          ? learned
                                ? 'Lesson understood. Compare the meters as you act.'
                                : 'Discuss the question, then test your idea.'
                          : hints[hint - 1],
                    ),
                    button(
                      hint == 0
                          ? 'Gentle hint'
                          : hint == 1
                          ? 'Stronger hint'
                          : 'Direct suggestion',
                      'hint',
                    ),
                    gap(),
                    if (phase == 'planning') ...[
                      if (number == 1)
                        InfoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const GameCopy(
                                'While installation runs, compare one proposed clean solar unit in daylight and at night. This is a preview; your real supplies do not change.',
                              ),
                              Wrap(
                                spacing: GameSpacing.sm,
                                runSpacing: GameSpacing.sm,
                                children: [
                                  GameButton(
                                    label: 'Preview daylight',
                                    onPressed: () => setState(
                                      () => _lightPreview = runtime
                                          .lightPreview(world, daylight: true),
                                    ),
                                  ),
                                  GameButton(
                                    label: 'Preview night',
                                    onPressed: () => setState(
                                      () => _lightPreview = runtime
                                          .lightPreview(world, daylight: false),
                                    ),
                                  ),
                                ],
                              ),
                              if (_lightPreview != null) ...[
                                GameCopy(
                                  'Proposed generation: ${_lightPreview!.toStringAsFixed(2)} kW',
                                ),
                                const DataChip(DataClass.derived),
                              ],
                            ],
                          ),
                        ),
                      if (number >= 2)
                        InfoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const GameCopy(
                                'Try a power plan while jobs run. This estimate assumes fully charged proposed storage and clear sky; it cannot change your base or guarantee storm survival.',
                              ),
                              DropdownButtonFormField<int>(
                                initialValue:
                                    _plannedPanels ??
                                    (p.facilities['solar_array'] ?? 1).clamp(
                                      1,
                                      c
                                          .migration
                                          .config
                                          .maxUnits['solar_array']!,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Proposed solar units',
                                ),
                                items: [
                                  for (
                                    var i = 1;
                                    i <=
                                        c
                                            .migration
                                            .config
                                            .maxUnits['solar_array']!;
                                    i++
                                  )
                                    DropdownMenuItem(
                                      value: i,
                                      child: Text('$i'),
                                    ),
                                ],
                                onChanged: (value) => setState(() {
                                  _plannedPanels = value;
                                  _powerPlan = null;
                                }),
                              ),
                              DropdownButtonFormField<int>(
                                initialValue:
                                    _plannedBatteries ??
                                    (p.facilities['battery_bank'] ?? 1).clamp(
                                      1,
                                      c
                                          .migration
                                          .config
                                          .maxUnits['battery_bank']!,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Proposed battery units',
                                ),
                                items: [
                                  for (
                                    var i = 1;
                                    i <=
                                        c
                                            .migration
                                            .config
                                            .maxUnits['battery_bank']!;
                                    i++
                                  )
                                    DropdownMenuItem(
                                      value: i,
                                      child: Text('$i'),
                                    ),
                                ],
                                onChanged: (value) => setState(() {
                                  _plannedBatteries = value;
                                  _powerPlan = null;
                                }),
                              ),
                              const DataChip(DataClass.game),
                              GameButton(
                                label: 'Compare day and night',
                                onPressed: () => setState(
                                  () => _powerPlan = runtime.powerPlan(
                                    world,
                                    panels:
                                        _plannedPanels ??
                                        (p.facilities['solar_array'] ?? 1)
                                            .clamp(
                                              1,
                                              c
                                                  .migration
                                                  .config
                                                  .maxUnits['solar_array']!,
                                            ),
                                    batteries:
                                        _plannedBatteries ??
                                        (p.facilities['battery_bank'] ?? 1)
                                            .clamp(
                                              1,
                                              c
                                                  .migration
                                                  .config
                                                  .maxUnits['battery_bank']!,
                                            ),
                                    disabledLoads: (session['disabled'] as List)
                                        .cast<String>(),
                                  ),
                                ),
                              ),
                              if (_powerPlan != null) ...[
                                GameCopy(
                                  'Estimated minimum: ${(_powerPlan!['minimum_kwh'] as num).toStringAsFixed(2)} kWh. ${_powerPlan!['safe'] == true ? 'Clear-sky reserve held.' : 'Revise the plan: reserve or crew safety failed.'}',
                                ),
                                const DataChip(DataClass.derived),
                              ],
                            ],
                          ),
                        ),
                      metric(
                        'Mission observation',
                        '${runtime.duration(widget.levelId).toStringAsFixed(2)} simulation hours',
                        DataClass.game,
                      ),
                      const GameCopy(
                        'Preparation steps use real energy and supplies. Waiting for a build uses no survival supplies.',
                      ),
                      if (number >= 2)
                        button('Observe preparation step', 'prepare'),
                    ] else ...[
                      GameCopy(
                        _paused
                            ? 'Decisions paused. You can still review or visit the base.'
                            : 'Simulation advances only when you choose a step.',
                      ),
                      if (number >= 4)
                        GameButton(
                          label: 'Assign cleaning and advance',
                          onPressed:
                              _paused ||
                                  _busy ||
                                  p.crewRoles.keys.every(
                                    p.crewAssignments.containsKey,
                                  )
                              ? null
                              : () => unawaited(_act('clean')),
                        ),
                    ],
                  ],
                  if (number >= 5) ...[gap(), _tauCard()],
                  if (phase == 'debrief') ...[
                    FactCard(
                      title: session['result'] == 'success'
                          ? 'Mission complete'
                          : 'What happened?',
                      body: session['message'] as String,
                      dataClass: DataClass.game,
                    ),
                    gap(),
                    GameCopy(def['lesson'] as String),
                    if (session['result'] == 'success') ...[
                      gap(),
                      if (p.receipts['resupply:${widget.levelId}']
                          case final receipt?) ...[
                        GameCopy(
                          'First-completion resupply recorded: ${receipt.amount.toStringAsFixed(0)} construction materials. Any delivery waiting for storage space stays saved. Replays do not grant it again.',
                        ),
                        const DataChip(DataClass.game),
                      ],
                      const GameCopy(
                        'Your crew, installed equipment and remaining supplies continue on the same base. The Campaign Map shows the saved unlock.',
                      ),
                    ],
                    gap(),
                    const GameCopy(
                      'What worked: the saved meters show the consequences of your choices. What to improve: compare supply, demand and reserve before the next step.',
                    ),
                    gap(),
                    for (final id in [
                      if (number >= 2) 'battery_kwh',
                      if (number >= 6) 'food_kg',
                      if (number >= 7) 'oxygen_kg',
                      if (number >= 11) 'water_kg',
                    ]) ...[
                      MissionComparison(
                        label: id.replaceAll('_', ' '),
                        before:
                            ((session['baseline'] as Map)[id] as num?)
                                ?.toDouble() ??
                            0,
                        after: world.resources[id]!.quantity,
                        unit: id == 'battery_kwh' ? 'kWh' : 'kg',
                      ),
                      gap(),
                    ],
                    const GameCopy(
                      'Alternative: prepare more storage and compare safe optional loads. Retry keeps this base and seed; it does not refill supplies or undo work.',
                    ),
                    if (session['alternative_battery'] != null) ...[
                      gap(),
                      const GameCopy(
                        'Last-step comparison: what if existing batteries had been fully charged before that step? Same loads and weather; this is a hypothetical estimate, not a refill or a survival guarantee.',
                      ),
                      const DataChip(DataClass.game),
                      MissionComparison(
                        label: 'Ending battery energy',
                        before: battery.quantity,
                        after: (session['alternative_battery'] as num)
                            .toDouble(),
                        unit: 'kWh',
                        beforeLabel: 'Actual',
                        afterLabel: 'If precharged',
                      ),
                    ],
                    button('Retry with this base', 'retry'),
                    GameButton(
                      label: 'Campaign map',
                      onPressed: () => widget.navigate('/campaign'),
                    ),
                    if (c.save.completedLevelIds.containsAll(runtime.levels))
                      GameButton(
                        label: 'Campaign certificate',
                        onPressed: () => widget.navigate('/certificate'),
                      ),
                  ],
                ],
                if (_feedback != null) ...[
                  gap(),
                  RadioBubble(speaker: 'Mission Control', message: _feedback!),
                ],
                if (phase != 'debrief' &&
                    (session['message'] as String).isNotEmpty) ...[
                  gap(),
                  GameCopy(session['message'] as String),
                ],
                gap(),
                const GameCopy(
                  'Emergency support is an explicit game aid: supplies and charging reach a capped floor; struggling crew receive help. Materials, spare parts, jobs and mission completion are not granted. Assisted outcomes are recorded.',
                ),
                const DataChip(DataClass.game),
                GameButton(
                  label: 'Request emergency support',
                  secondary: true,
                  onPressed: _busy ? null : _requestSupport,
                ),
                gap(),
                Wrap(
                  spacing: GameSpacing.sm,
                  runSpacing: GameSpacing.sm,
                  children: [
                    GameButton(
                      label: 'Build',
                      onPressed: () => widget.navigate('/build'),
                    ),
                    GameButton(
                      label: 'Crew',
                      onPressed: () => widget.navigate('/crew'),
                    ),
                    if (number >= (runtime.rules['research_from_level'] as int))
                      GameButton(
                        label: 'Research',
                        onPressed: () => widget.navigate('/research'),
                      ),
                    GameButton(
                      label: 'Return to base',
                      secondary: true,
                      onPressed: () => widget.navigate('/home'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _roleName(CrewRole role) => switch (role) {
    CrewRole.commander => 'Commander',
    CrewRole.engineer => 'Engineer',
    CrewRole.scientist => 'Scientist',
    CrewRole.medic => 'Medic',
  };

  Future<void> _requestSupport() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request game support?'),
        content: const GameCopy(
          'This delivers capped survival supplies or charging and helps struggling crew. The outcome records assistance. Lifetime exposure stays recorded; a completed game assessment window can restart. No mission is completed for you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep planning'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Request support'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      await _act('support');
    }
  }

  Widget _scienceCard(String id) {
    final fact = widget.repository.fact(id);
    return FactCard(
      title: fact?.raw['label'] as String? ?? 'NASA source not found',
      body: fact == null
          ? 'not found'
          : '${fact.value} ${fact.raw['unit'] ?? ''}. Source IDs: ${fact.sourceIds.join(', ')}.',
      dataClass: DataClass.nasa,
    );
  }

  Widget _tauCard() {
    final example = widget.repository.fact('tau_opportunity_2018');
    final light = widget.repository.fact('tau_3_sunlight');
    return FactCard(
      title: 'NASA example: dust and sunlight',
      body:
          'Opportunity measured tau ${example?.value ?? 'not found'}. ${light?.raw['label'] ?? 'Sunlight example'}: ${light?.value ?? 'not found'} ${light?.raw['unit'] ?? ''}. These measured examples are separate from the compressed GAME VALUE storm forecast.',
      dataClass: DataClass.nasa,
    );
  }
}
