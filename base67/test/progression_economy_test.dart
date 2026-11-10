import 'dart:convert';
import 'dart:io';

import 'package:base67/progression/progression_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'progression_service_test.dart' show observation;

void main() {
  late ProgressionConfig config;
  late RealTimeProgressionService service;
  final now = DateTime.utc(2026, 11, 9);
  Map<String, dynamic> data(String name) =>
      jsonDecode(File('assets/data/extra/$name.json').readAsStringSync())
          as Map<String, dynamic>;
  setUp(() {
    config = ProgressionConfig.fromDocuments(
      equipment: jsonDecode(
        File('assets/data/equipment.json').readAsStringSync(),
      ) as Map<String, dynamic>,
      events: jsonDecode(
        File('assets/data/events.json').readAsStringSync(),
      ) as Map<String, dynamic>,
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
    observation: observation(state, state.lastObservedUtc ?? now),
  );
  ProgressionState finish(ProgressionState state, String id) =>
      service.reconcile(
        state,
        observation: observation(state, state.jobs[id]!.deadlineUtc!),
      );

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
    expect(
      state.receipts.keys.any((id) => id.startsWith('assistance:')),
      isFalse,
    );
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
    state = service
        .cancel(state, jobId: 'full', observation: observation(state, now))
        .state;
    expect(state.materials, 200);
    expect(state.pending['materials'], 17);
    expect(service.resupply(state).pending, state.pending);
    expect(
      state.receipts.keys.where((id) => id.startsWith('assistance:')),
      isEmpty,
    );
  });

  test(
    'repeated ordinary cancellations recover a bounded restricted shortfall',
    () {
      var state = initial();
      var cancellations = 0;
      while (state.materials >= 5) {
        final id = 'cancel:${cancellations++}';
        state = service
            .cancel(
              start(state, id).state,
              jobId: id,
              observation: observation(start(state, id).state, now),
            )
            .state;
      }
      expect(cancellations, 26);
      expect(state.materials, 2);
      state = service.recover(state).state;
      expect(state.materials, 2);
      expect(state.restrictedMaterials, 3);
      expect(service.recover(state).code, 'not_needed');
      state = finish(start(state, 'rescued').state, 'rescued');
      expect(state.facilities['solar_array'], 1);
      expect(service.recover(state).code, 'no_required_facility');
    },
  );

  test(
    'assistance cannot fund optional upgrades or cheaper custom research',
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
          equipment: jsonDecode(
            File('assets/data/equipment.json').readAsStringSync(),
          ) as Map<String, dynamic>,
          events: jsonDecode(
            File('assets/data/events.json').readAsStringSync(),
          ) as Map<String, dynamic>,
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
      expect(state.materials, 0);
      expect(state.restrictedMaterials, 4);
      for (final kind in ['upgrade', 'research']) {
        final result = custom.start(
          state,
          jobId: kind,
          kind: kind,
          targetId: kind == 'upgrade'
              ? 'solar_array'
              : 'solar_energy_fundamentals',
          observation: observation(state, now),
        );
        expect(result.code, 'insufficient_resources');
        expect(result.state.resources, state.resources);
        expect(result.state.assistance, state.assistance);
      }
    },
  );

  test('unrelated research does not suppress recovery and queued work holds nothing', () {
    var state = initial().copyWith(resources: {'materials': 0});
    state = service
        .start(
          state,
          jobId: 'research',
          kind: 'research',
          targetId: 'solar_energy_fundamentals',
          observation: observation(state, now),
        )
        .state;
    state = service
        .enqueue(
          state,
          jobId: 'queued',
          kind: 'construction',
          targetId: 'solar_array',
        )
        .state;
    expect(state.jobs['queued']!.paid, isEmpty);
    expect(state.crewAssignments, isEmpty);
    state = service.recover(state).state;
    expect(state.restrictedMaterials, 5);
    expect(start(state, 'alongside').code, 'active');
  });

  test('fully assisted cancellation is repeatable without a dead end or ordinary farming', () {
    var state = service
        .recover(initial().copyWith(resources: {'materials': 0}))
        .state;
    for (var retry = 0; retry < 30; retry++) {
      final id = 'assisted:$retry';
      final active = start(state, id);
      expect(active.code, 'active');
      state = service
          .cancel(
            active.state,
            jobId: id,
            observation: observation(active.state, now),
          )
          .state;
      expect(state.materials, 0);
      expect(state.restrictedMaterials, 5);
      final again = service.cancel(
        state,
        jobId: id,
        observation: observation(state, now),
      );
      expect(again.state.assistance, state.assistance);
      expect(service.recover(state).code, 'not_needed');
      expect(
        state.receipts.keys.where((id) => id.startsWith('assistance:')).length,
        1,
      );
    }
    state = finish(start(state, 'finish').state, 'finish');
    expect(state.facilities['solar_array'], 1);
    expect(state.restrictedMaterials, 0);
    expect(service.recover(state).code, 'no_required_facility');
    expect(start(state, 'optional-second').code, 'insufficient_resources');
  });

  test(
    'mixed cancellations top up only the same eligible recipe shortfall',
    () {
      var state = service
          .recover(initial().copyWith(resources: {'materials': 2}))
          .state;
      for (var i = 0; i < 10; i++) {
        state = service
            .cancel(
              start(state, 'mixed:$i').state,
              jobId: 'mixed:$i',
              observation: observation(start(state, 'mixed:$i').state, now),
            )
            .state;
        state = service.recover(state).state;
        expect(state.materials + state.restrictedMaterials, 5);
        expect(state.restrictedMaterials <= 5, isTrue);
      }
      expect(state.materials, 0);
      expect(state.restrictedMaterials, 5);
      expect(
        state.receipts['assistance:construction:solar_array:1']!.amount,
        5,
      );
    },
  );

  test(
    'several required facilities recover in one level, including prerequisites',
    () {
      var state = initial(level: config.levels[2])
          .copyWith(resources: {'materials': 0});
      for (final target in [
        'battery_bank',
        'solar_array',
        'power_control_station',
      ]) {
        final recovery = service.recover(state);
        expect(recovery.code, 'assistance_granted');
        state = recovery.state;
        final active = start(state, 'required:$target', target: target);
        expect(active.code, 'active');
        state = finish(active.state, 'required:$target');
        expect(state.facilities[target], 1);
        expect(state.materials, 0);
      }
      expect(service.recover(state).code, 'no_required_facility');
      expect(
        state.receipts.keys.where((id) => id.startsWith('assistance:')).length,
        3,
      );
    },
  );

  test('completed required work cannot grant for optional units, upgrades or research', () {
    final state = initial(level: config.levels.last).copyWith(
      resources: {'materials': 0},
      facilities: {for (final id in config.requiredFacilities) id: 1},
    );
    expect(service.recover(state).code, 'no_required_facility');
    expect(service.recover(state).state.assistance, isEmpty);
  });

  test('greenhouse assistance covers its actual eight-unit recipe, not a level cap', () {
    var state = initial(level: config.levels[5]).copyWith(
      resources: {'materials': 0},
      facilities: {
        'solar_array': 1,
        'battery_bank': 1,
        'power_control_station': 1,
        'maintenance_bay': 1,
      },
    );
    state = service.recover(state).state;
    expect(state.restrictedMaterials, 8);
    state = finish(
      start(state, 'greenhouse', target: 'greenhouse').state,
      'greenhouse',
    );
    expect(state.facilities['greenhouse'], 1);
    expect(state.materials, 0);
    expect(state.restrictedMaterials, 0);
  });

  test('unidentified observed damage cannot mint repair assistance', () {
    final state = initial().copyWith(
      resources: {'materials': 0, 'spare_part': 0},
      facilities: {'solar_array': 1},
      damagedUnits: {'solar_array': 1},
    );
    expect(service.recover(state).code, 'no_required_facility');
    expect(
      start(state, 'repair', kind: 'major_repair').code,
      'insufficient_resources',
    );
    expect(service.confirmDamage(state, 'invented').code, 'unknown_damage');
    expect(
      service.recover(state, identity: 'repair:invented').state.assistance,
      isEmpty,
    );
  });

  test(
    'changing levels neither duplicates nor converts an objective entitlement',
    () {
      var state = service
          .recover(initial().copyWith(resources: {'materials': 0}))
          .state;
      final id = service.constructionObjective('solar_array');
      for (final level in [
        config.levels[1],
        config.levels.first,
        config.levels[2],
      ]) {
        state = service
            .recover(state.copyWith(levelId: level), identity: id)
            .state;
        expect(state.assistance[id]!['materials'], 5);
        expect(state.materials, 0);
      }
      state = finish(start(state, 'required').state, 'required');
      expect(
        service.recover(state, identity: id).code,
        'invalid_recovery_identity',
      );
    },
  );
}
