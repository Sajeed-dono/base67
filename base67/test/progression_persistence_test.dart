import 'dart:convert';
import 'dart:io';

import 'package:base67/app/campaign_controller.dart';
import 'package:base67/app/campaign_migration.dart';
import 'package:base67/app/campaign_save.dart';
import 'package:base67/app/campaign_save_store.dart';
import 'package:base67/data/repositories/game_data_repository.dart';
import 'package:base67/progression/progression_clock.dart';
import 'package:base67/progression/progression_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'progression_service_test.dart' show configuration, document, observation;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameDataRepository repository;
  late CampaignMigration migration;
  final now = DateTime.utc(2026, 11, 10);
  setUpAll(() async {
    repository = await GameDataRepository.load();
  });
  setUp(() => migration = CampaignMigration(repository));

  CampaignSave fixture() => CampaignSave.decode(
    File('test/fixtures/pre_4b_f0a179f.json').readAsStringSync(),
  );
  CampaignSaveStore store(_Storage storage) => CampaignSaveStore(storage,
    migrate: migration.migrate, validate: migration.validate);
  ProgressionState stateOf(CampaignSave save) =>
    migration.codec.decode(jsonDecode(save.progressionJson!));
  CampaignSave withState(CampaignSave save, ProgressionState state) =>
    save.copyWith(progressionJson: jsonEncode(migration.codec.encode(state)));

  test('synthetic pre-4B fixture migrates without losing metadata or double granting', () {
    final old = fixture();
    final updated = migration.migrate(old);
    final state = stateOf(updated);
    expect(updated.version, 3);
    expect(updated.crewNames, old.crewNames);
    expect(updated.settings, old.settings);
    expect(updated.startingCargo, old.startingCargo);
    expect(updated.inventory, old.inventory);
    expect(updated.buildingLevels, old.buildingLevels);
    expect(updated.missionPatchId, old.missionPatchId);
    expect(updated.deterministicSeed, old.deterministicSeed);
    expect(updated.completedLevelIds, old.completedLevelIds);
    expect(state.materials, migration.config.startMaterials);
    expect(migration.migrate(updated).encode(), updated.encode());
    expect(stateOf(migration.migrate(updated)).resources, state.resources);
    expect(updated.toJson().containsKey('inventory'), isFalse);
    expect(updated.toJson().containsKey('resources'), isFalse);
    expect(updated.toJson().containsKey('buildingLevels'), isFalse);
    expect(CampaignSave.decode(updated.encode()).encode(), updated.encode());
  });

  test('migration preserves depleted reserves, material balances and catch-up receipts', () {
    final old = fixture().copyWith(
      resources: {'oxygen_kg': 0, 'water_kg': 7, 'food_kg': 4, 'materials': 0},
      completedLevelIds: {migration.config.levels.first},
      unlockedLevelIds: migration.config.levels.take(2).toSet(),
    );
    final updated = migration.migrate(old);
    final state = stateOf(updated);
    expect(state.resources['oxygen_kg'], 0);
    expect(state.resources['water_kg'], 7);
    expect(state.resources['food_kg'], 4);
    expect(state.materials, migration.config.missionMaterials);
    expect(state.receipts['resupply:catch_up']!.amount, migration.config.missionMaterials);
    expect(stateOf(migration.migrate(updated)).resources, state.resources);
  });

  test('ambiguous legacy jobs are retained terminal, free crew and apply no effects', () {
    final old = fixture().copyWith(timerJobs: [TimerJobSave(
      id: 'legacy-job', category: 'construction', targetId: 'solar_array',
      assignedCrewRole: 'Engineer', startedAtUtc: now,
      expectedCompletionAtUtc: now.add(const Duration(minutes: 5)),
    )]);
    final updated = migration.migrate(old);
    final state = stateOf(updated);
    expect(updated.legacyTimerJobs.single.status, 'cancelled');
    expect(updated.legacyTimerJobs.single.assignedCrewRole, isNull);
    expect(state.facilities.containsKey('solar_array'), isFalse);
    expect(state.crewAssignments, isEmpty);
    expect(state.completedActivityIds, contains('legacy-job'));
    expect(state.log, contains('migration:legacy_job_retired:legacy-job:crew_freed:no_cost:no_effect'));
  });

  test('mixed spare ownership aborts migration and leaves original bytes untouched', () async {
    final original = fixture().copyWith(
      inventory: {'spare_part': 2}, resources: {'spare_part': 2},
    ).encode();
    final storage = _Storage()
      ..values[CampaignSaveStore.storageKey] = original
      ..values[CampaignSaveStore.backupKey] = fixture().encode();
    await expectLater(store(storage).load(), throwsFormatException);
    expect(storage.values[CampaignSaveStore.storageKey], original);
    expect(storage.writes, isEmpty);
  });

  test('migration backs up exact schema-2 bytes before replacing primary', () async {
    final original = fixture().encode();
    final storage = _Storage()..values[CampaignSaveStore.storageKey] = original;
    final updated = await store(storage).load();
    expect(updated.version, 3);
    expect(storage.values[CampaignSaveStore.backupKey], original);
    expect(storage.writes.map((e) => e.$1), [CampaignSaveStore.backupKey, CampaignSaveStore.storageKey]);
    expect(CampaignSave.decode(storage.values[CampaignSaveStore.storageKey]!).version, 3);
  });

  test('failed primary write restores original migration input and retains backup', () async {
    final original = fixture().encode();
    final storage = _Storage()
      ..values[CampaignSaveStore.storageKey] = original
      ..failNextPrimary = true;
    await expectLater(store(storage).load(), throwsStateError);
    expect(storage.values[CampaignSaveStore.storageKey], original);
    expect(storage.values[CampaignSaveStore.backupKey], original);
  });

  test('failed read-back cannot publish a bad save over the last good backup', () async {
    final storage = _Storage();
    final disk = store(storage);
    final saved = await disk.load();
    final original = storage.values[CampaignSaveStore.storageKey];
    storage.corruptNextPrimary = true;
    await expectLater(disk.save(saved.copyWith(settings: {'reduceMotion': true})), throwsStateError);
    expect(storage.values[CampaignSaveStore.storageKey], original);
    expect(storage.values[CampaignSaveStore.backupKey], original);
  });

  test('invalid primary can recover backup; two invalid blobs never start blank', () async {
    final storage = _Storage()
      ..values[CampaignSaveStore.storageKey] = '{broken'
      ..values[CampaignSaveStore.backupKey] = fixture().encode();
    final disk = store(storage);
    expect((await disk.load()).prologueComplete, isTrue);
    expect(disk.recoveredFromBackup, isTrue);
    expect(storage.values[CampaignSaveStore.storageKey], '{broken');
    expect(storage.writes, isEmpty);
    storage.values[CampaignSaveStore.backupKey] = '{also broken';
    await expectLater(store(storage).load(), throwsFormatException);
    expect(storage.writes, isEmpty);
  });

  test('unsupported future save is preserved even when an older backup exists', () async {
    final raw = jsonEncode({...fixture().toJson(), 'version': 99});
    final storage = _Storage()
      ..values[CampaignSaveStore.storageKey] = raw
      ..values[CampaignSaveStore.backupKey] = fixture().encode();
    await expectLater(store(storage).load(), throwsA(isA<UnsupportedSaveVersion>()));
    expect(storage.values[CampaignSaveStore.storageKey], raw);
    expect(storage.writes, isEmpty);
  });

  test('active paid job restores once; rollback and repeated completion preserve accounting', () async {
    final service = RealTimeProgressionService(migration.config);
    final base = migration.migrate(fixture());
    var state = stateOf(base);
    state = service.start(state, jobId: 'build', kind: 'construction', targetId: 'solar_array',
      crewId: 'Engineer', observation: observation(state, now)).state;
    final paid = state.resources;
    final stock = state.packedStock;
    final deadline = state.jobs['build']!.deadlineUtc;
    final storage = _Storage();
    await store(storage).save(withState(base, state));
    state = stateOf(await store(storage).load());
    state = service.reconcile(state, observation: observation(state, now.subtract(const Duration(days: 1))));
    expect(state.jobs['build']!.deadlineUtc, deadline);
    state = service.reconcile(state, observation: observation(state,
      now.subtract(const Duration(days: 1)).add(state.jobs['build']!.clock!.remaining)));
    await store(storage).save(withState(base, state));
    state = stateOf(await store(storage).load());
    final completion = state.jobs['build']!.finishedAtUtc;
    state = service.reconcile(state, observation: observation(state, DateTime.utc(2099)));
    expect(state.jobs['build']!.status, 'completed');
    expect(state.jobs['build']!.finishedAtUtc, completion);
    expect(state.facilities['solar_array'], 1);
    expect(state.resources, paid);
    expect(state.packedStock, stock);
    expect(state.crewAssignments, isEmpty);
  });

  test('codec preserves occurrence, assistance, allocation, clocks and shutdown through repair continuation', () {
    final rules = document('progression_rules');
    final level = migration.config.levels.first;
    rules['recovery']['damage_occurrences'] = [{
      'level_id': level, 'event_id': 'meteor_shower', 'sequence': 1,
      'facility_id': 'solar_array', 'units': 1, 'essential': true,
    }];
    final config = configuration(rules: rules);
    final codec = ProgressionCodec(config, equipmentIds: {'solar_panel','spare_part'});
    final service = RealTimeProgressionService(config);
    final damageId = '$level:meteor_shower:1';
    var state = ProgressionState(levelId: level, facilities: {'solar_array': 1},
      operatingStates: {'solar_array': 'off'}, crewRoles: {'e': 'Engineer'});
    state = service.observeDamage(state, occurrenceId: damageId, damagedCount: 1).state;
    state = service.confirmDamage(state, damageId).state;
    state = service.recover(state, identity: 'repair:$damageId').state;
    state = service.start(state, jobId: 'repair', kind: 'major_repair', targetId: 'solar_array',
      crewId: 'e', observation: observation(state, now)).state;
    state = codec.decode(jsonDecode(jsonEncode(codec.encode(state))));
    expect(state.jobs['repair']!.repairDamageId, damageId);
    expect(state.jobs['repair']!.assistancePaid, {'materials': 2.0, 'spare_part': 1.0});
    state = service.cancel(state, jobId: 'repair', observation: observation(state, now)).state;
    state = codec.decode(jsonDecode(jsonEncode(codec.encode(state))));
    expect(state.assistance['repair:$damageId'], {'materials': 2.0, 'spare_part': 1.0});
    state = service.start(state, jobId: 'retry', kind: 'major_repair', targetId: 'solar_array',
      crewId: 'e', observation: observation(state, now)).state;
    state = service.reconcile(state, observation: observation(state, state.jobs['retry']!.deadlineUtc!));
    state = codec.decode(jsonDecode(jsonEncode(codec.encode(state))));
    expect(state.assistance.containsKey('repair:$damageId'), isFalse);
    expect(state.damageObservations[damageId]!.remaining, 0);
    expect(state.operatingStates['solar_array'], 'off');
  });

  test('codec rejects broken clocks, invalid entitlements and inconsistent facility states', () {
    final save = migration.migrate(fixture());
    final state = stateOf(save);
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (row) => row['lastObservationToken'] = -2,
      (row) => row['assistance'] = {'invented': {'materials': 100}},
      (row) => row['operatingStates'] = {'crew_habitat': 'underConstruction'},
      (row) => row['packedStock'] = {'invented_equipment': 1},
      (row) {
        (row['packedStock'] as Map)['spare_part'] = 1;
        (row['resources'] as Map)['spare_part'] = 1;
      },
    ]) {
      final row = jsonDecode(jsonEncode(migration.codec.encode(state))) as Map<String, dynamic>;
      mutate(row);
      expect(() => migration.codec.decode(row), throwsFormatException);
    }
    expect(() => ProgressionClock.restore(
      startedAtUtc: now, originalDeadlineUtc: now,
      duration: const Duration(minutes: 1), remaining: const Duration(minutes: 2),
      observedAtUtc: now, rollbackCount: 0, observationToken: 0,
    ), throwsFormatException);
  });

  test('controller serializes preferences with job completion and rejects stale setup callbacks', () async {
    final storage = _Storage();
    var time = now;
    final controller = CampaignController(repository: repository, store: store(storage),
      initial: fixture(), utcNow: () => time);
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.start(jobId: 'build', kind: 'construction', targetId: 'solar_array');
    time = controller.progression.jobs['build']!.deadlineUtc!;
    await Future.wait([controller.updateSetting('reduceMotion', true), controller.reconcile()]);
    final restored = await store(storage).load();
    expect(restored.settings['reduceMotion'], isTrue);
    expect(stateOf(restored).jobs['build']!.status, 'completed');
    expect(await controller.completePrologue(fixture(), expectedGeneration: controller.setupGeneration), isTrue);
    expect(controller.progression.facilities['solar_array'], 1); // Replay grants nothing.
    final oldGeneration = controller.setupGeneration;
    await controller.resetCampaign();
    expect(await controller.completePrologue(fixture(), expectedGeneration: oldGeneration), isFalse);
    expect(controller.save.prologueComplete, isFalse);
  });
}

class _Storage implements LocalStringStore {
  final values = <String, String>{};
  final writes = <(String, String)>[];
  bool failNextPrimary = false, corruptNextPrimary = false;
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    writes.add((key, value));
    if (key == CampaignSaveStore.storageKey && failNextPrimary) {
      failNextPrimary = false;
      throw StateError('Injected write failure');
    }
    if (key == CampaignSaveStore.storageKey && corruptNextPrimary) {
      corruptNextPrimary = false;
      values[key] = '{interrupted';
    } else {
      values[key] = value;
    }
  }
}
