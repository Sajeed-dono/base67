import 'dart:math' as math;

import '../progression/facility_mapping.dart';
import '../progression/progression_service.dart';
import '../sim/engine.dart';
import '../sim/event_model.dart';
import '../sim/player_inputs.dart';
import '../sim/power_model.dart';
import '../sim/resource_model.dart';
import '../sim/sim_config.dart';
import '../sim/sim_state.dart';
import '../sim/seeded_rng.dart';
import 'crew_operations.dart';

/// Mission orchestration, without Flutter, IO or a real-time clock. Physics
/// stays in Engine and real-time jobs stay in RealTimeProgressionService.
class MissionRuntime {
  MissionRuntime(this.config, this.tutorial, this.levels, {
    required this.operations, required Map<String, dynamic> crewRules,
    required this.progressionConfig,
  }) : crew = CrewOperations(crewRules);
  final SimConfig config;
  final Map<String, dynamic> tutorial;
  final List<String> levels;
  final Map<String, dynamic> operations;
  final ProgressionConfig progressionConfig;
  final CrewOperations crew;
  Map<String, dynamic> settlement(ProgressionState p, Map<String, dynamic>? session) =>
    crew.snapshot(p, session?['settlement'] as Map?);
  List<Map<String, dynamic>> get definitions =>
      (tutorial['missions'] as List).cast<Map<String, dynamic>>();
  Map<String, dynamic> definition(String id) => definitions.firstWhere((r) => r['id'] == id);
  Map get rules => tutorial['mission_rules'] as Map;
  int order(String id) => levels.indexOf(id) + 1;
  bool supports(String id) => definitions.any((r) => r['id'] == id);
  bool introduced(String id, String system) => order(id) >= (switch (system) {
    'battery' || 'loads' => 2, 'dust' || 'cleaning' => 4,
    'greenhouse' || 'research' => 6, 'oxygen' => 7, 'radiation' => 8,
    'shelter' => 9, 'survey' => 10, 'water' => 11, 'food' => 12,
    'wellbeing' => 13, _ => 1,
  });
  double duration(String id) => switch (definition(id)['hours']) {
    'sol' => config.number('sol_hours'),
    'storm' => config.stormFrames.last.$1,
    num value => value.toDouble(),
    _ => throw const FormatException('Unknown mission duration'),
  };

  /// The Level 2 lesson uses the habitat's local heater switch. Central load
  /// management keeps its existing station prerequisite in later missions.
  bool canControlLoad(ProgressionState p, String id, String load) {
    if (!introduced(id, 'loads') ||
        !const {'heater', 'greenhouse_lights', 'ice_miner'}.contains(load)) {
      return false;
    }
    if (order(id) == 2) {
      return load == 'heater' && (p.facilities['crew_habitat'] ?? 0) > 0;
    }
    if ((p.facilities['power_control_station'] ?? 0) == 0) return false;
    return switch (load) {
      'greenhouse_lights' => introduced(id, 'greenhouse') && (p.facilities['greenhouse'] ?? 0) > 0,
      'ice_miner' => introduced(id, 'water') && (p.facilities['ice_miner_water_storage'] ?? 0) > 0,
      _ => true,
    };
  }

  /// Detached Level 1/2 guidance. The preview runs the same normal mission step
  /// on immutable inputs; its returned aggregate is never saved or published.
  /// It neither supplies a full battery nor invents a replacement power model.
  PowerMissionReport powerReport(ProgressionState p, Map<String, dynamic> session, {
    required String site, required int seed,
  }) {
    final id = session['level'] as String;
    if (order(id) < 1 || order(id) > 2) {
      throw ArgumentError.value(id, 'level', 'Power guidance is for Levels 1 and 2');
    }
    final current = world(p, session, site: site, seed: seed);
    final solar = current.facilities['solar_array']?.workingUnits ?? 0;
    final banks = current.facilities['battery_bank']?.workingUnits ?? 0;
    final battery = current.resources['battery_kwh']!;
    final reserve = battery.capacity * config.number('battery_safe_fraction');
    final observing = const {'play', 'debrief'}.contains(session['phase']);
    final elapsed = observing
        ? math.max(0.0, current.elapsedHours - (session['start'] as num)) : 0.0;
    final proposed = session['phase'] == 'play' ? session : begin(session, current);
    final next = step(p, proposed, site: site, seed: seed);
    return PowerMissionReport(
      solarUnits: solar, batteryUnits: banks,
      storedKwh: battery.quantity, capacityKwh: battery.capacity, reserveKwh: reserve,
      observationHours: duration(id), elapsedHours: elapsed,
      previewHours: ((next.session['environment'] as Map)['hours'] as num).toDouble() - current.elapsedHours,
      generationKw: (next.session['generation'] as num?)?.toDouble() ?? 0,
      demandKw: (next.session['demand'] as num?)?.toDouble() ?? 0,
      projectedKwh: next.progression.resources['battery_kwh'] ?? 0,
      previewNeedsReview: next.session['result'] == 'retry',
      previewMessage: next.session['message'] as String,
      objectives: [
        ('Working solar array', solar > 0),
        ('Mission question discussed', (session['learned'] as List).contains(definition(id)['interaction'])),
        if (order(id) == 1)
          ('Solar generation observed', observing && (session['generation'] as num? ?? 0) > 0),
        if (order(id) == 2) ...[
          ('Working battery storage', banks > 0),
          ('Current battery reserve protected', banks > 0 && battery.capacity > 0 && battery.quantity >= reserve),
          ('Charging observed in this attempt', observing && session['charged'] == true),
          ('Discharging observed in this attempt', observing && session['discharged'] == true),
          ('Full observation completed', observing && elapsed >= duration(id) - 0.000000001),
        ],
      ],
    );
  }

  /// Resources/facilities are projected from the authoritative aggregate on
  /// every action. Checkpoints contain environment and teaching state only.
  SimState world(ProgressionState p, Map<String, dynamic>? session, {
    required String site, required int seed,
  }) {
    final e = session?['environment'] as Map?;
    final state = SimState(
      siteId: site, rngState: e?['rng'] as int? ?? seed,
      crewCount: p.crewRoles.length,
      elapsedHours: (e?['hours'] as num?)?.toDouble() ??
          config.number('daylight_hours') * (rules['initial_daylight_fraction'] as num),
      temperature: (e?['temperature'] as num?)?.toDouble() ?? config.number('target_temp'),
      dust: (e?['dust'] as num?)?.toDouble() ?? 0,
      radiation: (e?['radiation'] as num?)?.toDouble() ?? 0,
      cleaningHours: (e?['cleaning'] as num?)?.toDouble() ?? 0,
      lastRandomSol: e?['last_random_sol'] as int? ?? -1,
      spareParts: (p.resources['spare_part'] ?? 0).floor(),
      facilities: FacilityMapping.toSimulation(p), researchIds: p.completedResearch,
      firedScriptIds: ((e?['scripts'] as List?) ?? []).cast<String>(),
      activeEvents: {
        for (final row in ((e?['events'] as Map?) ?? {}).entries)
          row.key as String: ActiveEvent(row.key as String,
              ((row.value as Map)['start'] as num).toDouble(),
              ((row.value as Map)['end'] as num).toDouble()),
      },
    );
    final batteryCapacity = (state.facilities['battery_bank']?.storageUnits ?? 0) *
        config.number('battery_unit_kwh') * config.multiplier('battery_capacity', p.completedResearch,
          upgraded: (p.upgradeTiers['battery_bank'] ?? 0) > 0);
    return state.copyWith(resources: {
      for (final id in config.initial.keys)
        id: ResourceState(quantity: p.resources[id] ?? 0,
          capacity: ResourceModel.capacity(config, state, id)),
      'battery_kwh': ResourceState(quantity: p.resources['battery_kwh'] ?? 0, capacity: batteryCapacity),
    });
  }

  Map<String, Object> environment(SimState state) => {
    'rng': state.rngState, 'hours': state.elapsedHours, 'dust': state.dust,
    'temperature': state.temperature, 'radiation': state.radiation,
    'cleaning': state.cleaningHours, 'last_random_sol': state.lastRandomSol,
    'scripts': state.firedScriptIds.toList()..sort(),
    'events': {for (final e in state.activeEvents.entries)
      e.key: {'start': e.value.startHour, 'end': e.value.endHour}},
  };

  Map<String, dynamic> open(String id, SimState state, Map<String, dynamic>? previous) => {
    'level': id, 'phase': 'briefing', 'environment': {...environment(state),
      'radiation_total': (previous?['environment'] as Map?)?['radiation_total'] ?? state.radiation},
    'seed': previous?['seed'] ?? state.rngState,
    'learned': previous?['learned'] ?? <String>[],
    'disabled': previous?['disabled'] ?? <String>[],
    'hint': 0, 'history': <Map<String, Object>>[], 'baseline': <String, double>{},
    'start': state.elapsedHours, 'ticks': 0, 'charged': false, 'discharged': false,
    'result': '', 'message': '', 'attempt': (previous?['attempt'] as int? ?? 0) + 1,
    'storm_observed': false, 'storm_started': false,
    'settlement': previous?['settlement'],
    'shelter': previous?['shelter'] ?? false,
    'sheltered_events': previous?['sheltered_events'] ?? <String>[],
    'event_plan': (previous?['level'] == id)
      ? (previous?['event_plan'] ?? <Map<String, Object>>[])
      : <Map<String, Object>>[],
    'baseline_support': (previous?['level'] == id)
      ? (previous?['baseline_support'] ?? 0)
      : ((previous?['settlement'] as Map?)?['support_count'] ?? 0),
  };

  Map<String, dynamic> begin(Map<String, dynamic> session, SimState state) => {
    ...session, 'phase': 'play', 'start': state.elapsedHours, 'ticks': 0,
    'charged': false, 'discharged': false, 'history': <Map<String, Object>>[],
    'baseline': {for (final e in state.resources.entries) e.key: e.value.quantity},
    'result': '', 'message': '',
    'event_plan': forecasts(session).isNotEmpty ? forecasts(session)
      : eventPlan(session['level'] as String, state, session['seed'] as int),
    'baseline_support': session['baseline_support'] ?? (session['settlement'] as Map?)?['support_count'] ?? 0,
  };

  /// Seeded, warned campaign scenarios. Stable event identities cannot be
  /// replayed into duplicate damage or assistance. No unseeded event clustering.
  List<Map<String, Object>> eventPlan(String id, SimState state, int seed) {
    final profiles = (operations['event_profiles'] as Map)[id] as List? ?? const [];
    final rng = SeededRng(seed ^ order(id));
    var previousEnd = double.negativeInfinity;
    final plan = [for (final raw in profiles) (() {
      final row = Map<String, dynamic>.from(raw as Map);
      final jitter = row['jitter'] == true ? rng.nextDouble() * (rules['event_jitter_hours'] as num) : 0.0;
      final proposed = state.elapsedHours + (row['offset'] as num) + jitter;
      final at = math.max(proposed, previousEnd + (rules['event_gap_hours'] as num));
      previousEnd = at + (row['event_id'] == 'dust_storm' ? config.stormFrames.last.$1 : 0);
      return <String, Object>{...row.cast<String, Object>(), 'at': at,
        'script_id': '$id:${row['id']}'};
    })()];
    return plan.where((event) => !state.firedScriptIds.contains(event['script_id'])).toList();
  }

  List<Map<String, dynamic>> forecasts(Map<String, dynamic> session) =>
    ((session['event_plan'] as List?) ?? []).cast<Map<String, dynamic>>();

  MissionStep step(ProgressionState p, Map<String, dynamic> session, {
    required String site, required int seed, bool clean = false, bool preparation = false,
  }) {
    final id = session['level'] as String;
    if ((!preparation && session['phase'] != 'play') ||
        (preparation && session['phase'] != 'planning')) {
      return MissionStep(p, session);
    }
    var state = world(p, session, site: site, seed: seed);
    final initial = state;
    var colony = settlement(p, session);
    final tasks = colony['tasks'] as Map;
    final cleaningTask = tasks.values.whereType<Map>().where((t) => t['kind'] == 'clean').firstOrNull;
    final elapsed = state.elapsedHours - (session['start'] as num);
    final hours = preparation ? config.number('tick_hours') :
        math.min(config.number('tick_hours'), math.max(0.0, duration(id) - elapsed));
    if (hours <= 0) { return MissionStep(p, session); }
    // Explicit provisional settling-dust scenario input. The existing engine
    // calculates its effect on output; no alternative power formula is used.
    if (!preparation && order(id) == 4 && elapsed < (rules['dust_demonstration_hours'] as num)) {
      state = state.copyWith(dust: (state.dust + config.number('dust_gain_per_hour') * hours).clamp(0, 1).toDouble());
    }
    final disabled = (session['disabled'] as List).cast<String>().toSet();
    final ongoingStorm = state.activeEvents['dust_storm'];
    final stormActive = ongoingStorm != null && ongoingStorm.endHour > state.elapsedHours;
    final startStorm = !preparation && order(id) == 5 && session['storm_started'] != true && !stormActive;
    final inputs = PlayerInputs(
      disabledLoads: disabled, resume: true,
      shelter: session['shelter'] == true &&
        (state.facilities['radiation_shelter']?.workingUnits ?? 0) > 0,
      cleanPanels: introduced(id, 'cleaning') && (cleaningTask != null &&
        (cleaningTask['remaining'] as num) <= hours || clean && !p.crewAssignments.containsKey('Engineer')),
      crewAvailableForActions: cleaningTask != null || !p.crewAssignments.containsKey('Engineer'),
      scriptedEvents: [if (startStorm) ScheduledEvent(
        'storm:${session['attempt']}', 'dust_storm', (session['start'] as num).toDouble(),
      ), for (final row in forecasts(session))
        ScheduledEvent(row['script_id'] as String, row['event_id'] as String, (row['at'] as num).toDouble())],
    );
    final trace = Engine(config).step(state, inputs, hours: hours);
    final end = trace.state;
    final battery = end.resources['battery_kwh']!;
    final notices = trace.entries.expand((e) => e.notices).toList();
    var owned = p;
    for (final event in forecasts(session).where((row) => row['occurrence_id'] != null &&
        end.firedScriptIds.contains(row['script_id']) && !initial.firedScriptIds.contains(row['script_id']))) {
      final authority = progressionConfig.damageOccurrences[event['occurrence_id']];
      if (authority == null) { throw const FormatException('Mission damage authority not found'); }
      final observedCount = end.facilities[authority.targetId]?.damagedUnits ?? 0;
      final service = RealTimeProgressionService(progressionConfig);
      final observed = service.observeDamage(owned, occurrenceId: authority.id, damagedCount: observedCount);
      if (observed.code != 'damage_observed') { throw StateError('Mission damage rejected: ${observed.code}'); }
      final confirmed = service.confirmDamage(observed.state, authority.id);
      if (confirmed.code != 'damage_confirmed') { throw StateError('Mission confirmation rejected'); }
      owned = confirmed.state.copyWith(operatingStates: {...confirmed.state.operatingStates,
        if (p.operatingStates[authority.targetId] != 'off') authority.targetId: 'damaged'});
    }
    final crewStep = crew.advance(owned, colony, end,
      hours: end.elapsedHours - initial.elapsedHours, shortage: end.paused, config: config,
      cleaned: notices.any((n) => n.code == 'panels_cleaned'));
    owned = crewStep.progression;
    colony = crewStep.settlement;
    final shelteredEvents = ((session['sheltered_events'] as List?) ?? []).cast<String>().toSet();
    if (inputs.shelter && notices.any((n) => n.code == 'event' && n.detail == 'sep_event')) {
      shelteredEvents.add(id);
    }
    final reserveLost = !preparation && trace.entries.any((entry) {
      final b = entry.state.resources['battery_kwh']!;
      return order(id) == 2 && (b.capacity <= 0 || b.quantity < b.capacity * config.number('battery_safe_fraction')) ||
        (order(id) == 7 || order(id) == 15) && entry.state.resources['oxygen_kg']!.quantity <
          config.initial['oxygen_kg']! * (rules['oxygen_safe_fraction'] as num) ||
        order(id) >= 11 && entry.state.resources['water_kg']!.quantity <
          config.initial['water_kg']! * (rules['water_safe_fraction'] as num) ||
        order(id) >= 12 && entry.state.resources['food_kg']!.quantity <
          config.initial['food_kg']! * (rules['food_safe_fraction'] as num);
    });
    final failure = end.paused || reserveLost || order(id) >= 13 && !crew.safe(colony);
    final powerProblem = order(id) == 2 && reserveLost || notices.any((n) =>
      n.code == 'power_shortage' || n.code == 'needs_help' && n.detail == 'life_support_power');
    final alternative = failure && powerProblem && state.resources['battery_kwh']!.capacity > 0
        ? Engine(config).step(state.copyWith(resources: {
            ...state.resources, 'battery_kwh': ResourceState(
              quantity: state.resources['battery_kwh']!.capacity,
              capacity: state.resources['battery_kwh']!.capacity),
          }), inputs, hours: hours).state.resources['battery_kwh']!.quantity : null;
    final charged = session['charged'] == true || battery.quantity > initial.resources['battery_kwh']!.quantity;
    final discharged = session['discharged'] == true || battery.quantity < initial.resources['battery_kwh']!.quantity;
    final ticks = (session['ticks'] as int) + 1;
    final measured = switch (order(id)) {
      1 => battery.productionPerHour > 0,
      2 => charged && discharged,
      5 => session['storm_observed'] == true || startStorm || stormActive,
      6 => (end.facilities['greenhouse']?.workingUnits ?? 0) > 0 &&
          end.resources['food_kg']!.productionPerHour > 0,
      8 => end.radiation > initial.radiation,
      9 => (end.facilities['radiation_shelter']?.workingUnits ?? 0) > 0 &&
        (shelteredEvents.contains(id) || (colony['actions'] as List).contains('drill')),
      10 => (colony['survey_sites'] as List).contains(site),
      11 => end.resources['water_kg']!.productionPerHour > 0,
      12 => end.resources['food_kg']!.productionPerHour > 0,
      13 => (colony['actions'] as List).contains('care') &&
        (colony['actions'] as List).contains('rest') && (colony['actions'] as List).contains('rally'),
      14 => (colony['actions'] as List).contains('forecast') &&
        (colony['actions'] as List).contains('priorities') &&
        (shelteredEvents.contains(id) || (colony['actions'] as List).contains('drill')),
      15 => (colony['survey_sites'] as List).contains(site) &&
        (colony['actions'] as List).contains('care') && (colony['actions'] as List).contains('forecast') &&
        (colony['actions'] as List).contains('priorities') &&
        (end.facilities['greenhouse']?.workingUnits ?? 0) > 0 &&
        (end.facilities['ice_miner_water_storage']?.workingUnits ?? 0) > 0 &&
        (shelteredEvents.contains(id) || (colony['actions'] as List).contains('drill')) &&
        owned.receipts.containsKey('resolved:$id:meteor_shower:1'),
      _ => true,
    };
    final learned = (session['learned'] as List).contains(definition(id)['interaction']);
    // Floating-point termination tolerance, not a gameplay duration/bonus.
    final finished = end.elapsedHours - (session['start'] as num) >= duration(id) - 0.000000001;
    final success = !preparation && !failure && measured && learned && finished;
    final incomplete = !preparation && !success && finished;
    final history = [...(session['history'] as List), {
      'hour': end.elapsedHours, 'battery': battery.quantity,
      'oxygen': end.resources['oxygen_kg']!.quantity,
      'generation': battery.productionPerHour,
      'water': end.resources['water_kg']!.quantity, 'food': end.resources['food_kg']!.quantity,
    }];
    final next = <String, dynamic>{
      ...session, 'environment': {...environment(end), 'radiation_total': math.max(end.radiation,
        (((session['environment'] as Map)['radiation_total'] ?? initial.radiation) as num) + end.radiation - initial.radiation)},
      'settlement': colony, 'sheltered_events': shelteredEvents.toList(), 'ticks': ticks,
      'history': history.skip(math.max(0, history.length - (rules['history_limit'] as int))).toList(),
      'charged': charged, 'discharged': discharged,
      'storm_started': session['storm_started'] == true || startStorm || (!preparation && stormActive),
      'storm_observed': session['storm_observed'] == true || (!preparation && (startStorm || stormActive)),
      'phase': preparation ? 'planning' : failure || success || incomplete ? 'debrief' : 'play',
      'result': preparation ? '' : success ? 'success' : failure || incomplete ? 'retry' : '',
      'message': failure ? _failure(notices, reserveLost, id) : incomplete
          ? 'Observation finished. Review the lesson and required evidence before retrying.'
          : preparation ? 'Preparation advanced simulation time; real resources were used.'
          : success ? 'Goal met. This same base continues with your crew.' : 'Step saved. Review the meters before advancing.',
      'generation': battery.productionPerHour, 'demand': battery.consumptionPerHour,
      'food_rate': end.resources['food_kg']!.productionPerHour,
      'oxygen_rate': end.resources['oxygen_kg']!.productionPerHour,
      'oxygen_use': end.resources['oxygen_kg']!.consumptionPerHour,
      'water_rate': end.resources['water_kg']!.productionPerHour,
      'water_use': end.resources['water_kg']!.consumptionPerHour,
      'food_use': end.resources['food_kg']!.consumptionPerHour,
      'alternative_battery': alternative,
    };
    return MissionStep(owned.copyWith(resources: {
      ...owned.resources, for (final e in end.resources.entries) e.key: e.value.quantity,
    }), next);
  }

  String _failure(List<SimNotice> notices, bool reserveLost, String id) {
    if (reserveLost && order(id) == 7) { return 'Oxygen reserve crossed. Compare crew use and powered production; empty extra capacity cannot replace oxygen.'; }
    if (reserveLost && order(id) < 11) { return 'Battery safety reserve crossed. Charge or expand storage before retrying.'; }
    if (notices.any((n) => n.code == 'needs_help' && n.detail.contains('temperature'))) {
      return 'Habitat too cold. Restore heater power and review the power budget.';
    }
    return 'A reserve, crew condition or essential power needs help. Review the meters, request labelled recovery support, and revise the plan before retrying.';
  }

  double cleanGeneration(ProgressionState p, Map<String, dynamic> session, {required String site, required int seed}) {
    final state = world(p, session, site: site, seed: seed).copyWith(dust: 0);
    final storm = state.activeEvents['dust_storm'];
    final tau = storm != null && storm.endHour > state.elapsedHours
        ? EventModel.stormTau(config, state.elapsedHours - storm.startHour) : config.number('clear_tau');
    return PowerModel.step(config, state, PlayerInputs(
      disabledLoads: (session['disabled'] as List).cast<String>().toSet(),
    ), config.number('tick_hours'), tau, []).generationKw;
  }

  double lightPreview(SimState current, {required bool daylight}) => PowerModel.step(config,
    current.copyWith(elapsedHours: daylight ? config.number('daylight_hours') / 2
        : config.number('daylight_hours') + config.number('tick_hours'),
      dust: 0, activeEvents: {}, facilities: {...current.facilities,
        'solar_array': FacilityState(units: progressionConfig.requiredUnits['solar_array']!, status: FacilityStatus.operating)}),
    PlayerInputs(), config.number('tick_hours'), config.number('clear_tau'), []).generationKw;

  /// Explicit, labelled survival assistance is separate from construction
  /// credits: no materials, parts, facilities, jobs or completion effects.
  MissionStep support(ProgressionState p, Map<String, dynamic> session, {required String site, required int seed}) {
    final policy = operations['support'] as Map;
    final current = world(p, session, site: site, seed: seed);
    final resources = {...p.resources};
    final delivered = <String, double>{};
    for (final id in [...config.initial.keys, 'battery_kwh']) {
      final cap = current.resources[id]!.capacity;
      final desired = id == 'battery_kwh' ? cap * (policy['battery_fraction'] as num)
          : config.initial[id]! * (policy['reserve_fraction'] as num);
      final floor = math.min(cap, desired);
      final before = p.resources[id] ?? 0;
      if (before < floor) { resources[id] = floor; delivered[id] = floor - before; }
    }
    final colony = settlement(p, session);
    final members = <String, dynamic>{};
    var helped = delivered.isNotEmpty;
    for (final e in (colony['crew'] as Map).entries) {
      final member = Map<String, dynamic>.from(e.value as Map);
      for (final stat in ['health','morale']) {
        final floor = (policy['${stat}_floor'] as num).toDouble();
        if ((member[stat] as num) < floor) { member[stat] = floor; helped = true; }
      }
      if ((member['fatigue'] as num) > (policy['fatigue_ceiling'] as num)) {
        member['fatigue'] = policy['fatigue_ceiling']; helped = true;
      }
      members[e.key as String] = member;
    }
    final environment = Map<String, dynamic>.from(session['environment'] as Map);
    final assessed = (environment['radiation'] as num).toDouble();
    if (assessed >= config.number('radiation_limit')) {
      environment['radiation_total'] ??= assessed;
      environment['radiation'] = 0.0; // Explicit new GAME VALUE assessment window.
      helped = true; // Lifetime exposure history is never erased.
    }
    final count = (colony['support_count'] as int) + (helped ? 1 : 0);
    return MissionStep(p.copyWith(resources: resources), {...session,
      'environment': environment,
      'settlement': {...colony, 'crew': members, 'support_count': count,
        if (helped) 'last_support': {'receipt': count, 'delivered': delivered,
          'at_simulation_hour': current.elapsedHours, 'previous_assessment': assessed}},
      'message': helped ? 'Emergency support recorded: supplies or charging reached the labelled floor; crew received help. This is assistance, not local production. No job or mission was completed.'
          : 'Supplies and crew are already above the support floors. Nothing was granted.',
    });
  }

  /// A labelled counterfactual for planning while jobs run. It never returns
  /// a replacement progression state, spends resources or finishes a timer.
  Map<String, Object> powerPlan(SimState current, {required int panels, required int batteries,
    required Iterable<String> disabledLoads}) {
    final capacity = batteries * config.number('battery_unit_kwh') *
      config.multiplier('battery_capacity', current.researchIds,
        upgraded: (current.facilities['battery_bank']?.tier ?? 1) > 1);
    var state = current.copyWith(
      paused: false, activeEvents: {},
      facilities: {...current.facilities,
        'solar_array': FacilityState(units: panels, status: FacilityStatus.operating,
          tier: current.facilities['solar_array']?.tier ?? 1),
        'battery_bank': FacilityState(units: batteries, status: FacilityStatus.operating,
          tier: current.facilities['battery_bank']?.tier ?? 1)},
      resources: {...current.resources, 'battery_kwh': ResourceState(
        quantity: capacity, capacity: capacity)},
    );
    final end = state.elapsedHours + config.number('sol_hours');
    var minimum = capacity;
    var safe = true;
    while (state.elapsedHours < end) {
      final remaining = end - state.elapsedHours;
      if (remaining < 0.000001) { break; } // Numerical termination only.
      final result = Engine(config).step(state, PlayerInputs(disabledLoads: disabledLoads),
        hours: math.min(config.number('tick_hours'), remaining));
      final next = result.state;
      minimum = math.min(minimum, next.resources['battery_kwh']!.quantity);
      if (next.paused || minimum < capacity * config.number('battery_safe_fraction')) { safe = false; }
      if (next.paused || next.elapsedHours <= state.elapsedHours) { break; }
      state = next;
    }
    return {'minimum_kwh': minimum, 'safe': safe};
  }

  void validate(Map<String, dynamic> session) {
    if (!supports(session['level'] as String? ?? '') ||
        !const {'briefing','review','planning','play','debrief'}.contains(session['phase'])) {
      throw const FormatException('Invalid mission identity or phase');
    }
    if (session['environment'] is! Map || session['baseline'] is! Map ||
        session['history'] is! List || session['learned'] is! List || session['disabled'] is! List) {
      throw const FormatException('Invalid mission collections');
    }
    final e = session['environment'] as Map;
    if (e.keys.any((key) => !const {'rng','hours','dust','temperature','radiation',
        'cleaning','last_random_sol','scripts','events','radiation_total'}.contains(key)) ||
        e['scripts'] is! List || !(e['scripts'] as List).every((id) => id is String) ||
        e['events'] is! Map || (session['history'] as List).length > (rules['history_limit'] as int)) {
      throw const FormatException('Invalid environment ownership or history');
    }
    for (final key in ['generation','demand','food_rate','oxygen_rate','oxygen_use','alternative_battery','water_rate','water_use','food_use']) {
      final value = session[key];
      if (value != null && (value is! num || !value.isFinite || value < 0)) {
        throw FormatException('Invalid mission measurement: $key');
      }
    }
    for (final key in ['hours','dust','radiation','cleaning','temperature']) {
      final value = e[key];
      if (value is! num || !value.isFinite || key != 'temperature' && value < 0) {
        throw FormatException('Invalid mission environment: $key');
      }
    }
    if ((e['dust'] as num) > 1 || e['rng'] is! int || e['last_random_sol'] is! int ||
        session['seed'] is! int || session['attempt'] is! int || (session['attempt'] as int) < 1 ||
        session['ticks'] is! int || (session['ticks'] as int) < 0 ||
        session['hint'] is! int || (session['hint'] as int) < 0 || (session['hint'] as int) > 3 ||
        session['charged'] is! bool || session['discharged'] is! bool ||
        !const {'','success','retry'}.contains(session['result']) || session['message'] is! String) {
      throw const FormatException('Invalid mission checkpoint');
    }
    if (session['start'] is! num || !(session['start'] as num).isFinite ||
        (session['start'] as num) < 0 || (session['start'] as num) > (e['hours'] as num)) {
      throw const FormatException('Invalid mission start');
    }
    final allowed = definitions.map((d) => d['interaction']).toSet();
    if (!(session['learned'] as List).every(allowed.contains) ||
        !(session['disabled'] as List).every((id) => const {'heater','greenhouse_lights','ice_miner'}.contains(id))) {
      throw const FormatException('Invalid mission interaction');
    }
    for (final value in (session['baseline'] as Map).values) {
      if (value is! num || !value.isFinite || value < 0) { throw const FormatException('Invalid mission baseline'); }
    }
    for (final row in session['history'] as List) {
      for (final key in ['hour','battery','oxygen','generation']) {
        final value = (row as Map)[key];
        if (value is! num || !value.isFinite || value < 0) { throw const FormatException('Invalid mission history'); }
      }
    }
    for (final row in (e['events'] as Map).entries) {
      final value = row.value as Map;
      if (!config.events.containsKey(row.key) || value['start'] is! num || value['end'] is! num) {
        throw const FormatException('Invalid mission event');
      }
      final start = (value['start'] as num).toDouble(), end = (value['end'] as num).toDouble();
      if (!start.isFinite || !end.isFinite || start < 0 || end < start) { throw const FormatException('Invalid mission event times'); }
    }
    (e['scripts'] as List).cast<String>();
    if (e['radiation_total'] != null && (e['radiation_total'] is! num ||
        !(e['radiation_total'] as num).isFinite || (e['radiation_total'] as num) < (e['radiation'] as num))) {
      throw const FormatException('Lifetime radiation history');
    }
    for (final row in forecasts(session)) {
      final at = row['at'];
      final profile = ((operations['event_profiles'] as Map)[session['level']] as List?) ?? [];
      if (at is! num || !at.isFinite || at < 0 || !profile.any((raw) =>
          (raw as Map)['id'] == row['id'] && raw['event_id'] == row['event_id'] &&
          raw['occurrence_id'] == row['occurrence_id']) ||
          row['script_id'] != '${session['level']}:${row['id']}') {
        throw const FormatException('Mission event checkpoint');
      }
    }
  }
}

class MissionStep {
  const MissionStep(this.progression, this.session);
  final ProgressionState progression;
  final Map<String, dynamic> session;
}

/// A view of canonical state and an unsaved forecast, never completion authority.
class PowerMissionReport {
  PowerMissionReport({
    required this.solarUnits, required this.batteryUnits,
    required this.storedKwh, required this.capacityKwh, required this.reserveKwh,
    required this.observationHours, required this.elapsedHours, required this.previewHours,
    required this.generationKw, required this.demandKw, required this.projectedKwh,
    required this.previewNeedsReview, required this.previewMessage,
    required Iterable<(String, bool)> objectives,
  }) : objectives = List.unmodifiable(objectives);
  final int solarUnits, batteryUnits;
  final double storedKwh, capacityKwh, reserveKwh, observationHours, elapsedHours,
      previewHours, generationKw, demandKw, projectedKwh;
  final bool previewNeedsReview;
  final String previewMessage;
  final List<(String, bool)> objectives;
}
