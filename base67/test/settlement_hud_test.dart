import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:base67/app/campaign_controller.dart';
import 'package:base67/app/campaign_save_store.dart';
import 'package:base67/game/settlement_game_screen.dart';
import 'package:base67/ui/crew_movement.dart';
import 'package:flutter/rendering.dart';

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
  for (final size in [
    const Size(640, 360),
    const Size(960, 420),
    const Size(360, 800),
  ]) {
    testWidgets('compact settlement HUD fits $size and discloses controls', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = CampaignController(
        repository: repository,
        store: CampaignSaveStore(_Memory()),
        initial: migration.migrate(
          const CampaignSave(
            prologueComplete: true,
            selectedSiteId: 'gale',
            settings: {'reduceMotion': true},
            buildingLevels: {'crew_habitat': 1},
          ),
        ),
      );
      final movement = CrewMovement();
      await c.initialize();
      await tester.pumpWidget(
        MaterialApp(
          theme: Base67Theme.missionControl(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          ),
          home: RepaintBoundary(
            key: const ValueKey('hud-capture'),
            child: ListenableBuilder(
              listenable: c,
              builder: (context, _) => SettlementGameScreen(
                controller: c,
                repository: repository,
                movement: movement,
                navigate: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(
        tester.getSize(find.byKey(const ValueKey('settlement-viewport'))),
        size,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('crew-joystick'))),
        const Size(92, 92),
      );
      expect(find.text('Power'), findsNothing);
      expect(find.text('Oxygen'), findsNothing);
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel(RegExp(r'^Power: .* kWh$')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Oxygen: .* kg$')), findsOneWidget);
      for (final name in ['Build', 'Crew', 'Pause']) {
        expect(find.byTooltip(name).hitTestable(), findsOneWidget);
        expect(
          tester.getSize(find.byTooltip(name)).shortestSide,
          greaterThanOrEqualTo(48),
        );
      }
      expect(find.byTooltip('Missions'), findsNothing);
      expect(find.byTooltip('Zoom in'), findsNothing);
      expect(find.byTooltip('Zoom out'), findsNothing);
      expect(find.byKey(const ValueKey('select-engineer')), findsNothing);
      final action = find.byKey(const ValueKey('mission-action'));
      final actionRect = tester.getRect(action);
      expect(action.hitTestable(), findsOneWidget);
      expect(actionRect.center.dx, greaterThan(size.width / 2));
      expect(actionRect.bottom, greaterThan(size.height - 32));
      expect(actionRect.left, greaterThanOrEqualTo(108));
      expect(
        actionRect.overlaps(
          tester.getRect(find.byKey(const ValueKey('crew-chip'))),
        ),
        isFalse,
      );
      const review = String.fromEnvironment('BASE67_REVIEW_DIR');
      if (review.isNotEmpty) {
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('hud-capture')),
          );
          final image = await boundary.toImage();
          try {
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            Directory(review).createSync(recursive: true);
            File('$review/hud-${size.width.toInt()}.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
      }
      final objective = find.byKey(const ValueKey('mission-objective'));
      final expandedWidth = tester.getSize(objective).width;
      await tester.pump(GameMotion.objectiveTimeout);
      expect(tester.getSize(objective).width, lessThan(expandedWidth));
      await tester.tap(objective);
      await tester.pump();
      expect(tester.getSize(objective).width, expandedWidth);
      await tester.tap(find.byKey(const ValueKey('crew-chip')));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('select-engineer')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('select-engineer')));
      await tester.pump();
      expect(movement.selected, 'engineer');
      expect(find.byKey(const ValueKey('select-engineer')), findsNothing);
      await tester.tap(find.byTooltip('Pause'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byTooltip('Missions'), 100);
      await tester.pump();
      expect(find.text('Missions'), findsOneWidget);
      expect(movement.direction, Offset.zero);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(action.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
      movement.dispose();
    });
  }
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

class _Memory implements LocalStringStore {
  final values = <String, String>{};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}
