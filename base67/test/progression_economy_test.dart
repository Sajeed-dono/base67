import 'dart:convert';
import 'dart:io';

import 'package:base67/progression/progression_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProgressionConfig config;
  late RealTimeProgressionService service;
  final now = DateTime.utc(2026, 11, 9);
  Map<String, dynamic> data(String name) =>
      jsonDecode(File('assets/data/extra/$name.json').readAsStringSync())
          as Map<String, dynamic>;
  setUp(() {
    config = ProgressionConfig.fromDocuments(
      buildings: data('buildings'),
      research: data('research'),
      timers: data('timer_rules'),
      crew: data('crew_assignments'),
      rules: data('progression_rules'),
    );
    service = RealTimeProgressionService(config);
  });
  ProgressionState initial({String? level}) =>
      service.resupply(ProgressionState(levelId: level ?? config.levels.first));
  ProgressionResult start(
    ProgressionState state,
    String id, {
    String target = 'solar_array',
    String kind = 'construction',
  }) => service.start(
    state,
    jobId: id,
    kind: kind,
    targetId: target,
    nowUtc: state.lastObservedUtc ?? now,
  );
  ProgressionState finish(ProgressionState state, String id) =>
      service.reconcile(state, nowUtc: state.jobs[id]!.deadlineUtc!);

  test('resupply start 80, capacity 200, +10 once for levels 1-14; level 15 and replays grant nothing', () {
    var state = initial();
    expect(state.materials, 80);
    for (final level in config.levels) {
      state = service.resupply(
        state.copyWith(completedLevels: {...state.completedLevels, level}),
      );
    }
    expect(state.materials, 200);
    expect(state.pending['materials'], 20);
    expect(
      state.receipts.keys
          .where(
            (id) =>
                id.startsWith('resupply:') &&
                !['resupply:start', 'resupply:catch_up'].contains(id),
          )
          .length,
      14,
    );
    final repeated = service.resupply(state);
    expect(repeated.resources, state.resources);
    expect(repeated.pending, state.pending);
    expect(repeated.receipts.length, state.receipts.length);
  });

  test('one-time catch-up is deterministic, receipted and compatible with partially claimed missions', () {
    final completed = config.levels.take(3).toSet();
    final state = service.resupply(
      ProgressionState(levelId: config.levels[3], completedLevels: completed),
    );
    expect(state.materials, 110);
    expect(state.receipts['resupply:catch_up']!.amount, 30);
    expect(service.resupply(state).materials, 110);
    final partial = ProgressionState(
      levelId: config.levels[3],
      completedLevels: completed,
      resources: {'materials': 90},
      receipts: {
        'resupply:start': const ProgressionReceipt('resupply', 80),
        'resupply:${config.levels.first}': const ProgressionReceipt(
          'resupply',
          10,
        ),
      },
    );
    final caught = service.resupply(partial);
    expect(caught.materials, 110);
    expect(caught.receipts['resupply:catch_up']!.amount, 20);
    expect(caught.receipts.keys, containsAll(state.receipts.keys));
  });

  test('all 11 baseline facilities are affordable before each mission reward; total cost 62', () {
    var state = initial();
    var spent = 0.0;
    for (final level in config.levels) {
      state = state.copyWith(levelId: level);
      final recipes = config.recipes.values
          .where((r) => r.kind == 'construction' && r.levelId == level)
          .toList();
      for (final recipe in recipes) {
        final result = start(
          state,
          'baseline:${recipe.targetId}',
          target: recipe.targetId,
        );
        expect(
          result.code,
          'active',
          reason: '$level/${recipe.targetId}: ${state.materials} materials',
        );
        spent += recipe.cost['materials']!;
        state = finish(result.state, 'baseline:${recipe.targetId}');
      }
      state = service.resupply(
        state.copyWith(completedLevels: {...state.completedLevels, level}),
      );
    }
    expect(spent, 62);
    expect(state.facilities.keys.toSet(), config.requiredFacilities);
    expect(state.materials, 158);
    expect(state.receipts.keys.any((id) => id.startsWith('salvage:')), isFalse);
  });

  test(
    'starting materials alone cover the baseline without mission rewards',
    () {
      var state = initial(level: config.levels.last);
      for (final recipe in config.recipes.values.where(
        (r) => r.kind == 'construction',
      )) {
        final id = 'baseline:${recipe.targetId}';
        final result = start(state, id, target: recipe.targetId);
        expect(result.code, 'active');
        state = finish(result.state, id);
      }
      expect(state.materials, 18);
    },
  );

  test('full storage retains grants and refunds and releases overflow when materials are spent', () {
    var state = service.resupply(
      ProgressionState(
        levelId: config.levels.first,
        completedLevels: config.resupplyLevels,
      ),
    );
    expect(state.materials, 200);
    expect(state.pending['materials'], 20);
    expect(service.recover(state).code, 'not_needed');
    state = start(state, 'full').state;
    expect(state.materials, 200);
    expect(state.pending['materials'], 15);
    state = service.cancel(state, jobId: 'full', nowUtc: now).state;
    expect(state.materials, 200);
    expect(state.pending['materials'], 17);
    expect(service.resupply(state).pending, state.pending);
    expect(
      state.receipts.keys.where((id) => id.startsWith('salvage:')),
      isEmpty,
    );
  });

  test('repeated cancellation counterexample is rescued once at level 1 without farming', () {
    var state = initial();
    var cancellations = 0;
    while (state.materials >= 5) {
      final id = 'cancel:${cancellations++}';
      final active = start(state, id);
      expect(active.code, 'active');
      state = service.cancel(active.state, jobId: id, nowUtc: now).state;
    }
    expect(cancellations, 26);
    expect(state.materials, 2);
    final recovery = service.recover(state);
    expect(recovery.code, 'salvage_granted');
    state = recovery.state;
    expect(state.materials, 5);
    expect(state.receipts['salvage:${config.levels.first}']!.amount, 3);
    expect(service.recover(state).state.materials, 5);
    state = finish(start(state, 'rescued').state, 'rescued');
    expect(state.facilities['solar_array'], 1);
    expect(service.recover(state).code, 'no_required_facility');
  });

  test('salvage is earmarked: optional upgrades cannot spend the grant', () {
    var state = initial(level: config.levels[1])
        .copyWith(resources: {'materials': 0}, facilities: {'solar_array': 1});
    state = service.recover(state).state;
    expect(state.materials, 4);
    expect(state.salvage['battery_bank'], 4);
    final upgraded = start(state, 'optional', kind: 'upgrade');
    expect(upgraded.code, 'insufficient_resources');
    expect(upgraded.state.materials, 4);
    state = finish(
      start(state, 'required', target: 'battery_bank').state,
      'required',
    );
    expect(state.facilities['battery_bank'], 1);
    expect(state.reservedMaterials, 0);
  });

  test('salvage requires no active job; queued or blocked jobs hold no crew or materials', () {
    var state = start(
      initial(),
      'active',
    ).state.copyWith(resources: {'materials': 0});
    expect(service.recover(state).code, 'active_job');
    state = service.cancel(state, jobId: 'active', nowUtc: now).state;
    final queued = service
        .enqueue(
          state,
          jobId: 'queued',
          kind: 'construction',
          targetId: 'solar_array',
        )
        .state;
    expect(service.recover(queued).code, 'salvage_granted');
  });

  test('once-per-level salvage cannot be farmed by cancelling salvage-funded work; reports remaining dead end', () {
    var state = initial().copyWith(resources: {'materials': 0});
    state = service.recover(state).state;
    state = service
        .cancel(start(state, 'salvaged').state, jobId: 'salvaged', nowUtc: now)
        .state;
    expect(state.materials, 2);
    expect(state.salvage['solar_array'], 2);
    for (var retry = 0; retry < 20; retry++) {
      final recovery = service.recover(state);
      expect(recovery.code, 'salvage_exhausted');
      expect(recovery.state.materials, 2);
      expect(
        recovery.state.receipts.keys
            .where((id) => id.startsWith('salvage:'))
            .length,
        1,
      );
      state = recovery.state;
    }
    expect(start(state, 'cannot-retry').code, 'insufficient_resources');
  });

  test('per-level salvage cap cannot rescue multiple requirements after resources were exhausted', () {
    var state = initial(level: config.levels[2])
        .copyWith(resources: {'materials': 0});
    state = service.recover(state).state;
    expect(
      state.receipts['salvage:${config.levels[2]}']!.amount,
      4,
    ); // Cheapest is battery.
    state = finish(
      start(state, 'battery', target: 'battery_bank').state,
      'battery',
    );
    expect(service.recover(state).code, 'salvage_exhausted');
    expect(start(state, 'solar').code, 'insufficient_resources');
  });

  test('salvage never grants for optional research/upgrades once required facilities exist', () {
    final state = initial(level: config.levels.last).copyWith(
      resources: {'materials': 0},
      facilities: {for (final id in config.requiredFacilities) id: 1},
    );
    expect(service.recover(state).code, 'no_required_facility');
    expect(service.recover(state).state.materials, 0);
  });

  test(
    'earmarks reject even affordable optional upgrade and research costs',
    () {
      final buildings = data('buildings');
      buildings['buildings'][0]['upgrade_cost']['materials'] = 1;
      final research = data('research');
      research['projects'][0]['cost'] = {'materials': 1};
      final custom = RealTimeProgressionService(
        ProgressionConfig.fromDocuments(
          buildings: buildings,
          research: research,
          timers: data('timer_rules'),
          crew: data('crew_assignments'),
          rules: data('progression_rules'),
        ),
      );
      final state = custom
          .recover(
            initial(level: config.levels[1]).copyWith(
              resources: {'materials': 0},
              facilities: {'solar_array': 1},
            ),
          )
          .state;
      expect(state.materials, 4);
      for (final kind in ['upgrade', 'research']) {
        final result = custom.start(
          state,
          jobId: kind,
          kind: kind,
          targetId: kind == 'upgrade'
              ? 'solar_array'
              : 'solar_energy_fundamentals',
          nowUtc: now,
        );
        expect(result.code, 'insufficient_resources');
        expect(result.state.materials, 4);
      }
    },
  );

  test(
    'salvage reaches the configured 8-unit cap for a greenhouse shortfall',
    () {
      var state = initial(level: config.levels[5]).copyWith(
        resources: {'materials': 0},
        facilities: {
          'solar_array': 1,
          'battery_bank': 1,
          'power_control_station': 1,
          'maintenance_bay': 1,
        },
      );
      final recovered = service.recover(state);
      expect(recovered.code, 'salvage_granted');
      expect(
        recovered.state.receipts['salvage:${config.levels[5]}']!.amount,
        8,
      );
      state = finish(
        start(recovered.state, 'greenhouse', target: 'greenhouse').state,
        'greenhouse',
      );
      expect(state.facilities['greenhouse'], 1);
      expect(state.materials, 0);
    },
  );

  test(
    'required-construction salvage does not rescue missing repair parts',
    () {
      final state = initial().copyWith(
        resources: {'materials': 0, 'spare_part': 0},
        facilities: {'solar_array': 1},
        damagedUnits: {'solar_array': 1},
      );
      expect(service.recover(state).code, 'no_required_facility');
      expect(
        start(
          state,
          'repair',
          target: 'solar_array',
          kind: 'major_repair',
        ).code,
        'insufficient_resources',
      );
    },
  );

  test('each later level has a distinct receipt but returning to an old level does not reset it', () {
    var state = service
        .recover(initial().copyWith(resources: {'materials': 0}))
        .state;
    final merelyChangedLevel = service.recover(
      state.copyWith(levelId: config.levels[1]),
    );
    expect(merelyChangedLevel.code, 'not_needed');
    expect(
      merelyChangedLevel.state.receipts.keys
          .where((id) => id.startsWith('salvage:'))
          .length,
      1,
    );
    state = finish(start(state, 'required-solar').state, 'required-solar');
    state = state.copyWith(levelId: config.levels[1]);
    state = service.recover(state).state;
    expect(
      state.receipts.keys.where((id) => id.startsWith('salvage:')).length,
      2,
    );
    final total = state.materials;
    state = state.copyWith(levelId: config.levels.first);
    expect(service.recover(state).state.materials, total);
  });
}
