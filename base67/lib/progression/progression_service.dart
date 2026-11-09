import 'dart:math' as math;

import 'timer_completion.dart';

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
    required this.salvageCap,
  }) : recipes = Map.unmodifiable(recipes),
       levels = List.unmodifiable(levels),
       resupplyLevels = Set.unmodifiable(resupplyLevels),
       indivisible = Set.unmodifiable(indivisible),
       requiredFacilities = Set.unmodifiable(requiredFacilities);

  final Map<String, ProgressionRecipe> recipes;
  final List<String> levels;
  final Set<String> resupplyLevels, indivisible, requiredFacilities;
  final int startMaterials, materialCapacity, missionMaterials, salvageCap;
  final double refundFraction;

  /// App-layer adapters will supply repository documents in 4B-2.
  factory ProgressionConfig.fromDocuments({
    required Map<String, dynamic> buildings,
    required Map<String, dynamic> research,
    required Map<String, dynamic> timers,
    required Map<String, dynamic> crew,
    required Map<String, dynamic> rules,
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
    final salvage = rules['salvage'] as Map;
    final capacity = _integer(materials['capacity']);
    final start = _integer(materials['start']);
    final fraction = _number(cancellation['refund_fraction']);
    final salvageCap = _integer(salvage['cap_per_level']);
    if (capacity <= 0 ||
        start > capacity ||
        fraction > 1 ||
        salvageCap <= 0 ||
        salvage['grants_per_level'] != 1 ||
        salvage['required_only'] != true ||
        salvage['earmark_for_required_construction'] != true) {
      throw const FormatException('Invalid economy rules');
    }
    final indivisible = Set<String>.from(
      cancellation['indivisible_resource_ids'],
    );
    if (!indivisible.contains('materials')) {
      throw const FormatException('Materials must be indivisible');
    }
    final roles = Map<String, String>.from(crew['job_roles']);
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
    return ProgressionConfig._(
      recipes: recipes,
      levels: levels,
      resupplyLevels: eligible,
      indivisible: indivisible,
      requiredFacilities: requiredFacilities,
      startMaterials: start,
      materialCapacity: capacity,
      missionMaterials: _integer(materials['per_first_mission']),
      refundFraction: fraction,
      salvageCap: salvageCap,
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

class ProgressionJob {
  ProgressionJob({
    required this.id,
    required this.recipe,
    this.crewId,
    this.status = 'queued',
    this.startedAtUtc,
    this.deadlineUtc,
    this.finishedAtUtc,
    Map<String, double> paid = const {},
    this.salvagePaid = 0,
    this.blockReason,
  }) : paid = Map.unmodifiable(paid);
  final String id;
  final ProgressionRecipe recipe;
  final String? crewId, blockReason;
  final String status;
  final DateTime? startedAtUtc, deadlineUtc, finishedAtUtc;
  final Map<String, double> paid;
  final double salvagePaid;

  ProgressionJob withStatus(
    String value, {
    DateTime? start,
    DateTime? end,
    DateTime? finished,
    Map<String, double>? paid,
    double? salvagePaid,
    String? reason,
  }) => ProgressionJob(
    id: id,
    recipe: recipe,
    crewId: crewId,
    status: value,
    startedAtUtc: start ?? startedAtUtc,
    deadlineUtc: end ?? deadlineUtc,
    finishedAtUtc: finished ?? finishedAtUtc,
    paid: paid ?? this.paid,
    salvagePaid: salvagePaid ?? this.salvagePaid,
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

/// Unwired immutable service state, NOT a CampaignSave schema or disk store.
/// 4B-2 must persist the whole aggregate, including every receipt and earmark.
class ProgressionState {
  ProgressionState({
    required this.levelId,
    Map<String, double> resources = const {},
    Map<String, double> pending = const {},
    Map<String, double> salvage = const {},
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
  }) : resources = Map.unmodifiable(resources),
       pending = Map.unmodifiable(pending),
       salvage = Map.unmodifiable(salvage),
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
  final Map<String, double> resources, pending, salvage;
  final Map<String, int> facilities, upgradeTiers, damagedUnits;
  final Map<String, String> crewRoles;
  final Set<String> completedLevels, completedResearch, completedActivityIds;
  final Map<String, ProgressionJob> jobs;
  final Map<String, ProgressionReceipt> receipts;
  final List<String> log;
  final DateTime? lastObservedUtc;
  double get materials => resources['materials'] ?? 0;
  double get reservedMaterials => salvage.values.fold(0, (a, b) => a + b);
  bool get hasActiveJob => jobs.values.any((job) => job.status == 'active');
  Map<String, String> get crewAssignments => Map.unmodifiable({
    for (final job in jobs.values)
      if (job.status == 'active' && job.crewId != null) job.crewId!: job.id,
  });

  ProgressionState copyWith({
    String? levelId,
    Map<String, double>? resources,
    Map<String, double>? pending,
    Map<String, double>? salvage,
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
  }) => ProgressionState(
    levelId: levelId ?? this.levelId,
    resources: resources ?? this.resources,
    pending: pending ?? this.pending,
    salvage: salvage ?? this.salvage,
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
    required DateTime nowUtc,
    String? crewId,
  }) {
    final queued = enqueue(
      state,
      jobId: jobId,
      kind: kind,
      targetId: targetId,
      crewId: crewId,
    );
    if (queued.code != 'queued') return queued;
    return activate(queued.state, jobId: jobId, nowUtc: nowUtc);
  }

  ProgressionResult activate(
    ProgressionState state, {
    required String jobId,
    required DateTime nowUtc,
  }) {
    var next = reconcile(state, nowUtc: nowUtc);
    final job = next.jobs[jobId];
    if (job == null || !['queued', 'blocked'].contains(job.status)) {
      return ProgressionResult(next, 'not_startable');
    }
    final reason = _blockedReason(next, job);
    if (reason != null) {
      next = next.copyWith(
        jobs: {
          ...next.jobs,
          jobId: job.withStatus('blocked', reason: reason),
        },
      );
      return ProgressionResult(next, reason);
    }
    final resources = {...next.resources};
    final salvage = {...next.salvage};
    final reserved =
        job.recipe.kind == 'construction' &&
            config.requiredFacilities.contains(job.recipe.targetId)
        ? math
              .min(next.reservedMaterials, job.recipe.cost['materials'] ?? 0)
              .toDouble()
        : 0.0;
    for (final entry in job.recipe.cost.entries) {
      resources[entry.key] = (resources[entry.key] ?? 0) - entry.value;
    }
    var reservedToSpend = reserved;
    final salvageIds = salvage.keys.toList()..sort();
    for (final id in salvageIds) {
      final spent = math.min(salvage[id]!, reservedToSpend).toDouble();
      salvage[id] = salvage[id]! - spent;
      reservedToSpend -= spent;
    }
    final now = next.lastObservedUtc!;
    next = next.copyWith(
      resources: resources,
      salvage: salvage,
      jobs: {
        ...next.jobs,
        jobId: job.withStatus(
          'active',
          start: now,
          end: now.add(job.recipe.duration),
          paid: job.recipe.cost,
          salvagePaid: reserved,
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
    if (!config.levels.contains(state.levelId) ||
        config.levels.indexOf(state.levelId) <
            config.levels.indexOf(recipe.levelId)) {
      return 'locked';
    }
    if (!recipe.buildings.every((id) => (state.facilities[id] ?? 0) > 0) ||
        !state.completedResearch.containsAll(recipe.research)) {
      return 'prerequisite';
    }
    if (job.crewId != null && state.crewAssignments.containsKey(job.crewId)) {
      return 'crew_busy';
    }
    if (state.jobs.values.any(
      (other) =>
          other.id != job.id &&
          other.status == 'active' &&
          other.recipe.targetId == recipe.targetId,
    )) {
      return 'target_busy';
    }
    if (recipe.kind == 'construction' &&
        (state.facilities[recipe.targetId] ?? 0) > 0) {
      return 'already_built';
    }
    if (recipe.kind == 'upgrade' &&
        (state.upgradeTiers[recipe.targetId] ?? 0) >= 1) {
      return 'already_upgraded';
    }
    if (recipe.kind == 'major_repair' &&
        (state.damagedUnits[recipe.targetId] ?? 0) <= 0) {
      return 'not_damaged';
    }
    if (recipe.kind == 'research' &&
        state.completedResearch.contains(recipe.targetId)) {
      return 'already_researched';
    }
    final usableSalvage =
        recipe.kind == 'construction' &&
            config.requiredFacilities.contains(recipe.targetId)
        ? state.reservedMaterials
        : 0.0;
    for (final cost in recipe.cost.entries) {
      var available = state.resources[cost.key] ?? 0;
      if (!available.isFinite || available < 0) return 'invalid_resource';
      if (cost.key == 'materials') {
        available -= state.reservedMaterials - usableSalvage;
      }
      if (available < cost.value) return 'insufficient_resources';
    }
    return null;
  }

  /// Completes active jobs only. Queued work never retroactively starts offline.
  ProgressionState reconcile(
    ProgressionState state, {
    required DateTime nowUtc,
  }) {
    final now = TimerCompletion.effectiveUtc(nowUtc, state.lastObservedUtc);
    var next = state.copyWith(lastObservedUtc: now);
    final jobs = state.jobs.values.where((j) => j.status == 'active').toList()
      ..sort((a, b) {
        final order = (a.deadlineUtc ?? now).compareTo(b.deadlineUtc ?? now);
        return order == 0 ? a.id.compareTo(b.id) : order;
      });
    for (final job in jobs) {
      if (!TimerCompletion.canComplete(
        id: job.id,
        status: job.status,
        completedIds: next.completedActivityIds,
        deadlineUtc: job.deadlineUtc,
        nowUtc: now,
      )) {
        continue;
      }
      final facilities = {...next.facilities},
          tiers = {...next.upgradeTiers},
          damage = {...next.damagedUnits};
      final research = {...next.completedResearch};
      final target = job.recipe.targetId;
      switch (job.recipe.kind) {
        case 'construction':
          facilities[target] = (facilities[target] ?? 0) + 1;
        case 'upgrade':
          tiers[target] = 1;
        case 'major_repair':
          damage[target] = math.max(0, (damage[target] ?? 0) - 1);
        case 'research':
          research.add(target);
      }
      next = next.copyWith(
        facilities: facilities,
        upgradeTiers: tiers,
        damagedUnits: damage,
        completedResearch: research,
        completedActivityIds: {...next.completedActivityIds, job.id},
        jobs: {
          ...next.jobs,
          job.id: job.withStatus('completed', finished: job.deadlineUtc),
        },
        receipts: {
          ...next.receipts,
          'complete:${job.id}': const ProgressionReceipt('complete', 0),
        },
      );
    }
    return _deliverPending(next);
  }

  Duration remaining(ProgressionState state, String jobId, DateTime nowUtc) {
    final job = state.jobs[jobId];
    if (job == null || job.status != 'active' || job.deadlineUtc == null) {
      return Duration.zero;
    }
    final now = TimerCompletion.effectiveUtc(nowUtc, state.lastObservedUtc);
    return TimerCompletion.isDue(deadlineUtc: job.deadlineUtc!, nowUtc: now)
        ? Duration.zero
        : job.deadlineUtc!.difference(now);
  }

  ProgressionResult cancel(
    ProgressionState state, {
    required String jobId,
    required DateTime nowUtc,
  }) {
    var next = reconcile(state, nowUtc: nowUtc); // Due completion wins.
    final job = next.jobs[jobId];
    if (job == null || ['completed', 'cancelled'].contains(job.status)) {
      return ProgressionResult(next, 'not_cancellable');
    }
    final resources = {...next.resources},
        pending = {...next.pending},
        salvage = {...next.salvage};
    if (job.status == 'active') {
      for (final entry in job.paid.entries) {
        var refund = entry.value * config.refundFraction;
        if (config.indivisible.contains(entry.key)) {
          refund = refund.floorToDouble();
        }
        if (entry.key == 'materials') {
          pending[entry.key] = (pending[entry.key] ?? 0) + refund;
          // Protect the earmarked part of a refund from optional spending.
          final restricted = math.min(
            refund,
            (job.salvagePaid * config.refundFraction).floorToDouble(),
          );
          salvage[job.recipe.targetId] =
              (salvage[job.recipe.targetId] ?? 0) + restricted;
        } else {
          resources[entry.key] = (resources[entry.key] ?? 0) + refund;
        }
      }
    }
    next = next.copyWith(
      resources: resources,
      pending: pending,
      salvage: salvage,
      jobs: {
        ...next.jobs,
        jobId: job.withStatus('cancelled', finished: next.lastObservedUtc),
      },
      receipts: {
        ...next.receipts,
        'cancel:$jobId': const ProgressionReceipt('cancel', 0),
      },
    );
    return ProgressionResult(_deliverPending(next), 'cancelled');
  }

  /// One shortfall grant per level, earmarked for required construction only.
  ProgressionResult recover(ProgressionState state) {
    final next = _deliverPending(state);
    if (!next.materials.isFinite ||
        next.materials < 0 ||
        next.salvage.values.any((value) => !value.isFinite || value < 0)) {
      return ProgressionResult(next, 'invalid_resource');
    }
    if (next.hasActiveJob) return ProgressionResult(next, 'active_job');
    if (!config.levels.contains(next.levelId)) {
      return ProgressionResult(next, 'unknown_level');
    }
    final candidates =
        config.recipes.values
            .where(
              (recipe) =>
                  recipe.kind == 'construction' &&
                  config.requiredFacilities.contains(recipe.targetId) &&
                  (next.facilities[recipe.targetId] ?? 0) == 0 &&
                  config.levels.indexOf(recipe.levelId) <=
                      config.levels.indexOf(next.levelId) &&
                  recipe.buildings.every(
                    (id) => (next.facilities[id] ?? 0) > 0,
                  ),
            )
            .toList()
          ..sort((a, b) {
            final order = (a.cost['materials'] ?? 0).compareTo(
              b.cost['materials'] ?? 0,
            );
            return order == 0 ? a.targetId.compareTo(b.targetId) : order;
          });
    if (candidates.isEmpty) {
      return ProgressionResult(next, 'no_required_facility');
    }
    final recipe = candidates.first;
    final cost = recipe.cost['materials'] ?? 0;
    final available = next.materials;
    if (available >= cost) return ProgressionResult(next, 'not_needed');
    final receiptId = 'salvage:${next.levelId}';
    if (next.receipts.containsKey(receiptId)) {
      return ProgressionResult(next, 'salvage_exhausted');
    }
    final amount = math.min(cost - available, config.salvageCap).toDouble();
    if (next.materials + amount > config.materialCapacity) {
      return ProgressionResult(next, 'storage_blocked');
    }
    final recovered = next.copyWith(
      resources: {...next.resources, 'materials': next.materials + amount},
      salvage: {
        ...next.salvage,
        recipe.targetId: (next.salvage[recipe.targetId] ?? 0) + amount,
      },
      receipts: {
        ...next.receipts,
        receiptId: ProgressionReceipt(
          'salvage',
          amount,
          targetId: recipe.targetId,
          levelId: next.levelId,
        ),
      },
      log: [...next.log, 'salvage:${next.levelId}:${recipe.targetId}:$amount'],
    );
    return ProgressionResult(
      recovered,
      amount < cost - available ? 'salvage_capped' : 'salvage_granted',
    );
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
