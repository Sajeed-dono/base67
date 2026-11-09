import 'dart:convert';
import 'dart:io';

import 'package:base67/app/campaign_save.dart';
import 'package:base67/progression/progression_service.dart';
import 'package:base67/progression/timer_completion.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> document(String name) =>
    jsonDecode(File('assets/data/extra/$name.json').readAsStringSync())
        as Map<String, dynamic>;

ProgressionConfig configuration({
  Map<String, dynamic>? buildings,
  Map<String, dynamic>? research,
  Map<String, dynamic>? timers,
  Map<String, dynamic>? rules,
}) => ProgressionConfig.fromDocuments(
  buildings: buildings ?? document('buildings'),
  research: research ?? document('research'),
  timers: timers ?? document('timer_rules'),
  crew: document('crew_assignments'),
  rules: rules ?? document('progression_rules'),
);

void main() {
  late ProgressionConfig config;
  late RealTimeProgressionService service;
  final now = DateTime.utc(2026, 11, 9, 12);
  setUp(() {
    config = configuration();
    service = RealTimeProgressionService(config);
  });

  ProgressionState initial({String? level}) => service.resupply(
    ProgressionState(
      levelId: level ?? config.levels.last,
      crewRoles: const {'engineer': 'Engineer', 'scientist': 'Scientist'},
      resources: const {'oxygen': 19, 'water': 29, 'food': 39, 'spare_part': 3},
    ),
  );

  ProgressionResult build(
    ProgressionState state,
    String id,
    String target, {
    String? crewId,
  }) => service.start(
    state,
    jobId: id,
    kind: 'construction',
    targetId: target,
    nowUtc: now,
    crewId: crewId,
  );

  test('provisional configuration resolves only existing facility IDs and sim research effects', () {
    expect(config.requiredFacilities.length, 11);
    expect(config.recipes.containsKey('construction:rover'), isFalse);
    expect(config.recipes.containsKey('construction:research_lab'), isFalse);
    expect(
      config.recipes.values.every((r) => r.duration > Duration.zero),
      isTrue,
    );
    final sim = document('sim_params')['research_bonuses'] as Map;
    for (final recipe in config.recipes.values.where(
      (r) => r.kind == 'research',
    )) {
      expect(sim.containsKey(recipe.targetId), isTrue);
    }
  });

  test(
    'config rejects non-finite, negative, fractional and over-capacity costs',
    () {
      for (final value in [double.nan, double.infinity, -1, 1.5, 201]) {
        final data = document('buildings');
        data['buildings'][0]['cost']['materials'] = value;
        expect(() => configuration(buildings: data), throwsFormatException);
      }
    },
  );

  test('config rejects unknown prerequisites, cycles, and unavailable future prerequisites', () {
    for (final dependency in ['missing', 'solar_array', 'greenhouse']) {
      final data = document('buildings');
      data['buildings'][0]['prerequisite_building_ids'] = [dependency];
      expect(() => configuration(buildings: data), throwsFormatException);
    }
    final data = document('research');
    data['projects'][0]['prerequisites'] = ['advanced_battery_systems'];
    expect(() => configuration(research: data), throwsFormatException);
  });

  test('config rejects invalid timers, refunds and salvage caps', () {
    final timers = document('timer_rules');
    timers['timers'][0]['duration_seconds'] = 0;
    expect(() => configuration(timers: timers), throwsFormatException);
    for (final field in ['refund', 'cap']) {
      final rules = document('progression_rules');
      if (field == 'refund') {
        rules['cancellation']['refund_fraction'] = 1.1;
      } else {
        rules['salvage']['cap_per_level'] = 0;
      }
      expect(() => configuration(rules: rules), throwsFormatException);
    }
  });

  test('queue costs nothing, reserves no crew and starts only through explicit activation', () {
    final state = initial();
    var queued = service
        .enqueue(
          state,
          jobId: 'q',
          kind: 'construction',
          targetId: 'solar_array',
          crewId: 'engineer',
        )
        .state;
    expect(queued.materials, state.materials);
    expect(queued.crewAssignments, isEmpty);
    queued = service.reconcile(
      queued,
      nowUtc: now.add(const Duration(days: 2)),
    );
    expect(queued.jobs['q']!.status, 'queued');
    final started = service.activate(
      queued,
      jobId: 'q',
      nowUtc: now.add(const Duration(days: 2)),
    );
    expect(started.code, 'active');
    expect(started.state.materials, state.materials - 5);
    expect(
      started.state.jobs['q']!.startedAtUtc,
      now.add(const Duration(days: 2)),
    );
  });

  test('duplicate requests and activation never deduct twice or reuse a cancelled ID', () {
    final first = build(initial(), 'build', 'solar_array').state;
    expect(
      build(first, 'build', 'solar_array').state.materials,
      first.materials,
    );
    expect(
      service.activate(first, jobId: 'build', nowUtc: now).code,
      'not_startable',
    );
    final cancelled = service.cancel(first, jobId: 'build', nowUtc: now).state;
    expect(
      build(cancelled, 'build', 'solar_array').code,
      'duplicate_or_invalid_id',
    );
  });

  test('construction completes once across a replacement service and repeated completion attempts', () {
    final active = build(
      initial(),
      'build',
      'solar_array',
      crewId: 'engineer',
    ).state;
    expect(active.crewAssignments['engineer'], 'build');
    final deadline = active.jobs['build']!.deadlineUtc!;
    final restarted = RealTimeProgressionService(config);
    final completed = restarted.reconcile(active, nowUtc: deadline);
    final twice = restarted.reconcile(
      completed,
      nowUtc: deadline.add(const Duration(days: 3)),
    );
    expect(twice.facilities['solar_array'], 1);
    expect(twice.completedActivityIds, {'build'});
    expect(twice.receipts.containsKey('complete:build'), isTrue);
    expect(twice.materials, active.materials);
    expect(twice.crewAssignments, isEmpty);
    expect(twice.jobs['build']!.finishedAtUtc, deadline);
    expect(build(twice, 'second', 'solar_array').code, 'already_built');
  });

  test('crew exclusivity, wrong roles and target conflicts are rechecked on activation', () {
    var state = build(
      initial(),
      'solar',
      'solar_array',
      crewId: 'engineer',
    ).state;
    expect(
      build(state, 'battery', 'battery_bank', crewId: 'engineer').code,
      'crew_busy',
    );
    expect(build(state, 'same-target', 'solar_array').code, 'target_busy');
    expect(
      build(state, 'wrong-role', 'battery_bank', crewId: 'scientist').code,
      'wrong_crew_role',
    );
    expect(
      build(state, 'unknown-crew', 'battery_bank', crewId: 'missing').code,
      'wrong_crew_role',
    );
    state = service.cancel(state, jobId: 'solar', nowUtc: now).state;
    expect(
      build(state, 'new-battery', 'battery_bank', crewId: 'engineer').code,
      'active',
    );
  });

  test('locked, missing prerequisites and unknown facilities are blocked without costs', () {
    final state = initial(level: config.levels.first);
    expect(build(state, 'battery', 'battery_bank').code, 'locked');
    expect(
      build(initial(), 'control', 'power_control_station').code,
      'prerequisite',
    );
    expect(build(state, 'rover', 'rover').code, 'unknown_recipe');
    expect(build(state, 'rover', 'rover').state.materials, state.materials);
  });

  test('insufficient resources leave a blocked job unpaid and crew free', () {
    final state = initial(level: config.levels.first)
        .copyWith(resources: {'materials': 0});
    final blocked = build(state, 'solar', 'solar_array', crewId: 'engineer');
    expect(blocked.code, 'insufficient_resources');
    expect(blocked.state.jobs['solar']!.paid, isEmpty);
    expect(blocked.state.crewAssignments, isEmpty);
    final recovered = service.recover(blocked.state).state;
    expect(
      service.activate(recovered, jobId: 'solar', nowUtc: now).code,
      'active',
    );
  });

  test('offline interval completes jobs without changing survival quantities or running simulation', () {
    final before = initial();
    final active = build(before, 'solar', 'solar_array').state;
    final after = service.reconcile(
      active,
      nowUtc: now.add(const Duration(days: 300)),
    );
    for (final resource in ['oxygen', 'water', 'food']) {
      expect(after.resources[resource], before.resources[resource]);
    }
    expect(after.jobs['solar']!.status, 'completed');
    final source = File('lib/progression/progression_service.dart')
        .readAsStringSync();
    for (final forbidden in [
      'package:flutter',
      'dart:io',
      'dart:ui',
      'DateTime.now',
      'Random(',
      '../sim/',
    ]) {
      expect(source.contains(forbidden), isFalse, reason: forbidden);
    }
  });

  test('rollback cannot increase remaining duration, shift deadlines or repeat completion', () {
    var state = build(initial(), 'solar', 'solar_array').state;
    final deadline = state.jobs['solar']!.deadlineUtc!;
    final half = now.add(const Duration(seconds: 150));
    state = service.reconcile(state, nowUtc: half);
    final remaining = service.remaining(state, 'solar', half);
    state = service.reconcile(
      state,
      nowUtc: now.subtract(const Duration(days: 1)),
    );
    expect(service.remaining(state, 'solar', now), remaining);
    expect(state.jobs['solar']!.deadlineUtc, deadline);
    state = service.reconcile(state, nowUtc: deadline);
    state = service.reconcile(state, nowUtc: now);
    expect(state.facilities['solar_array'], 1);
    expect(state.jobs['solar']!.status, 'completed');
  });

  test(
    'forward clock completes early as the accepted device-clock limitation',
    () {
      final active = build(initial(), 'solar', 'solar_array').state;
      expect(
        service
            .reconcile(active, nowUtc: now.add(const Duration(days: 1)))
            .facilities['solar_array'],
        1,
      );
    },
  );

  test('cancellation floors indivisible refunds, loses time and frees crew immediately', () {
    final state = build(
      initial(),
      'solar',
      'solar_array',
      crewId: 'engineer',
    ).state;
    final cancelled = service
        .cancel(
          state,
          jobId: 'solar',
          nowUtc: now.add(const Duration(seconds: 299)),
        )
        .state;
    expect(cancelled.materials, 77); // 80 - 5 + floor(5 * .5).
    expect(cancelled.facilities['solar_array'], isNull);
    expect(cancelled.crewAssignments, isEmpty);
    expect(cancelled.jobs['solar']!.status, 'cancelled');
    expect(
      service
          .reconcile(cancelled, nowUtc: now.add(const Duration(days: 1)))
          .facilities,
      isEmpty,
    );
    expect(
      service.cancel(cancelled, jobId: 'solar', nowUtc: now).state.materials,
      77,
    );
    final fresh = build(cancelled, 'retry', 'solar_array').state;
    expect(
      fresh.jobs['retry']!.deadlineUtc,
      cancelled.lastObservedUtc!.add(const Duration(seconds: 300)),
    );
  });

  test('queued and blocked cancellation refund nothing; completed and missing jobs cannot cancel', () {
    final queued = service
        .enqueue(
          initial(),
          jobId: 'queued',
          kind: 'construction',
          targetId: 'solar_array',
        )
        .state;
    expect(
      service.cancel(queued, jobId: 'queued', nowUtc: now).state.materials,
      queued.materials,
    );
    final blocked = build(initial(), 'control', 'power_control_station').state;
    expect(
      service.cancel(blocked, jobId: 'control', nowUtc: now).state.materials,
      blocked.materials,
    );
    final active = build(initial(), 'solar', 'solar_array').state;
    final atDue = service.cancel(
      active,
      jobId: 'solar',
      nowUtc: active.jobs['solar']!.deadlineUtc!,
    );
    expect(atDue.code, 'not_cancellable');
    expect(atDue.state.jobs['solar']!.status, 'completed');
    expect(atDue.state.materials, 75);
    expect(
      service.cancel(atDue.state, jobId: 'missing', nowUtc: now).code,
      'not_cancellable',
    );
  });

  test('research prerequisites, single activation and duplicate completion use existing IDs', () {
    var state = initial();
    ProgressionResult research(String id, String target) => service.start(
      state,
      jobId: id,
      kind: 'research',
      targetId: target,
      nowUtc: state.lastObservedUtc ?? now,
      crewId: 'scientist',
    );
    expect(research('locked', 'advanced_battery_systems').code, 'prerequisite');
    state = research('solar-research', 'solar_energy_fundamentals').state;
    state = service.reconcile(
      state,
      nowUtc: state.jobs['solar-research']!.deadlineUtc!,
    );
    state = service.reconcile(state, nowUtc: state.lastObservedUtc!);
    expect(state.completedResearch, {'solar_energy_fundamentals'});
    expect(
      research('duplicate', 'solar_energy_fundamentals').code,
      'already_researched',
    );
    expect(
      research('battery-research', 'advanced_battery_systems').code,
      'active',
    );
    expect(state.materials, 80);
  });

  test(
    'upgrade applies a single tier without changing installed unit count',
    () {
      var state = initial().copyWith(facilities: {'solar_array': 3});
      state = service
          .start(
            state,
            jobId: 'upgrade',
            kind: 'upgrade',
            targetId: 'solar_array',
            nowUtc: now,
          )
          .state;
      expect(state.materials, 70);
      state = service.reconcile(
        state,
        nowUtc: state.jobs['upgrade']!.deadlineUtc!,
      );
      expect(state.facilities['solar_array'], 3);
      expect(state.upgradeTiers['solar_array'], 1);
      expect(
        service
            .start(
              state,
              jobId: 'again',
              kind: 'upgrade',
              targetId: 'solar_array',
              nowUtc: now,
            )
            .code,
        'already_upgraded',
      );
      expect(
        service
            .start(
              state,
              jobId: 'unsupported',
              kind: 'upgrade',
              targetId: 'mission_control_hub',
              nowUtc: now,
            )
            .code,
        'unknown_recipe',
      );
    },
  );

  test(
    'timed repair restores one damaged unit once and floors spare-part refund',
    () {
      var state = initial().copyWith(
        facilities: {'solar_array': 3},
        damagedUnits: {'solar_array': 2},
      );
      state = service
          .start(
            state,
            jobId: 'repair',
            kind: 'major_repair',
            targetId: 'solar_array',
            nowUtc: now,
          )
          .state;
      expect(state.resources['spare_part'], 2);
      final cancelled = service
          .cancel(state, jobId: 'repair', nowUtc: now)
          .state;
      expect(cancelled.resources['spare_part'], 2);
      expect(cancelled.materials, 79);
      var completed = service.reconcile(
        state,
        nowUtc: state.jobs['repair']!.deadlineUtc!,
      );
      completed = service.reconcile(
        completed,
        nowUtc: now.add(const Duration(days: 1)),
      );
      expect(completed.damagedUnits['solar_array'], 1);
      expect(completed.facilities['solar_array'], 3);
      expect(completed.resources['spare_part'], 2);
    },
  );

  test(
    'receipts, config, jobs and collections are immutable and repeatable',
    () {
      final state = build(initial(), 'solar', 'solar_array').state;
      expect(() => state.resources['materials'] = 0, throwsUnsupportedError);
      expect(() => state.jobs.clear(), throwsUnsupportedError);
      expect(() => state.jobs['solar']!.paid.clear(), throwsUnsupportedError);
      expect(() => config.recipes.clear(), throwsUnsupportedError);
      final a = service.reconcile(
        state,
        nowUtc: now.add(const Duration(hours: 1)),
      );
      final b = RealTimeProgressionService(config)
          .reconcile(state, nowUtc: now.add(const Duration(hours: 1)));
      expect(a.resources, b.resources);
      expect(a.facilities, b.facilities);
      expect(a.completedActivityIds, b.completedActivityIds);
      expect(a.receipts.keys, b.receipts.keys);
    },
  );

  test('shared completion guard preserves legacy ledger and rewardApplied protection', () {
    expect(
      TimerCompletion.canComplete(
        id: 'x',
        status: 'active',
        completedIds: {},
        deadlineUtc: now,
        nowUtc: now,
      ),
      isTrue,
    );
    expect(
      TimerCompletion.canComplete(
        id: 'x',
        status: 'active',
        completedIds: {'x'},
        deadlineUtc: now,
        nowUtc: now,
      ),
      isFalse,
    );
    expect(
      TimerCompletion.canComplete(
        id: 'x',
        status: 'active',
        completedIds: {},
        deadlineUtc: now,
        nowUtc: now,
        rewardApplied: true,
      ),
      isFalse,
    );
  });

  test(
    'queued work rechecks changed crew membership before charging costs',
    () {
      var state = service
          .enqueue(
            initial(),
            jobId: 'queued',
            kind: 'construction',
            targetId: 'solar_array',
            crewId: 'engineer',
          )
          .state;
      state = state.copyWith(crewRoles: {'engineer': 'Medic'});
      final result = service.activate(state, jobId: 'queued', nowUtc: now);
      expect(result.code, 'wrong_crew_role');
      expect(result.state.materials, state.materials);
      expect(result.state.crewAssignments, isEmpty);
    },
  );

  test('fractional divisible resources refund exactly and invalid balances are rejected', () {
    final buildings = document('buildings');
    buildings['buildings'][0]['repair_cost']['lubricant'] = 1.5;
    final custom = RealTimeProgressionService(
      configuration(buildings: buildings),
    );
    var state = initial().copyWith(
      facilities: {'solar_array': 1},
      damagedUnits: {'solar_array': 1},
      resources: {'materials': 80, 'spare_part': 1, 'lubricant': 2},
    );
    state = custom
        .start(
          state,
          jobId: 'fractional',
          kind: 'major_repair',
          targetId: 'solar_array',
          nowUtc: now,
        )
        .state;
    state = custom.cancel(state, jobId: 'fractional', nowUtc: now).state;
    expect(state.resources['lubricant'], 1.25);
    expect(state.resources['spare_part'], 0);
    final invalid = build(
      initial().copyWith(resources: {'materials': double.nan}),
      'nan',
      'solar_array',
    );
    expect(invalid.code, 'invalid_resource');
    expect(invalid.state.jobs['nan']!.paid, isEmpty);
  });

  test('completion at a shared deadline is ordered by stable job IDs', () {
    var state = build(initial(), 'z-solar', 'solar_array').state;
    state = build(state, 'a-maintenance', 'maintenance_bay').state;
    expect(
      state.jobs['a-maintenance']!.deadlineUtc,
      state.jobs['z-solar']!.deadlineUtc,
    );
    state = service.reconcile(state, nowUtc: now.add(const Duration(hours: 1)));
    expect(state.completedActivityIds.toList(), ['a-maintenance', 'z-solar']);
    expect(state.facilities['solar_array'], 1);
    expect(state.facilities['maintenance_bay'], 1);
  });

  test('synthetic fixture was encoded by unchanged pre-4B serializer and has no app-created jobs', () {
    final source = File('test/fixtures/pre_4b_f0a179f.json')
        .readAsStringSync()
        .trim();
    final save = CampaignSave.decode(source);
    expect(save.version, 2);
    expect(save.encode(), source);
    expect(save.settings['fixture_note'], contains('f0a179f'));
    expect(save.settings['fixture_note'], contains('NOT a real player save'));
    expect(save.timerJobs, isEmpty);
    expect(save.prologueComplete, isTrue);
    expect(save.crewNames.length, 4);
    expect(save.inventory, {'solar_panel': 2, 'battery': 1});
  });
}
