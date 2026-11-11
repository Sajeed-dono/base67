import 'dart:convert';

import 'package:base67/app/campaign_controller.dart';
import 'package:base67/app/campaign_migration.dart';
import 'package:base67/app/campaign_save.dart';
import 'package:base67/app/campaign_save_store.dart';
import 'package:base67/data/repositories/game_data_repository.dart';
import 'package:base67/missions/mission_runtime.dart';
import 'package:base67/progression/progression_service.dart';
import 'package:base67/progression/progression_clock.dart';
import 'package:base67/game/certificate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameDataRepository repository;
  late CampaignMigration migration;
  late MissionRuntime runtime;
  setUpAll(() async {
    repository = await GameDataRepository.load();
    migration = CampaignMigration(repository);
    runtime = migration.missions;
  });
  CampaignSave initial() => migration.migrate(const CampaignSave(
    prologueComplete: true, selectedSiteId: 'gale', deterministicSeed: 42,
    settings: {'reduceMotion': true}, buildingLevels: {'crew_habitat': 1},
    inventory: {'solar_panel': 2, 'battery': 1, 'spare_part': 1},
  ));
  ProgressionState stateOf(CampaignSave save) => migration.codec.decode(jsonDecode(save.progressionJson!));
  Map<String, dynamic> session(ProgressionState p, int level) => runtime.open(runtime.levels[level - 1],
    runtime.world(p, null, site: 'gale', seed: 42), null);

  test('late mechanic gates and deterministic event spacing use configuration', () {
    for (final gate in {'radiation': 8, 'shelter': 9, 'survey': 10, 'water': 11, 'food': 12, 'wellbeing': 13}.entries) {
      for (var n = 1; n <= 15; n++) {
        expect(runtime.introduced(runtime.levels[n - 1], gate.key), n >= gate.value);
      }
    }
    final p = stateOf(initial());
    final world = runtime.world(p, null, site: 'gale', seed: 42);
    for (final id in [runtime.levels[8], runtime.levels[13], runtime.levels[14]]) {
      final a = runtime.eventPlan(id, world, 42), b = runtime.eventPlan(id, world, 42);
      expect(a, b);
      final old = runtime.begin(session(p, runtime.order(id)), world);
      final continued = world.copyWith(elapsedHours: world.elapsedHours + 1);
      final retry = runtime.open(id, continued, old);
      expect(runtime.begin(retry, continued)['event_plan'], old['event_plan']);
      for (var i = 1; i < a.length; i++) {
        final previousEnd = (a[i - 1]['at'] as num) +
          (a[i - 1]['event_id'] == 'dust_storm' ? runtime.config.stormFrames.last.$1 : 0);
        expect((a[i]['at'] as num) - previousEnd, greaterThanOrEqualTo(runtime.rules['event_gap_hours'] as num));
      }
    }
  });

  test('crew exclusivity, backup duration, cancellation and real-job conflict', () {
    final p = stateOf(initial()).copyWith(levelId: runtime.levels[12]);
    final colony = runtime.settlement(p, null);
    final specialist = runtime.crew.assign(p, colony, role: 'Scientist', action: 'survey', level: 13);
    final backup = runtime.crew.assign(p, colony, role: 'Commander', action: 'survey', level: 13);
    expect(((specialist.settlement['tasks'] as Map)['Scientist'] as Map)['remaining'],
      lessThan(((backup.settlement['tasks'] as Map)['Commander'] as Map)['remaining'] as num));
    final duplicate = runtime.crew.assign(specialist.progression, specialist.settlement,
      role: 'Scientist', action: 'forecast', level: 13);
    expect(duplicate.progression, same(specialist.progression));
    final service = RealTimeProgressionService(migration.config);
    final blocked = service.start(specialist.progression, jobId: 'busy-research',
      kind: 'research', targetId: 'solar_energy_fundamentals', crewId: 'Scientist',
      observation: _observation(0));
    expect(blocked.state.jobs['busy-research']?.status, isNot('active'));
    final cancelled = runtime.crew.cancel(specialist.progression, specialist.settlement, 'Scientist');
    expect(cancelled.progression.crewAssignments.containsKey('Scientist'), isFalse);
    expect(cancelled.progression.resources, p.resources);
    expect(cancelled.progression.receipts, p.receipts);
  });

  test('cleaning reserves the target and cannot finish without engine success', () {
    final p = stateOf(initial()).copyWith(facilities: {'crew_habitat': 1, 'solar_array': 1});
    final a = runtime.crew.assign(p, runtime.settlement(p, null), role: 'Engineer', action: 'clean', level: 4);
    expect(a.progression.externalFacilityReservations, contains('solar_array'));
    final second = runtime.crew.assign(a.progression, a.settlement, role: 'Medic', action: 'clean', level: 4);
    expect(second.progression, same(a.progression));
    final waiting = runtime.crew.advance(a.progression, a.settlement,
      runtime.world(a.progression, null, site: 'gale', seed: 42), hours: 1, shortage: false, config: runtime.config);
    expect((waiting.settlement['tasks'] as Map).containsKey('Engineer'), isTrue);
    final finished = runtime.crew.advance(waiting.progression, waiting.settlement,
      runtime.world(waiting.progression, null, site: 'gale', seed: 42), hours: 1,
      shortage: false, config: runtime.config, cleaned: true);
    expect(finished.progression.externalFacilityReservations, isNot(contains('solar_array')));
    expect(finished.progression.crewAssignments.containsKey('Engineer'), isFalse);
  });

  test('Medic and Commander effects, rest and bounded nonfatal wellbeing', () {
    final p = stateOf(initial());
    final colony = runtime.settlement(p, null);
    final tired = {...colony, 'crew': {for (final role in p.crewRoles.keys)
      role: {'health': 20.0, 'morale': 30.0, 'fatigue': 80.0}}};
    final medic = runtime.crew.assign(p, tired, role: 'Medic', action: 'care', level: 13);
    final backup = runtime.crew.assign(p, tired, role: 'Scientist', action: 'care', level: 13);
    final world = runtime.world(p, null, site: 'gale', seed: 42);
    final a = runtime.crew.advance(medic.progression, medic.settlement, world,
      hours: 1, shortage: false, config: runtime.config);
    final b = runtime.crew.advance(backup.progression, backup.settlement, world,
      hours: 1, shortage: false, config: runtime.config);
    expect(((a.settlement['crew'] as Map)['Engineer'] as Map)['health'],
      greaterThan(((b.settlement['crew'] as Map)['Engineer'] as Map)['health'] as num));
    final rally = runtime.crew.assign(p, tired, role: 'Commander', action: 'rally', level: 13);
    final rallied = runtime.crew.advance(rally.progression, rally.settlement, world,
      hours: 1, shortage: false, config: runtime.config);
    expect(((rallied.settlement['crew'] as Map)['Medic'] as Map)['morale'], greaterThan(30));
    final hurt = runtime.crew.advance(p, tired, world.copyWith(temperature: runtime.config.number('min_safe_temp') - 1),
      hours: 100, shortage: true, config: runtime.config);
    expect((hurt.settlement['crew'] as Map).length, 4);
    for (final raw in (hurt.settlement['crew'] as Map).values) {
      expect((raw as Map)['health'], inInclusiveRange(0, 100));
      expect(raw['fatigue'], inInclusiveRange(0, 100));
    }
  });

  test('explicit support is capped, repeat-idempotent, excludes ordinary credits and retains exposure history', () {
    final p = stateOf(initial()).copyWith(resources: {...stateOf(initial()).resources,
      'oxygen_kg': 0, 'water_kg': 0, 'food_kg': 0, 'materials': 0, 'spare_part': 0});
    final s = session(p, 13);
    final exposed = {...s, 'environment': {...s['environment'] as Map,
      'radiation': runtime.config.number('radiation_limit'), 'radiation_total': runtime.config.number('radiation_limit')}};
    final a = runtime.support(p, exposed, site: 'gale', seed: 42);
    final b = runtime.support(a.progression, a.session, site: 'gale', seed: 42);
    expect(b.progression.resources, a.progression.resources);
    expect((b.session['settlement'] as Map)['support_count'], (a.session['settlement'] as Map)['support_count']);
    expect(a.progression.materials, 0);
    expect(a.progression.resources['spare_part'], 0);
    expect(a.progression.facilities, p.facilities);
    expect(a.progression.receipts, p.receipts);
    expect((a.session['environment'] as Map)['radiation'], 0);
    expect((a.session['environment'] as Map)['radiation_total'], runtime.config.number('radiation_limit'));
    final begun = runtime.begin(a.session, runtime.world(a.progression, a.session, site: 'gale', seed: 42));
    expect(begun['baseline_support'], 0); // Planning aid remains attributable.
    final retried = runtime.open(a.session['level'] as String,
      runtime.world(a.progression, a.session, site: 'gale', seed: 42), a.session);
    expect(retried['baseline_support'], 0);
  });

  test('crew tasks and wellbeing survive reload while offline time advances no simulation', () async {
    final storage = _Memory();
    var now = DateTime.utc(2026, 11, 11);
    var p = stateOf(initial()).copyWith(levelId: runtime.levels[9]);
    var s = {...session(p, 10), 'phase': 'planning'};
    final assigned = runtime.crew.assign(p, runtime.settlement(p, s),
      role: 'Scientist', action: 'survey', level: 10);
    p = assigned.progression;
    s = {...s, 'settlement': assigned.settlement};
    final save = initial().copyWith(unlockedLevelIds: runtime.levels.take(10).toSet(),
      progressionJson: jsonEncode(migration.codec.encode(p)), missionJson: jsonEncode(s));
    final c = CampaignController(repository: repository, store: CampaignSaveStore(storage), initial: save, utcNow: () => now);
    await c.initialize();
    final before = c.save;
    now = now.add(const Duration(days: 30));
    await c.resume();
    expect(c.save.missionJson, before.missionJson);
    expect(c.progression.resources, before.resources);
    expect(c.progression.crewAssignments['Scientist'], 'mission:survey');
    final loaded = await CampaignSaveStore(storage, migrate: migration.migrate, validate: migration.validate).load();
    expect(loaded.missionJson, c.save.missionJson);
    final restored = CampaignController(repository: repository, store: CampaignSaveStore(storage), initial: loaded, utcNow: () => now);
    await restored.initialize();
    expect(restored.mission!['settlement'], s['settlement']);
    final malformed = {...restored.mission!, 'settlement': {
      ...restored.mission!['settlement'] as Map, 'tasks': <String, dynamic>{},
    }};
    expect(() => migration.validate(restored.save.copyWith(missionJson: jsonEncode(malformed))), throwsFormatException);
    restored.dispose(); c.dispose();
  });

  test('reference strategy progresses all 15 levels with the same base, repair ledger and save', () async {
    final storage = _Memory();
    var now = DateTime.utc(2026, 11, 11);
    final c = CampaignController(repository: repository, store: CampaignSaveStore(storage),
      initial: initial(), utcNow: () => now);
    addTearDown(c.dispose);
    await c.initialize();
    var serial = 0;
    Future<void> build(String target) async {
      final recipe = migration.config.recipes['construction:$target']!;
      final id = 'reference:${serial++}';
      expect(await c.startMissionJob(jobId: id, kind: 'construction', targetId: target, crewId: 'Engineer'), 'active');
      now = now.add(recipe.duration);
      final before = c.save.missionJson;
      await c.reconcile();
      expect(c.progression.jobs[id]!.status, 'completed');
      expect(c.save.missionJson, before);
    }
    Future<void> research(String target) async {
      final recipe = migration.config.recipes['research:$target']!;
      final id = 'reference-research:${serial++}';
      expect(await c.startMissionJob(jobId: id, kind: 'research', targetId: target, crewId: 'Scientist'), 'active');
      now = now.add(recipe.duration);
      await c.reconcile();
      expect(c.progression.completedResearch, contains(target));
    }
    for (var number = 1; number <= 15; number++) {
      final id = runtime.levels[number - 1];
      for (final target in migration.config.requiredUnits.keys) {
        final recipe = migration.config.recipes['construction:$target']!;
        if (runtime.order(recipe.levelId) <= number) {
          while ((c.progression.facilities[target] ?? 0) < migration.config.requiredUnits[target]!) { await build(target); }
        }
      }
      if (number == 2) {
        while ((c.progression.facilities['solar_array'] ?? 0) < migration.config.maxUnits['solar_array']!) { await build('solar_array'); }
        while ((c.progression.facilities['battery_bank'] ?? 0) < migration.config.maxUnits['battery_bank']!) { await build('battery_bank'); }
      }
      if (number == 6) { await build('greenhouse'); }
      if (number == 7) {
        await research('solar_energy_fundamentals');
        await research('advanced_battery_systems');
        await research('oxygen_production');
      }
      expect(await c.missionAction(id, 'open'), 'saved');
      await c.missionAction(id, 'review'); await c.missionAction(id, 'plan');
      if (number == 2) { for (var i = 0; i < 3; i++) { await c.missionAction(id, 'prepare'); } }
      if (number == 10) {
        await c.missionAction(id, 'crew', value: 'Scientist:survey');
        await c.missionAction(id, 'prepare');
      }
      if (number == 13) {
        await c.missionAction(id, 'crew', value: 'Medic:care');
        await c.missionAction(id, 'crew', value: 'Commander:rally');
        await c.missionAction(id, 'crew', value: 'Engineer:rest');
        await c.missionAction(id, 'prepare'); await c.missionAction(id, 'prepare');
      }
      if (number == 14) {
        await c.missionAction(id, 'crew', value: 'Scientist:forecast');
        await c.missionAction(id, 'crew', value: 'Commander:priorities');
        await c.missionAction(id, 'crew', value: 'Medic:drill');
        await c.missionAction(id, 'prepare');
      }
      if (number >= 14) {
        for (var i = 0; i < runtime.config.number('sol_hours').ceil() &&
            c.missionWorld.resources['battery_kwh']!.quantity <
              c.missionWorld.resources['battery_kwh']!.capacity * .9; i++) {
          await c.missionAction(id, 'prepare');
        }
      }
      if (number >= 9 && c.mission!['shelter'] != true) { await c.missionAction(id, 'shelter'); }
      if (number < 9 && c.mission!['shelter'] == true) { await c.missionAction(id, 'shelter'); }
      await c.missionAction(id, 'learn', value: runtime.definition(id)['answer'] as String);
      expect(await c.missionAction(id, 'begin'), 'saved');
      for (var tick = 0; tick < 64 && c.mission!['phase'] == 'play'; tick++) {
        await c.missionAction(id, 'step');
        if ((c.progression.damagedUnits['solar_array'] ?? 0) > 0) {
          final repairId = 'reference-repair:${serial++}';
          expect(await c.startMissionJob(jobId: repairId, kind: 'major_repair', targetId: 'solar_array', crewId: 'Engineer'), 'active');
          now = now.add(c.progression.jobs[repairId]!.clock!.remaining);
          await c.reconcile();
        }
      }
      expect(c.mission!['result'], 'success', reason: '$number: ${c.mission!['message']}');
      expect(c.save.completedLevelIds, contains(id));
      expect(c.progression.facilities['solar_array'], number == 1 ? 1 : migration.config.maxUnits['solar_array']);
      expect(c.save.selectedSiteId, 'gale');
    }
    expect(c.save.completedLevelIds, containsAll(runtime.levels));
    expect(c.progression.receipts, contains('resolved:${runtime.levels.last}:meteor_shower:1'));
    final repeated = runtime.begin(runtime.open(runtime.levels.last, c.missionWorld, c.mission), c.missionWorld);
    final replay = runtime.step(c.progression, repeated, site: 'gale', seed: 42);
    expect(replay.progression.damagedUnits, c.progression.damagedUnits);
    expect(replay.progression.resources['spare_part'], c.progression.resources['spare_part']);
    expect(replay.progression.receipts.keys.toSet(), c.progression.receipts.keys.toSet());
    final ledger = c.progression.receipts.keys.toSet();
    final stores = {...c.progression.resources};
    final facilities = {...c.progression.facilities};
    await c.missionAction(runtime.levels.first, 'open');
    expect(c.progression.resources, stores);
    expect(c.progression.facilities, facilities);
    expect(c.progression.receipts.keys.toSet(), ledger);
    expect(c.progression.levelId, runtime.levels.last);
    final reopened = await CampaignSaveStore(storage, migrate: migration.migrate, validate: migration.validate).load();
    expect(reopened.encode(), c.save.encode());
  });

  testWidgets('certificate requires the complete campaign and disclaims NASA accreditation', (tester) async {
    final start = initial();
    final unfinished = CampaignController(repository: repository, store: CampaignSaveStore(_Memory()), initial: start);
    await tester.pumpWidget(MaterialApp(home: CertificateScreen(controller: unfinished)));
    expect(find.text(runtime.operations['certificate'] as String), findsNothing);
    expect(find.text('Keep exploring'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    unfinished.dispose();
    final p = stateOf(start);
    final done = start.copyWith(unlockedLevelIds: runtime.levels.toSet(), progressionJson: jsonEncode(
      migration.codec.encode(p.copyWith(levelId: runtime.levels.last, completedLevels: runtime.levels.toSet()))));
    final c = CampaignController(repository: repository, store: CampaignSaveStore(_Memory()), initial: done);
    addTearDown(c.dispose);
    await tester.pumpWidget(MaterialApp(home: CertificateScreen(controller: c)));
    expect(find.text(runtime.operations['certificate'] as String), findsOneWidget);
    expect(find.byType(CertificateScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

ClockObservation _observation(int token) => ClockObservation(
  token: token, utc: DateTime.utc(2026, 11, 11));

class _Memory implements LocalStringStore {
  final Map<String, String> values = {};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async { values[key] = value; }
}
