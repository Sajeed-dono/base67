import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:base67/app/campaign_save.dart';
import 'package:base67/app/campaign_save_store.dart';
import 'package:base67/app/game_router.dart';
import 'package:base67/data/repositories/game_data_repository.dart';

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
      _router(repository, save: const CampaignSave(prologueComplete: true)),
    );
    await tester.tap(find.text('Open Home Base'));
    await _finishRouteTransition(tester);
    expect(find.text('Your Mars settlement'), findsOneWidget);

    await tester.tap(find.byTooltip('Campaign Map'));
    await _finishRouteTransition(tester);
    expect(find.text('One base. Fifteen missions.'), findsOneWidget);

    await tester.tap(find.text('First Light'));
    await _finishRouteTransition(tester);
    expect(find.text('Mission Briefing'), findsOneWidget);
    expect(find.text('First Light'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator).last).pop();
    await _finishRouteTransition(tester);

    await tester.scrollUntilVisible(
      find.text('The Final Mission'),
      500,
      scrollable: find.byType(Scrollable).last,
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
