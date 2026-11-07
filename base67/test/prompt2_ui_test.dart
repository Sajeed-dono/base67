import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:base67/app/campaign_save.dart';
import 'package:base67/app/campaign_save_store.dart';
import 'package:base67/app/game_router.dart';
import 'package:base67/data/models/data_class.dart';
import 'package:base67/data/repositories/game_data_repository.dart';
import 'package:base67/game/campaign_map_screen.dart';
import 'package:base67/game/home_base_screen.dart';
import 'package:base67/ui/crew_bean.dart';
import 'package:base67/ui/game_widgets.dart';
import 'package:base67/ui/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameDataRepository repository;
  setUpAll(() async {
    repository = await GameDataRepository.load();
  });

  for (final viewport in const [Size(360, 800), Size(800, 1100)]) {
    testWidgets(
      'Home Base and Campaign Map fit ${viewport.width.toInt()}dp at 1.4x text',
      (tester) async {
        _setViewport(tester, viewport);
        await tester.pumpWidget(
          _shell(
            viewport,
            HomeBaseScreen(
              save: const CampaignSave(),
              repository: repository,
              navigate: (_) {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('Your Mars settlement'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          _shell(
            viewport,
            CampaignMapScreen(
              save: const CampaignSave(),
              repository: repository,
              openLevel: (_) {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('One base. Fifteen missions.'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('The Final Mission'),
          500,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('The Final Mission'), findsOneWidget);
        expect(tester.takeException(), isNull);
        _resetViewport(tester);
      },
    );
  }

  testWidgets('reusable cards and controls build with accessible targets', (
    tester,
  ) async {
    _setViewport(tester, const Size(400, 1000));
    await tester.pumpWidget(
      MaterialApp(
        theme: Base67Theme.light(),
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GameButton(label: 'Start mission', onPressed: () {}),
              const InfoCard(child: Text('Information')),
              const MapPin(
                number: 1,
                state: MapPinState.available,
                label: 'First Light',
              ),
              const ProgressPath(
                states: [MapPinState.available, MapPinState.locked],
              ),
              const StarRating(stars: 2),
              const DataChip(DataClass.nasa),
              const FactCard(
                title: 'A Mars day',
                body: 'A sol is one Martian day.',
                dataClass: DataClass.nasa,
              ),
              const DaveBubble(message: 'Welcome to the base.'),
              const RadioBubble(
                speaker: 'MISSION CONTROL',
                message: 'Systems are ready.',
              ),
              const ModalSheet(
                title: 'Quick details',
                child: Text('More information stays in a focused panel.'),
              ),
              const GaugeBar(
                label: 'Stored power',
                value: .65,
                trailing: '65%',
              ),
              TimerCard(
                activity: 'Solar Array',
                deadlineUtc: DateTime(2027),
                outcome: 'Power becomes available.',
              ),
              const ResourceCard(
                name: 'Water',
                amount: 12,
                capacity: 20,
                change: 'Stored amount',
              ),
              const BuildingCard(
                name: 'Solar Array',
                level: 1,
                state: 'Built',
                upgrade: 'More panels',
                progress: .5,
              ),
              const ResearchCard(
                name: 'Energy Basics',
                prerequisites: 'First Light',
                state: 'Ready',
                progress: .25,
              ),
              const CrewAssignmentCard(
                name: 'Ari',
                role: 'Engineer',
                task: 'Panel check',
                status: 'Ready',
                duration: '10 min',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Start mission'), findsOneWidget);
    expect(find.text('A Mars day'), findsOneWidget);
    expect(
      tester.getSize(find.byType(FilledButton).first).height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
    _resetViewport(tester);
  });

  testWidgets(
    'CrewBean draws all roles and moods without motion when requested',
    (tester) async {
      _setViewport(tester, const Size(600, 1100));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Wrap(
                children: [
                  for (final role in CrewRole.values)
                    for (final mood in CrewMood.values)
                      CrewBean(
                        role: role,
                        mood: mood,
                        reducedMotion: true,
                        size: 54,
                      ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byType(CrewBean),
        findsNWidgets(CrewRole.values.length * CrewMood.values.length),
      );
      expect(tester.takeException(), isNull);
      _resetViewport(tester);
    },
  );

  testWidgets('ModalSheet opens as a focused bottom panel', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => ModalSheet.show<void>(
                  context,
                  title: 'Mission details',
                  child: const Text('This panel keeps extra details together.'),
                ),
                child: const Text('Open details'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open details'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Mission details'), findsOneWidget);
    expect(
      find.text('This panel keeps extra details together.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final viewport in const [Size(360, 800), Size(1024, 1366)]) {
    testWidgets(
      'all navigation screens open at ${viewport.width.toInt()}dp with 1.4x text',
      (tester) async {
        _setViewport(tester, viewport);
        await tester.pumpWidget(
          GameRouter(
            repository: repository,
            store: CampaignSaveStore(_MemoryStringStore()),
            save: const CampaignSave(
              settings: {'textScale': 1.4, 'reduceMotion': true},
            ),
          ),
        );
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'splash at ${viewport.width}dp',
        );
        final navigator = tester.state<NavigatorState>(
          find.byType(Navigator).last,
        );
        const routes = [
          '/prologue',
          '/home',
          '/campaign',
          '/briefing',
          '/planning',
          '/play',
          '/debrief',
          '/build',
          '/research',
          '/crew',
          '/notebook',
          '/badges',
          '/patch',
          '/settings',
          '/about',
          '/credits',
          '/data-check',
          '/design-gallery',
        ];
        for (final route in routes) {
          navigator.pushNamed(route, arguments: 'L01_first_light');
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
          expect(
            tester.takeException(),
            isNull,
            reason: '$route at ${viewport.width}dp',
          );
          navigator.pop();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
          expect(tester.takeException(), isNull, reason: 'closing $route');
        }
        _resetViewport(tester);
      },
    );
  }
}

Widget _shell(Size size, Widget home) => MaterialApp(
  theme: Base67Theme.light(),
  home: MediaQuery(
    data: MediaQueryData(size: size, textScaler: const TextScaler.linear(1.4)),
    child: home,
  ),
);

void _setViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

class _MemoryStringStore implements LocalStringStore {
  final values = <String, String>{};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}
