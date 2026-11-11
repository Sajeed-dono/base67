import 'dart:convert';

import 'package:base67/app/campaign_controller.dart';
import 'package:base67/app/campaign_migration.dart';
import 'package:base67/app/campaign_save.dart';
import 'package:base67/app/campaign_save_store.dart';
import 'package:base67/data/repositories/game_data_repository.dart';
import 'package:base67/missions/mission_runtime.dart';
import 'package:base67/progression/progression_service.dart';
import 'package:base67/progression/progression_clock.dart';
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
  CampaignSave initial([String site = 'gale']) => migration.migrate(
    CampaignSave(
      prologueComplete: true,
      selectedSiteId: site,
      deterministicSeed: 42,
      settings: {'reduceMotion': true},
      buildingLevels: {'crew_habitat': 1},
    ),
  );
  ProgressionState state() =>
      migration.codec.decode(jsonDecode(initial().progressionJson!));
  ProgressionState powered() => state().copyWith(
    facilities: {'crew_habitat': 1, 'solar_array': 8, 'battery_bank': 6},
    resources: {
      ...state().resources,
      'battery_kwh': runtime.config.number('battery_unit_kwh') * 3,
    },
  );
  Map<String, dynamic> session(ProgressionState p, int level) => runtime.open(
    runtime.levels[level - 1],
    runtime.world(p, null, site: 'gale', seed: 42),
    null,
  );

  test('power preview agrees with the normal step and cannot create saved evidence', () {
    final p = powered();
    final s = {
      ...session(p, 2),
      'phase': 'planning',
      'learned': ['storage'],
    };
    final beforeP = jsonEncode(migration.codec.encode(p));
    final beforeS = jsonEncode(s);
    final report = runtime.powerReport(p, s, site: 'gale', seed: 42);
    final again = runtime.powerReport(p, s, site: 'gale', seed: 42);
    final actual = runtime.step(
      p,
      runtime.begin(s, runtime.world(p, s, site: 'gale', seed: 42)),
      site: 'gale',
      seed: 42,
    );
    expect(report.projectedKwh, actual.progression.resources['battery_kwh']);
    expect(report.generationKw, actual.session['generation']);
    expect(report.demandKw, actual.session['demand']);
    expect(report.projectedKwh, again.projectedKwh);
    expect(report.objectives, again.objectives);
    expect(actual.session['charged'], isTrue);
    expect(
      report.objectives
          .singleWhere((row) => row.$1 == 'Charging observed in this attempt')
          .$2,
      isFalse,
    );
    expect(jsonEncode(migration.codec.encode(p)), beforeP);
    expect(jsonEncode(s), beforeS);
    expect(p.completedLevels, isEmpty);
  });

  test(
    'missing or damaged power equipment produces an honest finite forecast',
    () {
      for (final p in [
        state(),
        powered().copyWith(
          damagedUnits: {'solar_array': 8},
          resources: {...powered().resources, 'battery_kwh': 0},
        ),
      ]) {
        final s = session(p, 2);
        final before = jsonEncode(migration.codec.encode(p));
        final report = runtime.powerReport(p, s, site: 'gale', seed: 42);
        expect(report.solarUnits, 0);
        expect(report.previewNeedsReview, isTrue);
        expect(
          [
            report.projectedKwh,
            report.generationKw,
            report.demandKw,
            report.reserveKwh,
          ].every((v) => v.isFinite),
          isTrue,
        );
        expect(jsonEncode(migration.codec.encode(p)), before);
      }
    },
  );

  test(
    'preview cannot finish construction or release its assigned Engineer',
    () {
      final service = RealTimeProgressionService(migration.config);
      final p = powered().copyWith(
        levelId: runtime.levels[1],
        facilities: {'crew_habitat': 1, 'solar_array': 1, 'battery_bank': 1},
        resources: {
          ...powered().resources,
          'battery_kwh': runtime.config.number('battery_unit_kwh') / 2,
        },
      );
      final started = service.start(
        p,
        jobId: 'preview-battery',
        kind: 'construction',
        targetId: 'battery_bank',
        crewId: 'Engineer',
        observation: ClockObservation(
          token: 0,
          utc: DateTime.utc(2026, 11, 11),
        ),
      );
      expect(started.code, 'active');
      final before = jsonEncode(migration.codec.encode(started.state));
      final s = session(started.state, 2);
      runtime.powerReport(started.state, s, site: 'gale', seed: 42);
      expect(jsonEncode(migration.codec.encode(started.state)), before);
      expect(started.state.jobs['preview-battery']!.status, 'active');
      expect(started.state.crewAssignments['Engineer'], 'preview-battery');
      expect(started.state.facilities['battery_bank'], 1);
    },
  );

  test('Level 2 local heater control does not unlock other loads or later station gates', () {
    final p = powered();
    expect(runtime.canControlLoad(p, runtime.levels[0], 'heater'), isFalse);
    expect(runtime.canControlLoad(p, runtime.levels[1], 'heater'), isTrue);
    for (final load in [
      'habitat_base',
      'greenhouse_lights',
      'ice_miner',
      'invented',
    ]) {
      expect(runtime.canControlLoad(p, runtime.levels[1], load), isFalse);
    }
    expect(
      runtime.canControlLoad(
        p.copyWith(facilities: {'solar_array': 8}),
        runtime.levels[1],
        'heater',
      ),
      isFalse,
    );
    expect(runtime.canControlLoad(p, runtime.levels[2], 'heater'), isFalse);
    expect(
      runtime.canControlLoad(
        p.copyWith(facilities: {...p.facilities, 'power_control_station': 1}),
        runtime.levels[2],
        'heater',
      ),
      isTrue,
    );
  });

  test('Level 2 switch saves through the existing controller and cooling uses simulation time', () async {
    final storage = _Memory();
    final p = powered().copyWith(
      levelId: runtime.levels[1],
      completedLevels: {runtime.levels[0]},
    );
    final c = CampaignController(
      repository: repository,
      store: CampaignSaveStore(storage),
      initial: initial().copyWith(
        unlockedLevelIds: runtime.levels.take(2).toSet(),
        progressionJson: jsonEncode(migration.codec.encode(p)),
      ),
      utcNow: () => DateTime.utc(2026, 11, 11),
    );
    addTearDown(c.dispose);
    await c.initialize();
    final id = runtime.levels[1];
    await c.missionAction(id, 'open');
    expect(
      await c.missionAction(id, 'toggle', value: 'heater'),
      'system_locked',
    );
    await c.missionAction(id, 'review');
    await c.missionAction(id, 'plan');
    final before = c.missionWorld;
    final beforeResources = c.progression.resources;
    final previewOn = runtime.powerReport(
      c.progression,
      c.mission!,
      site: 'gale',
      seed: 42,
    );
    expect(await c.missionAction(id, 'toggle', value: 'heater'), 'saved');
    expect(c.mission!['disabled'], contains('heater'));
    expect(c.progression.resources, beforeResources);
    expect(c.missionWorld.elapsedHours, before.elapsedHours);
    final previewOff = runtime.powerReport(
      c.progression,
      c.mission!,
      site: 'gale',
      seed: 42,
    );
    expect(previewOff.demandKw, lessThan(previewOn.demandKw));
    await c.missionAction(id, 'prepare');
    expect(c.missionWorld.elapsedHours, greaterThan(before.elapsedHours));
    expect(c.missionWorld.temperature, lessThan(before.temperature));
    final restored = await CampaignSaveStore(
      storage,
      migrate: migration.migrate,
      validate: migration.validate,
    ).load();
    expect(restored.version, 3);
    expect(restored.missionJson, c.save.missionJson);
    expect(restored.progressionJson, c.save.progressionJson);
  });

  for (final site in ['gale', 'arcadia', 'deuteronilus', 'equatorial_plain']) {
    test(
      'real construction and engine observations progress from Level 1 through Level 2 once at $site',
      () async {
        final storage = _Memory();
        var now = DateTime.utc(2026, 11, 11);
        var c = CampaignController(
          repository: repository,
          store: CampaignSaveStore(storage),
          initial: initial(site),
          utcNow: () => now,
        );
        addTearDown(() => c.dispose());
        await c.initialize();
        var serial = 0;
        Future<void> build(String target) async {
          final id = 'power-test:${serial++}';
          final recipe = migration.config.recipes['construction:$target']!;
          final before = c.missionWorld.elapsedHours;
          expect(
            await c.startMissionJob(
              jobId: id,
              kind: 'construction',
              targetId: target,
              crewId: 'Engineer',
            ),
            'active',
          );
          now = now.add(recipe.duration);
          await c.reconcile();
          expect(c.progression.jobs[id]!.status, 'completed');
          expect(c.missionWorld.elapsedHours, before);
        }

        await build('solar_array');
        for (var number = 1; number <= 2; number++) {
          if (number == 2) {
            for (final target in ['solar_array', 'battery_bank']) {
              while ((c.progression.facilities[target] ?? 0) <
                  migration.config.maxUnits[target]!) {
                await build(target);
              }
            }
          }
          final id = runtime.levels[number - 1];
          expect(await c.missionAction(id, 'open'), 'saved');
          await c.missionAction(id, 'review');
          await c.missionAction(id, 'plan');
          await c.missionAction(
            id,
            'learn',
            value: runtime.definition(id)['answer'] as String,
          );
          if (number == 1) {
            while (runtime
                    .powerReport(
                      c.progression,
                      c.mission!,
                      site: site,
                      seed: 42,
                    )
                    .previewNeedsReview &&
                c.progression.facilities['solar_array']! <
                    migration.config.maxUnits['solar_array']!) {
              await build('solar_array');
            }
          }
          if (number == 2) {
            // Test strategy, not a new mission rule: fill a comfortable buffer using
            // actual solar steps, never by changing stock or granting energy.
            for (
              var i = 0;
              i < runtime.config.number('sol_hours').ceil() * 2;
              i++
            ) {
              final battery = c.missionWorld.resources['battery_kwh']!;
              if (battery.quantity >= battery.capacity * .85) break;
              await c.missionAction(id, 'prepare');
            }
            final battery = c.missionWorld.resources['battery_kwh']!;
            expect(
              battery.quantity,
              greaterThanOrEqualTo(battery.capacity * .85),
            );
          }
          final beforePreview = c.save.encode();
          runtime.powerReport(c.progression, c.mission!, site: site, seed: 42);
          expect(c.save.encode(), beforePreview);
          expect(c.save.completedLevelIds.contains(id), isFalse);
          expect(await c.missionAction(id, 'begin'), 'saved');
          for (
            var tick = 0;
            tick < runtime.duration(id).ceil() + 1 &&
                c.mission!['phase'] == 'play';
            tick++
          ) {
            await c.missionAction(id, 'step');
            if (number == 2 && tick == 3 && c.mission!['phase'] == 'play') {
              final beforeRestart = c.save.encode();
              c.dispose();
              final restored = await CampaignSaveStore(
                storage,
                migrate: migration.migrate,
                validate: migration.validate,
              ).load();
              c = CampaignController(
                repository: repository,
                store: CampaignSaveStore(storage),
                initial: restored,
                utcNow: () => now,
              );
              await c.initialize();
              final expected =
                  jsonDecode(beforeRestart) as Map<String, dynamic>;
              final progress = expected['progression'] as Map<String, dynamic>;
              final oldToken = progress['lastObservationToken'] as int;
              // Initialization performs one ordered clock check. Every other
              // field, including the entire mission checkpoint, must match.
              expect(c.progression.lastObservationToken, oldToken + 1);
              progress['lastObservationToken'] = oldToken + 1;
              expect(
                jsonDecode(c.save.encode()),
                expected,
                reason: 'Restart cannot reset the base, mission evidence or reserve.',
              );
            }
          }
          expect(
            c.mission!['result'],
            'success',
            reason: c.mission!['message'] as String,
          );
          expect(c.save.completedLevelIds, contains(id));
          final materials = c.progression.materials;
          final receipts = c.progression.receipts.keys.toSet();
          await c.missionAction(id, 'step');
          expect(c.progression.materials, materials);
          expect(c.progression.receipts.keys.toSet(), receipts);
        }
        expect(
          c.progression.facilities['solar_array'],
          migration.config.maxUnits['solar_array'],
        );
        expect(c.save.selectedSiteId, site);
        final restored = await CampaignSaveStore(
          storage,
          migrate: migration.migrate,
          validate: migration.validate,
        ).load();
        expect(restored.encode(), c.save.encode());
      },
    );
  }
}

class _Memory implements LocalStringStore {
  final values = <String, String>{};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}
