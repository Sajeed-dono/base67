import 'dart:math' as math;

import 'timer_completion.dart';
import 'progression_clock.dart';

part 'progression_codec.dart';

/// Configuration-only GAME VALUE recipes. No filesystem, Flutter or clock reads.
class ProgressionRecipe {
  ProgressionRecipe({
    required this.kind,
    required this.targetId,
    required this.levelId,
    required this.duration,
    required Map<String, double> cost,
    required Iterable<String> buildings,
    required Iterable<String> research,
    required this.crewRole,
  }) : cost = Map.unmodifiable(cost),
       buildings = Set.unmodifiable(buildings),
       research = Set.unmodifiable(research);

  final String kind, targetId, levelId, crewRole;
  final Duration duration;
  final Map<String, double> cost;
  final Set<String> buildings, research;
  String get key => '$kind:$targetId';
}

class ProgressionConfig {
  ProgressionConfig._({
    required Map<String, ProgressionRecipe> recipes,
    required List<String> levels,
    required Set<String> resupplyLevels,
    required Set<String> indivisible,
    required Set<String> requiredFacilities,
    required this.startMaterials,
    required this.materialCapacity,
    required this.missionMaterials,
    required this.refundFraction,
    required this.maxUnits,
    required this.stockEquipment,
    required this.requiredUnits,
    required this.damageOccurrences,
    required this.lanes,
    required this.repairDurationMultiplier,
    required this.savedRecipeDurations,
  }) : recipes = Map.unmodifiable(recipes),
       levels = List.unmodifiable(levels),
       resupplyLevels = Set.unmodifiable(resupplyLevels),
       indivisible = Set.unmodifiable(indivisible),
       requiredFacilities = Set.unmodifiable(requiredFacilities);

  final Map<String, ProgressionRecipe> recipes;
  final List<String> levels;
  final Set<String> resupplyLevels, indivisible, requiredFacilities;
  final int startMaterials, materialCapacity, missionMaterials;
  final Map<String, int> maxUnits, requiredUnits;
  final Map<String, String> stockEquipment, lanes;
  final Map<String, DamageAuthority> damageOccurrences;
  final double repairDurationMultiplier;
  final double refundFraction;
  final Map<String, Set<Duration>> savedRecipeDurations;

  /// App-layer adapters will supply repository documents in 4B-2.
  factory ProgressionConfig.fromDocuments({
    required Map<String, dynamic> buildings,
    required Map<String, dynamic> research,
    required Map<String, dynamic> timers,
    required Map<String, dynamic> crew,
    required Map<String, dynamic> rules,
    required Map<String, dynamic> equipment,
    required Map<String, dynamic> events,
  }) {
    for (final document in [buildings, research, timers, crew, rules]) {
      if (document['_meta']?['data_class'] != 'GAME_VALUE' ||
          document['_meta']?['status'] != 'provisional') {
        throw const FormatException(
          'Progression must be provisional GAME_VALUE',
        );
      }
    }
    final levels = <String>[
      for (final row in rules['level_unlocks'] as List)
        row['level_id'] as String,
    ];
    if (levels.isEmpty || levels.toSet().length != levels.length) {
      throw const FormatException('Invalid campaign order');
    }
    final timerMap = <String, Duration>{};
    for (final row in timers['timers'] as List) {
      final seconds = _integer(row['duration_seconds']);
      if (seconds <= 0 ||
          seconds < _integer(row['duration_seconds_min']) ||
          seconds > _integer(row['duration_seconds_max']) ||
          timerMap.containsKey(row['id'])) {
        throw const FormatException('Invalid timer');
      }
      timerMap[row['id'] as String] = Duration(seconds: seconds);
    }
    final materials = rules['materials'] as Map;
    final cancellation = rules['cancellation'] as Map;
    final recovery = rules['recovery'] as Map;
    final capacity = _integer(materials['capacity']);
    final start = _integer(materials['start']);
    final fraction = _number(cancellation['refund_fraction']);
    final multiplier = _number(crew['timed_repair_duration_multiplier']);
    if (capacity <= 0 ||
        start > capacity ||
        fraction > 1 ||
        multiplier <= 0 ||
        multiplier > 1 ||
        recovery['required_only'] != true ||
        recovery['assistance_cancel_restore_fraction'] != 1 ||
        cancellation['queued_refund'] != 0 ||
        cancellation['due_completion_wins'] != true) {
      throw const FormatException('Invalid economy rules');
    }
    final indivisible = Set<String>.from(
      cancellation['indivisible_resource_ids'],
    );
    if (!indivisible.contains('materials')) {
      throw const FormatException('Materials must be indivisible');
    }
    final roles = Map<String, String>.from(crew['job_roles']);
    final lanes = Map<String, String>.from(rules['job_lanes']);
    if (lanes.length != 4 ||
        lanes['construction'] != 'engineering' ||
        lanes['upgrade'] != 'engineering' ||
        lanes['major_repair'] != 'engineering' ||
        lanes['research'] != 'research') {
      throw const FormatException('Invalid shared job lanes');
    }
    final equipmentRows = {
      for (final row in equipment['equipment'] as List)
        row['id'] as String: row as Map,
    };
    final maxUnits = <String, int>{}, requiredUnits = <String, int>{};
    final stockEquipment = <String, String>{};
    final recipes = <String, ProgressionRecipe>{};
    final requiredFacilities = <String>{};
    void add(
      Map row,
      String kind,
      String timerKey,
      Map cost,
      Iterable<String> neededBuildings,
      Iterable<String> neededResearch,
    ) {
      final duration = timerMap[row[timerKey]];
      final role = roles[kind];
      if (duration == null ||
          role == null ||
          !levels.contains(row['introduced_level_id'])) {
        throw const FormatException(
          'Missing timer, role or introduction level',
        );
      }
      final amounts = <String, double>{};
      for (final entry in cost.entries) {
        final value = _number(entry.value);
        if (indivisible.contains(entry.key) && value != value.floorToDouble()) {
          throw const FormatException('Fractional indivisible cost');
        }
        if (entry.key == 'materials' && value > capacity) {
          throw const FormatException('Cost exceeds material capacity');
        }
        amounts[entry.key as String] = value;
      }
      final recipe = ProgressionRecipe(
        kind: kind,
        targetId: row['id'] as String,
        levelId: row['introduced_level_id'] as String,
        duration: duration,
        cost: amounts,
        buildings: neededBuildings,
        research: neededResearch,
        crewRole: role,
      );
      if (recipes.containsKey(recipe.key)) {
        throw const FormatException('Duplicate recipe');
      }
      recipes[recipe.key] = recipe;
    }

    for (final row in buildings['buildings'] as List) {
      final prerequisites = List<String>.from(row['prerequisite_building_ids']);
      final id = row['id'] as String;
      final stockId = row['installation_stock_id'] as String?;
      if (stockId != null) {
        final source = equipmentRows[stockId];
        if (source == null ||
            stockId == 'spare_part' ||
            row['unit_limit_equipment_id'] != stockId) {
          throw const FormatException('Invalid installation equipment');
        }
        stockEquipment[id] = stockId;
        maxUnits[id] = _integer(source['max_units']);
      } else {
        maxUnits[id] = _integer(row['max_installed_units']);
      }
      if (maxUnits[id]! <= 0) throw const FormatException('Invalid unit limit');
      if (row['required_progression'] == true) {
        final units = _integer(row['required_installed_units']);
        if (units <= 0 || units > maxUnits[id]!) {
          throw const FormatException('Invalid required facility count');
        }
        requiredUnits[id] = units;
      }
      add(
        row,
        'construction',
        'construction_timer_id',
        row['cost'],
        prerequisites,
        [],
      );
      if (row['required_progression'] == true) {
        requiredFacilities.add(row['id'] as String);
      }
      if (row['max_upgrade_tier'] == 1) {
        add(row, 'upgrade', 'upgrade_timer_id', row['upgrade_cost'], [
          row['id'],
        ], []);
      } else if (row['max_upgrade_tier'] != 0) {
        throw const FormatException(
          'Only the existing single upgrade is supported',
        );
      }
      add(row, 'major_repair', 'repair_timer_id', row['repair_cost'], [
        row['id'],
      ], []);
    }
    for (final row in research['projects'] as List) {
      final effects = row['effects'] as List;
      if (effects.length != 1 ||
          effects.single['type'] != 'activate_sim_research' ||
          effects.single['research_id'] != row['id']) {
        throw const FormatException('Unsupported research effect');
      }
      add(
        row,
        'research',
        'timer_id',
        row['cost'],
        [],
        List<String>.from(row['prerequisites']),
      );
    }
    // Reject unknown prerequisites, cycles and prerequisites introduced too late.
    final visiting = <String>{}, visited = <String>{};
    void visit(String key) {
      if (visited.contains(key)) return;
      if (!visiting.add(key)) throw const FormatException('Prerequisite cycle');
      final recipe = recipes[key];
      if (recipe == null) throw const FormatException('Unknown prerequisite');
      final dependencies = [
        ...recipe.buildings.map((id) => 'construction:$id'),
        ...recipe.research.map((id) => 'research:$id'),
      ];
      for (final dependency in dependencies) {
        final parent = recipes[dependency];
        if (parent == null ||
            levels.indexOf(parent.levelId) > levels.indexOf(recipe.levelId)) {
          throw const FormatException('Unavailable prerequisite');
        }
        visit(dependency);
      }
      visiting.remove(key);
      visited.add(key);
    }

    for (final key in recipes.keys) {
      visit(key);
    }
    final eligible = Set<String>.from(materials['eligible_level_ids']);
    if (!levels.toSet().containsAll(eligible)) {
      throw const FormatException('Unknown resupply level');
    }
    final damageOccurrences = <String, DamageAuthority>{};
    final eventRows = {
      for (final row in events['events'] as List) row['id']: row as Map,
    };
    for (final raw in recovery['damage_occurrences'] as List) {
      final row = raw as Map;
      final target = row['facility_id'] as String;
      final level = row['level_id'] as String;
      final eventId = row['event_id'] as String;
      final sequence = _integer(row['sequence']);
      final units = _integer(row['units']);
      final effect = eventRows[eventId]?['effect'] as Map?;
      if (!levels.contains(level) ||
          !requiredFacilities.contains(target) ||
          stockEquipment[target] == null ||
          row['essential'] != true ||
          effect == null ||
          effect['damage'] != stockEquipment[target] ||
          sequence <= 0 ||
          units <= 0 ||
          units > _integer(effect['units']) ||
          units > maxUnits[target]!) {
        throw const FormatException('Invalid authoritative damage occurrence');
      }
      final id = '$level:$eventId:$sequence';
      if (damageOccurrences.containsKey(id)) {
        throw const FormatException(
          'Duplicate authoritative damage occurrence',
        );
      }
      damageOccurrences[id] = DamageAuthority._(id, target, level, units);
    }
    final savedDurations = <String, Set<Duration>>{};
    for (final entry
        in (timers['saved_recipe_durations_seconds'] as Map? ?? {}).entries) {
      if (!recipes.containsKey(entry.key)) {
        throw const FormatException('Unknown saved recipe duration');
      }
      savedDurations[entry.key as String] = Set.unmodifiable([
        for (final seconds in entry.value as List)
          Duration(seconds: _integer(seconds)),
      ]);
      if (savedDurations[entry.key]!.any(
        (duration) => duration <= Duration.zero,
      )) {
        throw const FormatException('Invalid saved recipe duration');
      }
    }
    return ProgressionConfig._(
      savedRecipeDurations: Map.unmodifiable(savedDurations),
      recipes: recipes,
      levels: levels,
      resupplyLevels: eligible,
      indivisible: indivisible,
      requiredFacilities: requiredFacilities,
      startMaterials: start,
      materialCapacity: capacity,
      missionMaterials: _integer(materials['per_first_mission']),
      refundFraction: fraction,
      maxUnits: Map.unmodifiable(maxUnits),
      stockEquipment: Map.unmodifiable(stockEquipment),
      requiredUnits: Map.unmodifiable(requiredUnits),
      damageOccurrences: Map.unmodifiable(damageOccurrences),
      lanes: Map.unmodifiable(lanes),
      repairDurationMultiplier: multiplier,
    );
  }

  static double _number(Object? value) {
    if (value is! num || !value.isFinite || value < 0) {
      throw const FormatException('Expected a finite nonnegative number');
    }
    return value.toDouble();
  }

  static int _integer(Object? value) {
    final number = _number(value);
    if (number != number.floorToDouble()) {
      throw const FormatException('Expected a whole number');
    }
    return number.toInt();
  }
}

/// Minted from the validated, repository-owned occurrence catalogue only.
class DamageAuthority {
  const DamageAuthority._(this.id, this.targetId, this.levelId, this.units);
  final String id, targetId, levelId;
  final int units;
}

class ProgressionJob {
  ProgressionJob({
    required this.id,
    required this.recipe,
    this.crewId,
    this.status = 'queued',
    this.clock,
    this.finishedAtUtc,
    this.recoveryId,
    this.repairDamageId,
    Map<String, double> paid = const {},
    Map<String, double> assistancePaid = const {},
    Map<String, int> reservedStock = const {},
    this.blockReason,
  }) : paid = Map.unmodifiable(paid),
       assistancePaid = Map.unmodifiable(assistancePaid),
       reservedStock = Map.unmodifiable(reservedStock);
  final String id;
  final ProgressionRecipe recipe;
  final String? crewId, blockReason, recoveryId, repairDamageId;
  final String status;
  final ProgressionClock? clock;
  final DateTime? finishedAtUtc;
  final Map<String, double> paid, assistancePaid;
  final Map<String, int> reservedStock;
  DateTime? get startedAtUtc => clock?.startedAtUtc;
  DateTime? get deadlineUtc => clock?.originalDeadlineUtc;
  ProgressionJob withStatus(
    String value, {
    ProgressionClock? clock,
    DateTime? finished,
    Map<String, double>? paid,
    Map<String, double>? assistancePaid,
    Map<String, int>? reservedStock,
    String? recoveryId,
    String? repairDamageId,
    String? reason,
  }) => ProgressionJob(
    id: id,
    recipe: recipe,
    crewId: crewId,
    status: value,
    clock: clock ?? this.clock,
    finishedAtUtc: finished ?? finishedAtUtc,
    paid: paid ?? this.paid,
    assistancePaid: assistancePaid ?? this.assistancePaid,
    reservedStock: reservedStock ?? this.reservedStock,
    recoveryId: recoveryId ?? this.recoveryId,
    repairDamageId: repairDamageId ?? this.repairDamageId,
    blockReason: reason,
  );
}

class ProgressionReceipt {
  const ProgressionReceipt(
    this.kind,
    this.amount, {
    this.targetId,
    this.levelId,
  });
  final String kind;
  final double amount;
  final String? targetId, levelId;
}

/// An observed damage allocation. Only the service can mint/resolve records.
/// Catalogue IDs carry authority; unidentified job allocations never do.
class DamageObservation {
  const DamageObservation._(this.targetId, this.units, this.remaining);
  final String targetId;
  final int units, remaining;
  DamageObservation _resolve() =>
      DamageObservation._(targetId, units, remaining - 1);
}

/// Unwired immutable service state, NOT a CampaignSave schema or disk store.
/// 4B-2 must persist the whole aggregate, including every receipt and earmark.
class ProgressionState {
  ProgressionState({
    required this.levelId,
    Map<String, double> resources = const {},
    Map<String, double> pending = const {},
    Map<String, Map<String, double>> assistance = const {},
    Map<String, int> packedStock = const {},
    Map<String, int> confirmedDamage = const {},
    Map<String, DamageObservation> damageObservations = const {},
    Map<String, String> operatingStates = const {},
    Map<String, String> externalCrewAssignments = const {},
    Set<String> externalFacilityReservations = const {},
    Map<String, int> facilities = const {},
    Map<String, int> upgradeTiers = const {},
    Map<String, int> damagedUnits = const {},
    Map<String, String> crewRoles = const {},
    Set<String> completedLevels = const {},
    Set<String> completedResearch = const {},
    Set<String> completedActivityIds = const {},
    Map<String, ProgressionJob> jobs = const {},
    Map<String, ProgressionReceipt> receipts = const {},
    List<String> log = const [],
    this.lastObservedUtc,
    this.lastObservationToken = -1,
  }) : resources = Map.unmodifiable(resources),
       pending = Map.unmodifiable(pending),
       assistance = Map.unmodifiable({
         for (final e in assistance.entries)
           e.key: Map<String, double>.unmodifiable(e.value),
       }),
       packedStock = Map.unmodifiable(packedStock),
       confirmedDamage = Map.unmodifiable(confirmedDamage),
       damageObservations = Map.unmodifiable(damageObservations),
       operatingStates = Map.unmodifiable(operatingStates),
       externalCrewAssignments = Map.unmodifiable(externalCrewAssignments),
       externalFacilityReservations = Set.unmodifiable(
         externalFacilityReservations,
       ),
       facilities = Map.unmodifiable(facilities),
       upgradeTiers = Map.unmodifiable(upgradeTiers),
       damagedUnits = Map.unmodifiable(damagedUnits),
       crewRoles = Map.unmodifiable(crewRoles),
       completedLevels = Set.unmodifiable(completedLevels),
       completedResearch = Set.unmodifiable(completedResearch),
       completedActivityIds = Set.unmodifiable(completedActivityIds),
       jobs = Map.unmodifiable(jobs),
       receipts = Map.unmodifiable(receipts),
       log = List.unmodifiable(log);

  final String levelId;
  final Map<String, double> resources, pending;
  final Map<String, Map<String, double>> assistance;
  final Map<String, int> packedStock, confirmedDamage;
  final Map<String, DamageObservation> damageObservations;
  final Map<String, String> operatingStates, externalCrewAssignments;
  final Set<String> externalFacilityReservations;
  final Map<String, int> facilities, upgradeTiers, damagedUnits;
  final Map<String, String> crewRoles;
  final Set<String> completedLevels, completedResearch, completedActivityIds;
  final Map<String, ProgressionJob> jobs;
  final Map<String, ProgressionReceipt> receipts;
  final List<String> log;
  final DateTime? lastObservedUtc;
  final int lastObservationToken;
  double get materials => resources['materials'] ?? 0;
  double get restrictedMaterials =>
      assistance.values.fold(0.0, (a, b) => a + (b['materials'] ?? 0));
  bool get hasActiveJob => jobs.values.any((job) => job.status == 'active');
  Map<String, String> get crewAssignments => Map.unmodifiable({
    ...externalCrewAssignments,
    for (final job in jobs.values)
      if (job.status == 'active' && job.crewId != null) job.crewId!: job.id,
  });

  ProgressionState copyWith({
    String? levelId,
    Map<String, double>? resources,
    Map<String, double>? pending,
    Map<String, Map<String, double>>? assistance,
    Map<String, int>? packedStock,
    Map<String, int>? confirmedDamage,
    Map<String, DamageObservation>? damageObservations,
    Map<String, String>? operatingStates,
    Map<String, String>? externalCrewAssignments,
    Set<String>? externalFacilityReservations,
    Map<String, int>? facilities,
    Map<String, int>? upgradeTiers,
    Map<String, int>? damagedUnits,
    Map<String, String>? crewRoles,
    Set<String>? completedLevels,
    Set<String>? completedResearch,
    Set<String>? completedActivityIds,
    Map<String, ProgressionJob>? jobs,
    Map<String, ProgressionReceipt>? receipts,
    List<String>? log,
    DateTime? lastObservedUtc,
    int? lastObservationToken,
  }) => ProgressionState(
    levelId: levelId ?? this.levelId,
    resources: resources ?? this.resources,
    pending: pending ?? this.pending,
    assistance: assistance ?? this.assistance,
    packedStock: packedStock ?? this.packedStock,
    confirmedDamage: confirmedDamage ?? this.confirmedDamage,
    damageObservations: damageObservations ?? this.damageObservations,
    operatingStates: operatingStates ?? this.operatingStates,
    externalCrewAssignments:
        externalCrewAssignments ?? this.externalCrewAssignments,
    externalFacilityReservations:
        externalFacilityReservations ?? this.externalFacilityReservations,
    facilities: facilities ?? this.facilities,
    upgradeTiers: upgradeTiers ?? this.upgradeTiers,
    damagedUnits: damagedUnits ?? this.damagedUnits,
    crewRoles: crewRoles ?? this.crewRoles,
    completedLevels: completedLevels ?? this.completedLevels,
    completedResearch: completedResearch ?? this.completedResearch,
    completedActivityIds: completedActivityIds ?? this.completedActivityIds,
    jobs: jobs ?? this.jobs,
    receipts: receipts ?? this.receipts,
    log: log ?? this.log,
    lastObservedUtc: lastObservedUtc ?? this.lastObservedUtc,
    lastObservationToken: lastObservationToken ?? this.lastObservationToken,
  );
}

class ProgressionResult {
  const ProgressionResult(this.state, this.code);
  final ProgressionState state;
  final String code;
}

class RealTimeProgressionService {
  const RealTimeProgressionService(this.config);
  final ProgressionConfig config;

  /// Caller owns mission results. This service never declares a mission won.
  ProgressionState resupply(ProgressionState state) {
    if (!config.levels.contains(state.levelId)) return state;
    var next = state;
    if (!next.receipts.containsKey('resupply:start')) {
      next = _grant(
        next,
        'resupply:start',
        config.startMaterials.toDouble(),
        'resupply',
      );
    }
    final eligible = config.levels
        .where(
          (id) =>
              config.resupplyLevels.contains(id) &&
              state.completedLevels.contains(id),
        )
        .toList();
    if (!next.receipts.containsKey('resupply:catch_up')) {
      final missing = eligible
          .where((id) => !next.receipts.containsKey('resupply:$id'))
          .toList();
      for (final id in missing) {
        next = _grant(
          next,
          'resupply:$id',
          config.missionMaterials.toDouble(),
          'resupply',
          level: id,
        );
      }
      next = next.copyWith(
        receipts: {
          ...next.receipts,
          'resupply:catch_up': ProgressionReceipt(
            'catch_up',
            (missing.length * config.missionMaterials).toDouble(),
          ),
        },
      );
    } else {
      for (final id in eligible) {
        if (!next.receipts.containsKey('resupply:$id')) {
          next = _grant(
            next,
            'resupply:$id',
            config.missionMaterials.toDouble(),
            'resupply',
            level: id,
          );
        }
      }
    }
    return _deliverPending(next);
  }

  /// Consumes packed consumables atomically. Mixed positive representations are
  /// ambiguous without provenance; never silently sum them or grant duplicates.
  ProgressionResult unpackSpareParts(ProgressionState state) {
    final packed = state.packedStock['spare_part'] ?? 0;
    final available = state.resources['spare_part'] ?? 0;
    if (packed < 0 ||
        !available.isFinite ||
        available < 0 ||
        available != available.floorToDouble()) {
      return ProgressionResult(state, 'invalid_resource');
    }
    if (packed == 0) return ProgressionResult(state, 'nothing_to_unpack');
    if (available > 0) {
      return ProgressionResult(state, 'ambiguous_spare_ownership');
    }
    final stock = {...state.packedStock}..remove('spare_part');
    return ProgressionResult(
      state.copyWith(
        packedStock: stock,
        resources: {...state.resources, 'spare_part': packed.toDouble()},
      ),
      'spares_unpacked',
    );
  }

  ProgressionResult enqueue(
    ProgressionState state, {
    required String jobId,
    required String kind,
    required String targetId,
    String? crewId,
  }) {
    if (jobId.isEmpty ||
        state.jobs.containsKey(jobId) ||
        state.completedActivityIds.contains(jobId)) {
      return ProgressionResult(state, 'duplicate_or_invalid_id');
    }
    final recipe = config.recipes['$kind:$targetId'];
    if (recipe == null) return ProgressionResult(state, 'unknown_recipe');
    if (crewId != null && state.crewRoles[crewId] != recipe.crewRole) {
      return ProgressionResult(state, 'wrong_crew_role');
    }
    return ProgressionResult(
      state.copyWith(
        jobs: {
          ...state.jobs,
          jobId: ProgressionJob(id: jobId, recipe: recipe, crewId: crewId),
        },
      ),
      'queued',
    );
  }

  ProgressionResult start(
    ProgressionState state, {
    required String jobId,
    required String kind,
    required String targetId,
    required ClockObservation observation,
    String? crewId,
  }) {
    if (observation.token <= state.lastObservationToken) {
      return ProgressionResult(state, 'stale_observation');
    }
    final queued = enqueue(
      reconcile(state, observation: observation),
      jobId: jobId,
      kind: kind,
      targetId: targetId,
      crewId: crewId,
    );
    if (queued.code != 'queued') return queued;
    return _activateReconciled(
      queued.state,
      jobId: jobId,
      observation: observation,
    );
  }

  String constructionObjective(String target) =>
      'construction:$target:${config.requiredUnits[target]}';

  /// Pure admission of an externally observed event transition, NOT event execution.
  /// The future mission boundary must supply the actual occurrence at observation
  /// time. A later positive aggregate count is not evidence for an old event.
  ProgressionResult observeDamage(
    ProgressionState state, {
    required String occurrenceId,
    required int damagedCount,
  }) {
    final source = config.damageOccurrences[occurrenceId];
    if (source == null) return ProgressionResult(state, 'unknown_damage');
    if (state.damageObservations.containsKey(occurrenceId) ||
        state.receipts.containsKey('observed:$occurrenceId') ||
        state.receipts.containsKey('damage:$occurrenceId') ||
        state.receipts.containsKey('resolved:$occurrenceId')) {
      return ProgressionResult(state, 'duplicate_damage');
    }
    final before = state.damagedUnits[source.targetId] ?? 0;
    if (state.levelId != source.levelId ||
        !_damageConsistent(state, source.targetId) ||
        before < 0 ||
        damagedCount != before + source.units ||
        damagedCount > (state.facilities[source.targetId] ?? 0)) {
      return ProgressionResult(state, 'damage_not_verified');
    }
    return ProgressionResult(
      state.copyWith(
        damagedUnits: {...state.damagedUnits, source.targetId: damagedCount},
        damageObservations: {
          ...state.damageObservations,
          occurrenceId: DamageObservation._(
            source.targetId,
            source.units,
            source.units,
          ),
        },
        receipts: {
          ...state.receipts,
          'observed:$occurrenceId': ProgressionReceipt(
            'observed_damage',
            source.units.toDouble(),
            targetId: source.targetId,
            levelId: source.levelId,
          ),
        },
      ),
      'damage_observed',
    );
  }

  bool _validObservation(ProgressionState state, String id) {
    final source = config.damageOccurrences[id],
        observed = state.damageObservations[id];
    final receipt = state.receipts['observed:$id'];
    return source != null &&
        observed != null &&
        observed.targetId == source.targetId &&
        observed.units == source.units &&
        observed.remaining > 0 &&
        observed.remaining <= observed.units &&
        receipt?.kind == 'observed_damage' &&
        receipt?.targetId == source.targetId &&
        receipt?.levelId == source.levelId &&
        receipt?.amount == source.units &&
        !state.receipts.containsKey('resolved:$id') &&
        _damageConsistent(state, source.targetId);
  }

  bool _damageConsistent(ProgressionState state, String target) {
    final count = state.damagedUnits[target] ?? 0;
    final tracked = state.damageObservations.values
        .where((o) => o.targetId == target)
        .fold(0, (sum, o) => sum + o.remaining);
    return count >= tracked && count <= (state.facilities[target] ?? 0);
  }

  ProgressionResult confirmDamage(ProgressionState state, String occurrenceId) {
    final source = config.damageOccurrences[occurrenceId];
    if (source == null) return ProgressionResult(state, 'unknown_damage');
    if (state.confirmedDamage.containsKey(occurrenceId) ||
        state.receipts.containsKey('damage:$occurrenceId') ||
        state.receipts.containsKey('resolved:$occurrenceId')) {
      return ProgressionResult(state, 'duplicate_damage');
    }
    if (state.levelId != source.levelId ||
        !_validObservation(state, occurrenceId)) {
      return ProgressionResult(state, 'damage_not_verified');
    }
    return ProgressionResult(
      state.copyWith(
        confirmedDamage: {
          ...state.confirmedDamage,
          occurrenceId: state.damageObservations[occurrenceId]!.remaining,
        },
        receipts: {
          ...state.receipts,
          'damage:$occurrenceId': ProgressionReceipt(
            'damage',
            source.units.toDouble(),
            targetId: source.targetId,
            levelId: source.levelId,
          ),
        },
      ),
      'damage_confirmed',
    );
  }

  bool _damageReserved(ProgressionState state, String id) => state.jobs.values
      .any((job) => job.status == 'active' && job.repairDamageId == id);

  /// Reports an already-paid external field-repair outcome. Does not execute
  /// field repairs or charge resources; future coordination owns that transaction.
  ProgressionResult recordFieldRepair(
    ProgressionState state, {
    required String damageId,
    required int damagedCount,
  }) {
    final damage = state.damageObservations[damageId];
    if (damage == null || damage.remaining <= 0) {
      return ProgressionResult(state, 'damage_not_open');
    }
    if (_damageReserved(state, damageId) ||
        state.externalFacilityReservations.contains(damage.targetId)) {
      return ProgressionResult(state, 'damage_reserved');
    }
    if (!_damageConsistent(state, damage.targetId) ||
        damagedCount != (state.damagedUnits[damage.targetId] ?? 0) - 1) {
      return ProgressionResult(state, 'damage_not_verified');
    }
    return ProgressionResult(
      _resolveDamage(state, damageId),
      'field_repair_recorded',
    );
  }

  ProgressionState _resolveDamage(ProgressionState state, String id) {
    final damage = state.damageObservations[id]!;
    final left = damage.remaining - 1;
    final assistance = {...state.assistance};
    if (left == 0) assistance.remove('repair:$id');
    return state.copyWith(
      damagedUnits: {
        ...state.damagedUnits,
        damage.targetId: (state.damagedUnits[damage.targetId] ?? 0) - 1,
      },
      damageObservations: {...state.damageObservations, id: damage._resolve()},
      confirmedDamage: {
        ...state.confirmedDamage,
        if (state.confirmedDamage.containsKey(id)) id: left,
      },
      assistance: assistance,
      receipts: {
        ...state.receipts,
        if (left == 0)
          'resolved:$id': ProgressionReceipt(
            'resolved_damage',
            damage.units.toDouble(),
            targetId: damage.targetId,
          ),
      },
    );
  }

  String? _recoveryId(ProgressionState state, ProgressionRecipe recipe) {
    if (recipe.kind == 'construction' &&
        (state.facilities[recipe.targetId] ?? 0) <
            (config.requiredUnits[recipe.targetId] ?? 0)) {
      return constructionObjective(recipe.targetId);
    }
    if (recipe.kind == 'major_repair' &&
        (state.damagedUnits[recipe.targetId] ?? 0) > 0) {
      final ids = state.confirmedDamage.keys.toList()..sort();
      for (final id in ids) {
        final authority = config.damageOccurrences[id];
        if (_validObservation(state, id) &&
            authority != null &&
            authority.targetId == recipe.targetId &&
            (state.confirmedDamage[id] ?? 0) > 0 &&
            state.confirmedDamage[id] ==
                state.damageObservations[id]!.remaining &&
            state.receipts['damage:$id']?.kind == 'damage' &&
            state.receipts['damage:$id']?.targetId == authority.targetId &&
            state.receipts['damage:$id']?.levelId == authority.levelId &&
            state.receipts['damage:$id']?.amount == authority.units &&
            (state.damagedUnits[recipe.targetId] ?? 0) <=
                (state.facilities[recipe.targetId] ?? 0)) {
          return 'repair:$id';
        }
      }
    }
    return null;
  }

  ProgressionResult activate(
    ProgressionState state, {
    required String jobId,
    required ClockObservation observation,
  }) {
    if (observation.token <= state.lastObservationToken) {
      return ProgressionResult(state, 'stale_observation');
    }
    return _activateReconciled(
      reconcile(state, observation: observation),
      jobId: jobId,
      observation: observation,
    );
  }

  // The public entry point accepts the observation exactly once, even when
  // the requested command is invalid. Internal work must not accept it again.
  ProgressionResult _activateReconciled(
    ProgressionState state, {
    required String jobId,
    required ClockObservation observation,
  }) {
    var next = state;
    final job = next.jobs[jobId];
    if (job == null || !['queued', 'blocked'].contains(job.status)) {
      return ProgressionResult(next, 'not_startable');
    }
    final reason = _blockedReason(next, job);
    if (reason != null) {
      return ProgressionResult(
        next.copyWith(
          jobs: {
            ...next.jobs,
            jobId: job.withStatus('blocked', reason: reason),
          },
        ),
        reason,
      );
    }
    String? repairDamageId;
    if (job.recipe.kind == 'major_repair') {
      final tracked =
          next.damageObservations.keys
              .where(
                (id) =>
                    next.damageObservations[id]!.targetId ==
                        job.recipe.targetId &&
                    next.damageObservations[id]!.remaining > 0,
              )
              .toList()
            ..sort();
      final funded = _recoveryId(next, job.recipe);
      if (funded != null) {
        repairDamageId = funded.substring('repair:'.length);
      } else if (tracked.isNotEmpty) {
        repairDamageId = tracked.first;
      } else {
        repairDamageId = 'unidentified:${job.id}';
        next = next.copyWith(
          damageObservations: {
            ...next.damageObservations,
            repairDamageId: DamageObservation._(job.recipe.targetId, 1, 1),
          },
        );
      }
    }
    final recoveryId = _recoveryId(next, job.recipe);
    final credit = {...?next.assistance[recoveryId]};
    final resources = {...next.resources};
    final ordinaryPaid = <String, double>{}, assisted = <String, double>{};
    for (final e in job.recipe.cost.entries) {
      final used = math.min(credit[e.key] ?? 0, e.value).toDouble();
      assisted[e.key] = used;
      credit[e.key] = (credit[e.key] ?? 0) - used;
      ordinaryPaid[e.key] = e.value - used;
      resources[e.key] = (resources[e.key] ?? 0) - ordinaryPaid[e.key]!;
    }
    final stock = {...next.packedStock}, reserved = <String, int>{};
    final stockId = config.stockEquipment[job.recipe.targetId];
    if (job.recipe.kind == 'construction' &&
        stockId != null &&
        (stock[stockId] ?? 0) > 0) {
      stock[stockId] = stock[stockId]! - 1;
      reserved[stockId] = 1;
    }
    final duration = job.recipe.kind == 'major_repair' && job.crewId != null
        ? Duration(
            microseconds:
                (job.recipe.duration.inMicroseconds *
                        config.repairDurationMultiplier)
                    .ceil(),
          )
        : job.recipe.duration;
    next = next.copyWith(
      operatingStates: {
        ...next.operatingStates,
        if (job.recipe.kind == 'construction' &&
            (next.facilities[job.recipe.targetId] ?? 0) == 0 &&
            [
              null,
              'notBuilt',
              'underConstruction',
            ].contains(next.operatingStates[job.recipe.targetId]))
          job.recipe.targetId: 'underConstruction',
      },
      resources: resources,
      packedStock: stock,
      assistance: {...next.assistance, ?recoveryId: credit},
      jobs: {
        ...next.jobs,
        jobId: job.withStatus(
          'active',
          clock: ProgressionClock.start(observation, duration),
          paid: ordinaryPaid,
          assistancePaid: assisted,
          reservedStock: reserved,
          recoveryId: recoveryId,
          repairDamageId: repairDamageId,
        ),
      },
      receipts: {
        ...next.receipts,
        'start:$jobId': const ProgressionReceipt('start', 0),
      },
    );
    return ProgressionResult(_deliverPending(next), 'active');
  }

  String? _blockedReason(ProgressionState state, ProgressionJob job) {
    final recipe = job.recipe;
    if (job.crewId != null && state.crewRoles[job.crewId] != recipe.crewRole) {
      return 'wrong_crew_role';
    }
    final operating = state.operatingStates[recipe.targetId];
    if (operating != null &&
        (!const {
              'notBuilt',
              'underConstruction',
              'operating',
              'damaged',
              'off',
              'outOfResources',
            }.contains(operating) ||
            ((state.facilities[recipe.targetId] ?? 0) > 0 &&
                ['notBuilt', 'underConstruction'].contains(operating)))) {
      return 'invalid_operating_state';
    }
    final essentialRepair =
        recipe.kind == 'major_repair' && _recoveryId(state, recipe) != null;
    if (!config.levels.contains(state.levelId) ||
        (!essentialRepair &&
            config.levels.indexOf(state.levelId) <
                config.levels.indexOf(recipe.levelId))) {
      return 'locked';
    }
    if (!recipe.buildings.every((id) => (state.facilities[id] ?? 0) > 0) ||
        !state.completedResearch.containsAll(recipe.research)) {
      return 'prerequisite';
    }
    if (job.crewId != null && state.crewAssignments.containsKey(job.crewId)) {
      return 'crew_busy';
    }
    if (state.externalFacilityReservations.contains(recipe.targetId) ||
        state.jobs.values.any(
          (j) =>
              j.id != job.id &&
              j.status == 'active' &&
              j.recipe.targetId == recipe.targetId,
        )) {
      return 'target_busy';
    }
    if (state.jobs.values.any(
      (j) =>
          j.id != job.id &&
          j.status == 'active' &&
          config.lanes[j.recipe.kind] == config.lanes[recipe.kind],
    )) {
      return 'lane_busy';
    }
    if (recipe.kind == 'construction' &&
        (state.facilities[recipe.targetId] ?? 0) >=
            config.maxUnits[recipe.targetId]!) {
      return 'unit_limit';
    }
    if (recipe.kind == 'upgrade' &&
        (state.upgradeTiers[recipe.targetId] ?? 0) >= 1) {
      return 'already_upgraded';
    }
    if (recipe.kind == 'major_repair' &&
        !_damageConsistent(state, recipe.targetId)) {
      return 'damage_not_verified';
    }
    if (recipe.kind == 'major_repair' &&
        (state.damagedUnits[recipe.targetId] ?? 0) <= 0) {
      return 'not_damaged';
    }
    if (recipe.kind == 'research' &&
        state.completedResearch.contains(recipe.targetId)) {
      return 'already_researched';
    }
    if (recipe.kind == 'major_repair' &&
        (state.packedStock['spare_part'] ?? 0) != 0) {
      return 'spares_need_unpacking';
    }
    final credit =
        state.assistance[_recoveryId(state, recipe)] ??
        const <String, double>{};
    for (final e in recipe.cost.entries) {
      final amount = state.resources[e.key] ?? 0, aid = credit[e.key] ?? 0;
      if (!amount.isFinite ||
          amount < 0 ||
          !aid.isFinite ||
          aid < 0 ||
          aid > e.value) {
        return 'invalid_resource';
      }
      if (amount + aid < e.value) return 'insufficient_resources';
    }
    return null;
  }

  /// The updated snapshot is authoritative for countdown display. A read of the
  /// stored countdown never observes wall time or increases remaining work.
  ProgressionState reconcile(
    ProgressionState state, {
    required ClockObservation observation,
  }) {
    if (observation.token <= state.lastObservationToken) return state;
    final nowUtc = observation.utc;
    var next = state.copyWith(
      lastObservationToken: observation.token,
      lastObservedUtc: nowUtc,
      log: [
        ...state.log,
        if (state.lastObservedUtc != null &&
            nowUtc.toUtc().isBefore(state.lastObservedUtc!))
          'clock_rollback:${state.lastObservedUtc!.toIso8601String()}:${nowUtc.toUtc().toIso8601String()}',
      ],
    );
    final jobs = state.jobs.values.where((j) => j.status == 'active').toList()
      ..sort((a, b) {
        final order = a.deadlineUtc!.compareTo(b.deadlineUtc!);
        return order == 0 ? a.id.compareTo(b.id) : order;
      });
    for (final job in jobs) {
      final clock = job.clock!.observe(observation);
      // Never apply a repair against damage substituted outside the observation
      // boundary. Keep the reservation and payment for a diagnosable retry.
      if (job.recipe.kind == 'major_repair' &&
          (job.repairDamageId == null ||
              (next.damageObservations[job.repairDamageId]?.remaining ?? 0) <=
                  0 ||
              !_damageConsistent(next, job.recipe.targetId))) {
        next = next.copyWith(
          jobs: {
            ...next.jobs,
            job.id: job.withStatus(
              'active',
              clock: clock,
              reason: 'damage_not_verified',
            ),
          },
          log: [...next.log, 'repair_damage_mismatch:${job.id}'],
        );
        continue;
      }
      if (!TimerCompletion.canApply(
            id: job.id,
            status: job.status,
            completedIds: next.completedActivityIds,
          ) ||
          !clock.isDue) {
        next = next.copyWith(
          jobs: {
            ...next.jobs,
            job.id: job.withStatus(job.status, clock: clock),
          },
        );
        continue;
      }
      final facilities = {...next.facilities},
          tiers = {...next.upgradeTiers},
          damage = {...next.damagedUnits},
          confirmed = {...next.confirmedDamage};
      final research = {...next.completedResearch};
      final operating = {...next.operatingStates};
      final target = job.recipe.targetId;
      switch (job.recipe.kind) {
        case 'construction':
          if ((facilities[target] ?? 0) == 0 &&
              [
                null,
                'notBuilt',
                'underConstruction',
              ].contains(operating[target])) {
            operating[target] = (damage[target] ?? 0) > 0
                ? 'damaged'
                : 'operating';
          }
          facilities[target] = (facilities[target] ?? 0) + 1;
        case 'upgrade':
          tiers[target] = 1;
        case 'major_repair':
          next = _resolveDamage(next, job.repairDamageId!);
          damage.clear();
          damage.addAll(next.damagedUnits);
          confirmed.clear();
          confirmed.addAll(next.confirmedDamage);
        case 'research':
          research.add(target);
      }
      next = next.copyWith(
        facilities: facilities,
        operatingStates: operating,
        upgradeTiers: tiers,
        damagedUnits: damage,
        confirmedDamage: confirmed,
        completedResearch: research,
        completedActivityIds: {...next.completedActivityIds, job.id},
        jobs: {
          ...next.jobs,
          job.id: job.withStatus(
            'completed',
            clock: clock,
            finished: nowUtc.toUtc(),
          ),
        },
        receipts: {
          ...next.receipts,
          'complete:${job.id}': const ProgressionReceipt('complete', 0),
        },
      );
    }
    return _deliverPending(next);
  }

  Duration remaining(ProgressionState state, String jobId) {
    final job = state.jobs[jobId];
    return job?.status == 'active' ? job!.clock!.remaining : Duration.zero;
  }

  ProgressionResult cancel(
    ProgressionState state, {
    required String jobId,
    required ClockObservation observation,
  }) {
    if (observation.token <= state.lastObservationToken) {
      return ProgressionResult(state, 'stale_observation');
    }
    var next = reconcile(state, observation: observation);
    final job = next.jobs[jobId];
    if (job == null || ['completed', 'cancelled'].contains(job.status)) {
      return ProgressionResult(next, 'not_cancellable');
    }
    final resources = {...next.resources},
        pending = {...next.pending},
        stock = {...next.packedStock};
    final credit = {...?next.assistance[job.recoveryId]};
    if (job.status == 'active') {
      for (final e in job.paid.entries) {
        var refund = e.value * config.refundFraction;
        if (config.indivisible.contains(e.key)) refund = refund.floorToDouble();
        if (e.key == 'materials') {
          pending[e.key] = (pending[e.key] ?? 0) + refund;
        } else {
          resources[e.key] = (resources[e.key] ?? 0) + refund;
        }
      }
      for (final e in job.assistancePaid.entries) {
        credit[e.key] = (credit[e.key] ?? 0) + e.value;
      }
      for (final e in job.reservedStock.entries) {
        stock[e.key] = (stock[e.key] ?? 0) + e.value;
      }
    }
    next = next.copyWith(
      operatingStates: {
        ...next.operatingStates,
        if (job.status == 'active' &&
            job.recipe.kind == 'construction' &&
            (next.facilities[job.recipe.targetId] ?? 0) == 0 &&
            next.operatingStates[job.recipe.targetId] == 'underConstruction')
          job.recipe.targetId: 'notBuilt',
      },
      resources: resources,
      pending: pending,
      packedStock: stock,
      assistance: {
        ...next.assistance,
        if (job.recoveryId != null) job.recoveryId!: credit,
      },
      jobs: {
        ...next.jobs,
        jobId: job.withStatus('cancelled', finished: observation.utc),
      },
      receipts: {
        ...next.receipts,
        'cancel:$jobId': const ProgressionReceipt('cancel', 0),
      },
    );
    return ProgressionResult(_deliverPending(next), 'cancelled');
  }

  /// The optional identity is a selector, never authority. Only configuration-
  /// derived mandatory objectives and confirmed catalogue damage can qualify.
  ProgressionResult recover(ProgressionState state, {String? identity}) {
    var next = _deliverPending(state);
    final candidates =
        config.recipes.values
            .where(
              (r) =>
                  _recoveryId(next, r) != null &&
                  config.levels.contains(next.levelId) &&
                  (r.kind == 'major_repair' ||
                      config.levels.indexOf(r.levelId) <=
                          config.levels.indexOf(next.levelId)) &&
                  r.buildings.every((id) => (next.facilities[id] ?? 0) > 0) &&
                  next.completedResearch.containsAll(r.research),
            )
            .toList()
          ..sort((a, b) {
            final c = (a.cost['materials'] ?? 0).compareTo(
              b.cost['materials'] ?? 0,
            );
            return c == 0 ? a.key.compareTo(b.key) : c;
          });
    if (identity != null) {
      candidates.removeWhere((r) => _recoveryId(next, r) != identity);
    }
    if (candidates.isEmpty) {
      return ProgressionResult(
        next,
        identity == null ? 'no_required_facility' : 'invalid_recovery_identity',
      );
    }
    for (final recipe in candidates) {
      final id = _recoveryId(next, recipe)!;
      if (next.jobs.values.any(
        (j) =>
            j.status == 'active' &&
            (j.recoveryId == id ||
                (recipe.kind == 'major_repair' &&
                    j.repairDamageId == id.substring('repair:'.length))),
      )) {
        continue;
      }
      final credit = {...?next.assistance[id]};
      var granted = 0.0;
      for (final e in recipe.cost.entries) {
        final ordinary = next.resources[e.key] ?? 0,
            existing = credit[e.key] ?? 0;
        if (!ordinary.isFinite ||
            ordinary < 0 ||
            !existing.isFinite ||
            existing < 0 ||
            existing > e.value) {
          return ProgressionResult(next, 'invalid_resource');
        }
        final shortfall = math.max(0.0, e.value - ordinary - existing);
        credit[e.key] = existing + shortfall;
        granted += shortfall;
      }
      if (granted == 0) continue;
      final key = 'assistance:$id';
      next = next.copyWith(
        assistance: {...next.assistance, id: credit},
        receipts: {
          ...next.receipts,
          key: ProgressionReceipt(
            'assistance',
            (next.receipts[key]?.amount ?? 0) + granted,
            targetId: recipe.targetId,
          ),
        },
        log: [...next.log, 'assistance:$id:$granted'],
      );
      return ProgressionResult(next, 'assistance_granted');
    }
    return ProgressionResult(next, 'not_needed');
  }

  ProgressionState _grant(
    ProgressionState state,
    String id,
    double amount,
    String kind, {
    String? level,
  }) => state.copyWith(
    pending: {
      ...state.pending,
      'materials': (state.pending['materials'] ?? 0) + amount,
    },
    receipts: {
      ...state.receipts,
      id: ProgressionReceipt(kind, amount, levelId: level),
    },
  );

  ProgressionState _deliverPending(ProgressionState state) {
    final pending = state.pending['materials'] ?? 0;
    if (!pending.isFinite ||
        pending <= 0 ||
        !state.materials.isFinite ||
        state.materials < 0) {
      return state;
    }
    final amount = math
        .min(pending, math.max(0, config.materialCapacity - state.materials))
        .toDouble();
    if (amount <= 0) return state;
    return state.copyWith(
      resources: {...state.resources, 'materials': state.materials + amount},
      pending: {...state.pending, 'materials': pending - amount},
    );
  }
}
