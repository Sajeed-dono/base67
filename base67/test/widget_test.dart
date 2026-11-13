import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:base67/app/campaign_save.dart';
import 'package:base67/app/campaign_save_store.dart';
import 'package:base67/app/game_router.dart';
import 'package:base67/data/repositories/game_data_repository.dart';
import 'package:base67/game/campaign_map_screen.dart';
import 'package:base67/game/settlement_game_screen.dart';

void main() {
  late GameDataRepository repository;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    repository = await GameDataRepository.load();
  });

  testWidgets('splash opens the preserved prologue route', (tester) async {
    _landscape(tester);
    await tester.pumpWidget(_router(repository));
    expect(find.text('Open Home Base'), findsOneWidget);
    await tester.tap(find.text('Watch the prologue'));
    await _finishRouteTransition(tester);
    expect(find.textContaining('THE LAST YEAR'), findsOneWidget);
    expect(find.textContaining('Tap to continue'), findsOneWidget);
  });

  testWidgets(
    'landscape world, campaign drawer and canonical mission flow open',
    (tester) async {
      _landscape(tester);
      await tester.pumpWidget(
        _router(
          repository,
          save: const CampaignSave(
            prologueComplete: true,
            selectedSiteId: 'gale',
            buildingLevels: {'crew_habitat': 1},
            settings: {'reduceMotion': true},
          ),
        ),
      );
      await tester.tap(find.text('Open Home Base'));
      await _finishRouteTransition(tester);
      expect(find.byType(SettlementGameScreen), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('settlement-viewport'))),
        const Size(640, 360),
      );
      await tester.tap(find.byTooltip('Missions'));
      await tester.pumpAndSettle();
      expect(find.text('One base. Fifteen missions.'), findsOneWidget);
      final campaignScrollable = find
          .descendant(
            of: find.byType(CampaignMapScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      final firstMission = find.byKey(
        const ValueKey('campaign-node-L01_first_light'),
      );
      await tester.scrollUntilVisible(
        firstMission,
        250,
        scrollable: campaignScrollable,
        continuous: true,
      );
      await tester.pumpAndSettle();
      expect(firstMission.hitTestable(), findsOneWidget);
      await tester.tap(firstMission);
      await tester.pumpAndSettle();
      final game = tester.widget<SettlementGameScreen>(
        find.byType(SettlementGameScreen),
      );
      expect(game.controller.mission?['level'], 'L01_first_light');
      expect(game.controller.mission?['phase'], 'briefing');
      final review = find.widgetWithText(FilledButton, 'Review base');
      expect(review.hitTestable(), findsOneWidget);
      await tester.tap(review);
      await tester.pumpAndSettle();
      expect(game.controller.mission?['phase'], 'review');
      await tester.tap(find.widgetWithText(FilledButton, 'Make a plan'));
      await tester.pumpAndSettle();
      expect(game.controller.mission?['phase'], 'planning');
      expect(
        find.widgetWithText(FilledButton, 'Build equipment').hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Missions'));
      await tester.pumpAndSettle();
      final scroll = find
          .descendant(
            of: find.byType(CampaignMapScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('The Final Mission'),
        400,
        scrollable: scroll,
        continuous: true,
      );
      expect(find.text('The Final Mission'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(SettlementGameScreen), findsOneWidget);
      expect(find.byTooltip('Back'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

void _landscape(WidgetTester tester) {
  tester.view.physicalSize = const Size(640, 360);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

GameRouter _router(
  GameDataRepository repository, {
  CampaignSave save = const CampaignSave(),
}) => GameRouter(
  repository: repository,
  store: CampaignSaveStore(_MemoryStringStore()),
  save: save,
);

Future<void> _finishRouteTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

class _MemoryStringStore implements LocalStringStore {
  final values = <String, String>{};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}
