import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:base67/app/campaign_save.dart';
import 'package:base67/app/campaign_save_store.dart';
import 'package:base67/app/game_router.dart';
import 'package:base67/data/repositories/game_data_repository.dart';
import 'package:base67/game/campaign_map_screen.dart';
import 'package:base67/game/mission_screen.dart';
import 'package:base67/ui/game_widgets.dart';

void main() {
  late GameDataRepository repository;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    repository = await GameDataRepository.load();
  });

  testWidgets('splash opens the preserved prologue route', (tester) async {
    await tester.pumpWidget(_router(repository));
    expect(find.text('Open Home Base'), findsOneWidget);
    await tester.tap(find.text('Watch the prologue'));
    await _finishRouteTransition(tester);
    expect(find.textContaining('THE LAST YEAR'), findsOneWidget);
    expect(find.textContaining('Tap to continue'), findsOneWidget);
  });

  testWidgets('Home Base and Campaign Map routes open', (tester) async {
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
    expect(find.text('Your Mars settlement'), findsOneWidget);

    await tester.tap(find.byTooltip('Campaign Map'));
    await _finishRouteTransition(tester);
    expect(find.text('One base. Fifteen missions.'), findsOneWidget);

    final campaignScrollable = find.descendant(
      of: find.byType(CampaignMapScreen),
      matching: find.byType(Scrollable),
    ).first;
    final firstMission = find.byKey(
      const ValueKey('campaign-node-L01_first_light'),
    );
    await tester.scrollUntilVisible(
      firstMission,
      300,
      scrollable: campaignScrollable,
      continuous: true,
    );
    expect(firstMission.hitTestable(), findsOneWidget);
    await tester.tap(firstMission);
    await _finishRouteTransition(tester);
    await tester.pumpAndSettle();
    final mission = find.byType(MissionScreen);
    expect(mission, findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('First Light'),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<MissionScreen>(mission).controller.mission?['phase'],
      'briefing',
    );
    final review = find.widgetWithText(GameButton, 'Review this base');
    expect(review, findsOneWidget);
    expect(review.hitTestable(), findsOneWidget);
    expect(tester.widget<GameButton>(review).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
    tester.state<NavigatorState>(find.byType(Navigator).last).pop();
    await _finishRouteTransition(tester);

    await tester.scrollUntilVisible(
      find.text('The Final Mission'),
      500,
      scrollable: campaignScrollable,
      continuous: true,
    );
    expect(find.text('The Final Mission'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator).last).pop();
    await _finishRouteTransition(tester);
  });
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
