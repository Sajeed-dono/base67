import 'dart:convert';

import 'package:base67/app/campaign_migration.dart';
import 'package:base67/app/campaign_save.dart';
import 'package:base67/data/repositories/game_data_repository.dart';
import 'package:base67/game/campaign_map_screen.dart';
import 'package:base67/progression/progression_service.dart';
import 'package:base67/ui/game_widgets.dart';
import 'package:base67/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameDataRepository repository;
  setUpAll(() async {
    repository = await GameDataRepository.load();
  });
  for (final width in [360.0, 800.0, 1024.0]) {
    testWidgets(
      'campaign details reflect persisted completion and real reward at $width dp',
      (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final migration = CampaignMigration(repository);
        // Explicit presentation fixture; mission success is tested through the
        // actual engine in power_mission_test, not manufactured by this widget.
        final initial = migration.migrate(
          const CampaignSave(
            prologueComplete: true,
            selectedSiteId: 'gale',
            buildingLevels: {'crew_habitat': 1},
          ),
        );
        final first = migration.config.levels.first,
            second = migration.config.levels[1];
        final state = RealTimeProgressionService(migration.config).resupply(
          migration.codec
              .decode(jsonDecode(initial.progressionJson!))
              .copyWith(completedLevels: {first}, levelId: second),
        );
        final save = initial.copyWith(
          unlockedLevelIds: {first, second},
          progressionJson: jsonEncode(migration.codec.encode(state)),
        );
        final before = save.encode();
        final opened = <String>[];
        await tester.pumpWidget(
          MaterialApp(
            theme: Base67Theme.light(),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1100),
                textScaler: const TextScaler.linear(1.4),
              ),
              child: CampaignMapScreen(
                save: save,
                repository: repository,
                progression: state,
                openLevel: opened.add,
              ),
            ),
          ),
        );
        final details = find.widgetWithText(GameButton, 'Mission details');
        await tester.ensureVisible(details);
        await tester.pump();
        expect(details.hitTestable(), findsOneWidget);
        await tester.tap(details);
        await tester.pumpAndSettle();
        expect(find.text('Power Storage'), findsWidgets);
        final briefing = find.widgetWithText(
          GameButton,
          'Open mission briefing',
        );
        await tester.ensureVisible(briefing);
        await tester.pump();
        expect(briefing.hitTestable(), findsOneWidget);
        await tester.tap(briefing);
        await tester.pumpAndSettle();
        expect(opened, [second]);
        final firstNode = find.byKey(ValueKey('campaign-node-$first'));
        await tester.scrollUntilVisible(firstNode, 300, continuous: true);
        await tester.pump();
        await tester.longPress(firstNode);
        await tester.pumpAndSettle();
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is GameCopy &&
                w.text.startsWith(
                  'Recorded resupply: ${migration.config.missionMaterials} materials.',
                ),
          ),
          findsOneWidget,
        );
        expect(save.encode(), before);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
