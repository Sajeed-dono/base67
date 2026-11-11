import 'dart:convert';

import 'package:base67/app/campaign_migration.dart';
import 'package:base67/app/campaign_save.dart';
import 'package:base67/game/home_base_screen.dart';
import 'package:base67/data/repositories/game_data_repository.dart';
import 'package:base67/progression/progression_clock.dart';
import 'package:base67/progression/progression_service.dart';
import 'package:base67/ui/game_widgets.dart';
import 'package:base67/ui/settlement_status_panel.dart';
import 'package:base67/ui/settlement_map.dart';
import 'package:base67/sim/sim_state.dart';
import 'package:base67/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CampaignMigration migration;
  late GameDataRepository repository;
  setUpAll(() async {
    repository = await GameDataRepository.load();
    migration = CampaignMigration(repository);
  });
  testWidgets(
    'Home renders canonical night, storm and panel dust without changing the save',
    (tester) async {
      final save = migration.migrate(
        const CampaignSave(
          prologueComplete: true,
          selectedSiteId: 'gale',
          settings: {'reduceMotion': true},
          buildingLevels: {'crew_habitat': 1},
        ),
      );
      final before = save.encode();
      final state = migration.codec.decode(jsonDecode(save.progressionJson!));
      final config = migration.missions.config;
      final time = config.number('daylight_hours') + 1;
      final world = migration.missions
          .world(state, null, site: 'gale', seed: 42)
          .copyWith(
            elapsedHours: time,
            dust: .2,
            activeEvents: {
              'dust_storm': ActiveEvent('dust_storm', time, time + 1),
            },
          );
      await tester.pumpWidget(
        MaterialApp(
          theme: Base67Theme.light(),
          home: HomeBaseScreen(
            save: save,
            repository: repository,
            world: world,
            progression: state,
            solHours: config.number('sol_hours'),
            daylightHours: config.number('daylight_hours'),
            navigate: (_) {},
          ),
        ),
      );
      final map = find.byType(SettlementMap);
      await tester.scrollUntilVisible(map, 300, continuous: true);
      await tester.pump();
      final widget = tester.widget<SettlementMap>(map);
      expect(widget.night, isTrue);
      expect(widget.storm, isTrue);
      expect(widget.dust, .2);
      expect(save.encode(), before);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final width in [360.0, 800.0, 1024.0]) {
    testWidgets('HUD and corrected-clock job snapshot fit $width dp', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final save = migration.migrate(
        const CampaignSave(
          prologueComplete: true,
          selectedSiteId: 'gale',
          buildingLevels: {'crew_habitat': 1},
        ),
      );
      final original = migration.codec.decode(
        jsonDecode(save.progressionJson!),
      );
      final service = RealTimeProgressionService(migration.config);
      final start = service.start(
        original,
        jobId: 'hud-solar',
        kind: 'construction',
        targetId: 'solar_array',
        crewId: 'Engineer',
        observation: ClockObservation(token: 0, utc: DateTime.utc(2099)),
      );
      expect(start.code, 'active');
      final corrected = service.reconcile(
        start.state,
        observation: ClockObservation(
          token: 1,
          utc: DateTime.utc(2026, 11, 12),
        ),
      );
      final state = service.reconcile(
        corrected,
        observation: ClockObservation(
          token: 2,
          utc: DateTime.utc(2026, 11, 12, 0, 0, 5),
        ),
      );
      final before = jsonEncode(migration.codec.encode(state));
      String? action;
      await tester.pumpWidget(
        MaterialApp(
          theme: Base67Theme.light(),
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 1100),
              textScaler: const TextScaler.linear(1.4),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    SettlementStatusPanel(
                      world: migration.missions.world(
                        state,
                        null,
                        site: 'gale',
                        seed: 42,
                      ),
                    ),
                    SavedJobsPanel(
                      jobs: state.jobs.values,
                      onManage: () => action = 'manage',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('—'), findsOneWidget);
      final job = state.jobs['hud-solar']!;
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is GameCopy &&
              w.text.contains(
                '${job.clock!.remaining.inSeconds} real seconds at last check.',
              ),
        ),
        findsOneWidget,
      );
      final button = find.widgetWithText(GameButton, 'Manage jobs');
      await tester.ensureVisible(button);
      expect(button.hitTestable(), findsOneWidget);
      await tester.tap(button);
      expect(action, 'manage');
      expect(jsonEncode(migration.codec.encode(state)), before);
      expect(state.jobs['hud-solar']!.status, 'active');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
