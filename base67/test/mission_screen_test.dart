import 'dart:convert';

import 'package:base67/app/campaign_controller.dart';
import 'package:base67/app/campaign_migration.dart';
import 'package:base67/app/campaign_save.dart';
import 'package:base67/app/campaign_save_store.dart';
import 'package:base67/data/repositories/game_data_repository.dart';
import 'package:base67/game/mission_screen.dart';
import 'package:base67/ui/game_widgets.dart';
import 'package:base67/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameDataRepository repository;
  setUpAll(() async {
    // Load bundled data outside per-widget-test fake async zones. rootBundle
    // caches futures that otherwise retain the first test's scheduling zone.
    repository = await GameDataRepository.load();
  });
  for (final width in [360.0, 800.0, 1024.0]) {
    for (final index in [0, 1, 6, 8, 12, 14]) {
      testWidgets('mission ${index + 1} at $width dp and enlarged text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final migration = CampaignMigration(repository);
        final initial = migration.migrate(
          const CampaignSave(
            prologueComplete: true,
            selectedSiteId: 'gale',
            deterministicSeed: 42,
            settings: {'reduceMotion': true},
            buildingLevels: {'crew_habitat': 1},
          ),
        );
        final state = migration.codec.decode(
          jsonDecode(initial.progressionJson!),
        );
        final id = migration.config.levels[index];
        final controller = CampaignController(
          repository: repository,
          store: CampaignSaveStore(_Memory()),
          initial: initial.copyWith(
            unlockedLevelIds: migration.config.levels.take(index + 1).toSet(),
            progressionJson: jsonEncode(
              migration.codec.encode(state.copyWith(levelId: id)),
            ),
          ),
          utcNow: () => DateTime.utc(2026, 11, 11),
        );
        final navigation = <String>[];
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: Base67Theme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.4)),
              child: child!,
            ),
            home: ListenableBuilder(
              listenable: controller,
              builder: (context, child) => MissionScreen(
                controller: controller,
                repository: repository,
                levelId: id,
                navigate: navigation.add,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final reviewButton = find.widgetWithText(
          GameButton,
          'Review this base',
        );
        expect(reviewButton, findsOneWidget);
        expect(reviewButton.hitTestable(), findsOneWidget);
        expect(
          tester.getSize(reviewButton).height,
          greaterThanOrEqualTo(GameSpacing.touchTarget),
        );
        await tester.tap(reviewButton);
        await tester.pumpAndSettle();
        expect(controller.mission!['phase'], 'review');
        await controller.missionAction(id, 'plan');
        await tester.pumpAndSettle();
        // Follow visibility rather than assuming a fixed amount of content.
        // One continuous scroll keeps later drags away from the map joystick.
        final returnButton = find.widgetWithText(GameButton, 'Return to base');
        final missionScrollable = find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first;
        if (index <= 1) {
          final powerPlans = find.widgetWithText(
            GameButton,
            'Power build plans',
          );
          await tester.scrollUntilVisible(
            powerPlans,
            300,
            scrollable: missionScrollable,
            continuous: true,
          );
          await tester.pumpAndSettle();
          expect(powerPlans.hitTestable(), findsOneWidget);
          await tester.tap(powerPlans);
          await tester.pumpAndSettle();
          expect(navigation, ['/build']);
          final crewPlans = find.widgetWithText(GameButton, 'Crew assignments');
          await tester.ensureVisible(crewPlans);
          await tester.pump();
          expect(crewPlans.hitTestable(), findsOneWidget);
          await tester.tap(crewPlans);
          await tester.pump();
          expect(navigation, ['/build', '/crew']);
          if (index == 1) {
            final temperature = find.byWidgetPredicate(
              (widget) =>
                  widget is GameCopy &&
                  widget.text.startsWith('Habitat temperature:'),
            );
            await tester.scrollUntilVisible(
              temperature,
              300,
              scrollable: missionScrollable,
              continuous: true,
            );
            await tester.pumpAndSettle();
            expect(temperature.hitTestable(), findsOneWidget);
            final heater = find.byType(SwitchListTile);
            await tester.scrollUntilVisible(
              heater,
              300,
              scrollable: missionScrollable,
              continuous: true,
            );
            await tester.pumpAndSettle();
            expect(heater, findsOneWidget);
            expect(tester.widget<SwitchListTile>(heater).onChanged, isNotNull);
            await tester.tap(heater);
            await tester.pumpAndSettle();
            expect(controller.mission!['disabled'], contains('heater'));
          }
        }
        await tester.scrollUntilVisible(
          returnButton,
          500,
          scrollable: missionScrollable,
          continuous: true,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.widgetWithText(GameButton, 'Return to base'),
          findsOneWidget,
        );
        expect(returnButton.hitTestable(), findsOneWidget);
        expect(
          tester.getSize(returnButton).height,
          greaterThanOrEqualTo(GameSpacing.touchTarget),
        );
        for (final scrollable in tester.widgetList<Scrollable>(
          find.byType(Scrollable),
        )) {
          expect(
            scrollable.axisDirection,
            anyOf(AxisDirection.down, AxisDirection.up),
          );
        }
        expect(controller.mission!['phase'], 'planning');
        expect(controller.progression.facilities, state.facilities);
        expect(controller.progression.resources, state.resources);
        if (index <= 1) {
          final start = find.widgetWithText(GameButton, 'Start mission');
          await tester.tap(find.byTooltip('Pause decisions'));
          await tester.pumpAndSettle();
          expect(tester.widget<GameButton>(start).onPressed, isNull);
          expect(controller.mission!['phase'], 'planning');
          expect(controller.progression.resources, state.resources);
          await tester.tap(find.byTooltip('Mission settings'));
          await tester.pump();
          expect(navigation.last, '/settings');
          await tester.tap(find.byTooltip('Resume decisions'));
          await tester.pumpAndSettle();
          expect(tester.widget<GameButton>(start).onPressed, isNotNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}

class _Memory implements LocalStringStore {
  final Map<String, String> values = {};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}
