import 'dart:convert';

import 'package:base67/app/campaign_controller.dart';
import 'package:base67/app/campaign_migration.dart';
import 'package:base67/app/campaign_save.dart';
import 'package:base67/app/campaign_save_store.dart';
import 'package:base67/data/repositories/game_data_repository.dart';
import 'package:base67/missions/mission_runtime.dart';
import 'package:base67/progression/progression_service.dart';
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

  CampaignSave setup() => migration.migrate(const CampaignSave(
    prologueComplete: true, selectedSiteId: 'gale', deterministicSeed: 42,
    buildingLevels: {'crew_habitat': 1},
  ));
  ProgressionState state(CampaignSave save) => migration.codec.decode(jsonDecode(save.progressionJson!));
  ProgressionState equipped() => state(setup()).copyWith(
    facilities: {'crew_habitat': 1, 'solar_array': 8, 'battery_bank': 6, 'greenhouse': 1,
      'power_control_station': 1, 'maintenance_bay': 1, 'life_support_module': 1},
    resources: {...state(setup()).resources,
      'battery_kwh': runtime.config.number('battery_unit_kwh') * 6},
    completedResearch: {'solar_energy_fundamentals'},
  );
  Map<String, dynamic> session(ProgressionState p, String id, [Map<String, dynamic>? old]) =>
      runtime.open(id, runtime.world(p, old, site: 'gale', seed: 42), old);
  Map<String, dynamic> learned(Map<String, dynamic> s) => {...s,
    'learned': [runtime.definition(s['level'] as String)['interaction']]};

  test('systems are introduced at the intended levels', () {
    for (var i = 0; i < 7; i++) {
      final id = runtime.levels[i];
      for (final gate in {'battery': 2, 'loads': 2, 'dust': 4,
        'cleaning': 4, 'greenhouse': 6, 'research': 6, 'oxygen': 7}.entries) {
        expect(runtime.introduced(id, gate.key), i + 1 >= gate.value);
      }
    }
    for (final id in runtime.levels.skip(7)) {
      expect(runtime.supports(id), isTrue);
    }
  });

  test('all seven mission goals execute on the same equipped base without resets', () {
    var p = equipped();
    Map<String, dynamic>? previous;
    final starting = p.resources['oxygen_kg']!;
    for (final id in runtime.levels.take(7)) {
      var s = learned(session(p, id, previous));
      s = runtime.begin(s, runtime.world(p, s, site: 'gale', seed: 42));
      for (var step = 0; step < 64 && s['phase'] == 'play'; step++) {
        final result = runtime.step(p, s, site: 'gale', seed: 42);
        p = result.progression; s = result.session;
      }
      expect(s['result'], 'success', reason: '$id: ${s['message']}');
      expect(p.facilities, equipped().facilities);
      expect(p.completedResearch, equipped().completedResearch);
      expect(p.packedStock, equipped().packedStock);
      expect(p.materials, equipped().materials);
      runtime.validate(jsonDecode(jsonEncode(s)) as Map<String, dynamic>);
      previous = s;
    }
    expect(p.resources['oxygen_kg'], lessThan(starting));
    expect((previous!['environment'] as Map)['hours'], greaterThan(runtime.config.number('sol_hours')));
  });

  test('checkpoints exclude ownership; reopening and retry retain actual stocks, environment and seed', () {
    final p = equipped().copyWith(resources: {...equipped().resources, 'oxygen_kg': 7});
    final original = session(p, runtime.levels[6]);
    final s = runtime.begin(learned(original), runtime.world(p, original, site: 'gale', seed: 42));
    final result = runtime.step(p, s, site: 'gale', seed: 42);
    final reopened = session(result.progression, runtime.levels[6], result.session);
    final world = runtime.world(result.progression, reopened, site: 'gale', seed: 42);
    expect(world.resources['oxygen_kg']!.quantity, result.progression.resources['oxygen_kg']);
    expect(reopened['environment'], result.session['environment']);
    expect(reopened['seed'], s['seed']);
    expect(reopened['learned'], s['learned']);
    expect((reopened['environment'] as Map).containsKey('resources'), isFalse);
    expect((reopened['environment'] as Map).containsKey('facilities'), isFalse);
  });

  test('same seed, state and actions produce identical mission outcomes and continuation', () {
    final p = equipped();
    final initial = learned(session(p, runtime.levels[4]));
    final s = runtime.begin(initial, runtime.world(p, initial, site: 'gale', seed: 42));
    final a = runtime.step(p, s, site: 'gale', seed: 42);
    final b = runtime.step(p, jsonDecode(jsonEncode(s)) as Map<String, dynamic>, site: 'gale', seed: 42);
    expect(a.session, b.session);
    expect(a.progression.resources, b.progression.resources);
    final restored = jsonDecode(jsonEncode(a.session)) as Map<String, dynamic>;
    expect(runtime.step(a.progression, restored, site: 'gale', seed: 42).session,
      runtime.step(a.progression, a.session, site: 'gale', seed: 42).session);
  });

  test('missing power fails safely and insufficient oxygen gives debrief without refill', () {
    final p = state(setup());
    final s = learned(session(p, runtime.levels.first));
    final failure = runtime.step(p, runtime.begin(s, runtime.world(p, s, site: 'gale', seed: 42)), site: 'gale', seed: 42);
    expect(failure.session['phase'], 'debrief');
    expect(failure.session['result'], 'retry');
    expect(failure.progression.resources['oxygen_kg'], lessThan(p.resources['oxygen_kg']!));
    final low = equipped().copyWith(resources: {...equipped().resources, 'oxygen_kg': 0});
    final oxygen = learned(session(low, runtime.levels[6]));
    final outcome = runtime.step(low, runtime.begin(oxygen, runtime.world(low, oxygen, site: 'gale', seed: 42)), site: 'gale', seed: 42);
    expect(outcome.session['result'], 'retry');
    expect(outcome.progression.resources['oxygen_kg'], lessThan(runtime.config.initial['oxygen_kg']!));
  });

  test('preparation and hypothetical planning cannot complete missions or change jobs', () {
    final p = equipped();
    final s = {...learned(session(p, runtime.levels[1])), 'phase': 'planning'};
    final before = migration.codec.encode(p);
    final preview = runtime.powerPlan(runtime.world(p, s, site: 'gale', seed: 42),
      panels: 8, batteries: 6, disabledLoads: []);
    expect(preview['minimum_kwh'], isA<double>());
    expect(migration.codec.encode(p), before);
    final prepared = runtime.step(p, s, site: 'gale', seed: 42, preparation: true);
    expect(prepared.session['phase'], 'planning');
    expect(prepared.session['result'], '');
    expect(prepared.progression.resources['oxygen_kg'], lessThan(p.resources['oxygen_kg']!));
    expect(prepared.progression.jobs, p.jobs);
    expect(prepared.progression.receipts, p.receipts);
  });

  test('saved mission validation rejects non-finite environment', () {
    final s = session(equipped(), runtime.levels.first);
    final invalid = {...s, 'environment': {...s['environment'] as Map, 'hours': double.nan}};
    expect(() => runtime.validate(invalid), throwsFormatException);
  });

  test('controller saves success and resupply once; reload/retry retain facilities and research', () async {
    final storage = _Memory();
    final initial = setup().copyWith(progressionJson: jsonEncode(migration.codec.encode(equipped())));
    final c = CampaignController(repository: repository, store: CampaignSaveStore(storage),
      initial: initial, utcNow: () => DateTime.utc(2026, 11, 11));
    await c.initialize();
    final id = runtime.levels.first;
    expect(await c.missionAction(runtime.levels[1], 'open'), 'level_locked');
    await c.missionAction(id, 'open');
    await c.missionAction(id, 'review');
    await c.missionAction(id, 'plan');
    expect(await c.missionAction(id, 'begin'), contains('Discuss'));
    await c.missionAction(id, 'learn', value: runtime.definition(id)['answer'] as String);
    await c.missionAction(id, 'begin');
    await c.missionAction(id, 'step');
    expect(c.mission!['result'], 'success');
    expect(c.save.unlockedLevelIds, contains(runtime.levels[1]));
    final materials = c.progression.materials;
    final receipts = c.progression.receipts.keys.toSet();
    await c.missionAction(id, 'step');
    expect(c.progression.materials, materials);
    expect(c.progression.receipts.keys.toSet(), receipts);
    final store = CampaignSaveStore(storage, migrate: migration.migrate, validate: migration.validate);
    final restored = await store.load();
    expect(restored.missionJson, c.save.missionJson);
    final reopened = CampaignController(repository: repository, store: store, initial: restored,
      utcNow: () => DateTime.utc(2026, 11, 11));
    await reopened.initialize();
    final resources = {...reopened.progression.resources};
    await reopened.missionAction(id, 'retry');
    expect(reopened.progression.resources, resources);
    expect(reopened.progression.facilities, equipped().facilities);
    expect(reopened.progression.completedResearch, equipped().completedResearch);
    expect(reopened.mission!['learned'], contains('solar'));
    expect(reopened.mission!['seed'], 42);
    reopened.dispose(); c.dispose();
  });

  test('a running engineering job does not block mission steps; offline jobs never run simulation', () async {
    final p = equipped().copyWith(levelId: runtime.levels[5], facilities: {
      'crew_habitat': 1, 'solar_array': 8, 'battery_bank': 6,
    });
    final save = setup().copyWith(unlockedLevelIds: runtime.levels.take(6).toSet(),
      progressionJson: jsonEncode(migration.codec.encode(p)));
    var now = DateTime.utc(2026, 11, 11);
    final c = CampaignController(repository: repository, store: CampaignSaveStore(_Memory()),
      initial: save, utcNow: () => now);
    await c.initialize();
    final started = await c.startMissionJob(jobId: 'greenhouse-test', kind: 'construction',
      targetId: 'greenhouse', crewId: 'Engineer');
    expect(started, 'active');
    final id = runtime.levels[5];
    await c.missionAction(id, 'open'); await c.missionAction(id, 'review'); await c.missionAction(id, 'plan');
    final time = c.missionWorld.elapsedHours;
    await c.missionAction(id, 'prepare');
    expect(c.missionWorld.elapsedHours, greaterThan(time));
    expect(c.progression.jobs['greenhouse-test']!.status, 'active');
    final remaining = c.progression.jobs['greenhouse-test']!.clock!.remaining;
    final reserves = {...c.progression.resources};
    final halfway = remaining ~/ 2;
    now = now.add(halfway);
    await c.missionAction(id, 'hint');
    expect(c.progression.jobs['greenhouse-test']!.clock!.remaining,
      remaining - halfway);
    expect(c.progression.resources, reserves);
    final beforeOffline = {...c.progression.resources};
    final beforeTime = c.missionWorld.elapsedHours;
    now = now.add(const Duration(days: 1));
    await c.reconcile();
    expect(c.progression.jobs['greenhouse-test']!.status, 'completed');
    expect(c.missionWorld.elapsedHours, beforeTime);
    expect(c.progression.resources, beforeOffline);
    expect(c.progression.facilities['greenhouse'], 1);
    c.dispose();
  });
}

class _Memory implements LocalStringStore {
  final Map<String, String> values = {};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async { values[key] = value; }
}
