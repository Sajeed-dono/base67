import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:base67/app/campaign_save.dart';
import 'package:base67/app/campaign_save_store.dart';
import 'package:base67/app/game_router.dart';
import 'package:base67/data/models/data_class.dart';
import 'package:base67/data/repositories/game_data_repository.dart';
import 'package:base67/game/campaign_map_screen.dart';
import 'package:base67/game/home_base_screen.dart';
import 'package:base67/prologue/prologue.dart';
import 'package:base67/ui/crew_bean.dart';
import 'package:base67/ui/game_widgets.dart';
import 'package:base67/ui/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameDataRepository repository;
  setUpAll(() async {
    repository = await GameDataRepository.load();
  });

  for (final viewport in const [
    Size(360, 800),
    Size(800, 1100),
    Size(1024, 1366),
  ]) {
    testWidgets(
      'Home Base and Campaign Map fit ${viewport.width.toInt()}dp at 1.4x text',
      (tester) async {
        _setViewport(tester, viewport);
        final homeRoutes = <String>[];
        final openedMissions = <String>[];
        await tester.pumpWidget(
          _shell(
            viewport,
            HomeBaseScreen(
              save: const CampaignSave(),
              repository: repository,
              navigate: homeRoutes.add,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('Your Mars settlement'), findsOneWidget);
        expect(find.byType(MarsPanel), findsWidgets);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          _shell(
            viewport,
            CampaignMapScreen(
              save: const CampaignSave(),
              repository: repository,
              openLevel: openedMissions.add,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
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
        // Chapter panels are built lazily below the enlarged introduction.
        await tester.scrollUntilVisible(
          firstMission,
          300,
          scrollable: campaignScrollable,
          continuous: true,
        );
        // The final ensureVisible jump needs a layout frame before hit testing.
        await tester.pump();
        expect(find.byType(MarsPanel), findsWidgets);
        expect(firstMission, findsOneWidget);
        expect(firstMission.hitTestable(), findsOneWidget);
        await tester.tap(firstMission);
        await tester.pump();
        expect(openedMissions, ['L01_first_light']);
        _expectNoHorizontalScrolling(tester);
        expect(
          find.text('Complete the earlier mission to unlock this goal.'),
          findsNothing,
        );
        await tester.scrollUntilVisible(
          find.text('The Final Mission'),
          500,
          scrollable: campaignScrollable,
          continuous: true,
        );
        await tester.pump();
        expect(find.text('The Final Mission'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('campaign-node-L15_the_final_mission')),
          findsOneWidget,
        );
        expect(
          tester
              .widget<InkWell>(
                find.byKey(
                  const ValueKey('campaign-node-L15_the_final_mission'),
                ),
              )
              .onTap,
          isNull,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          _shell(
            viewport,
            HomeBaseScreen(
              save: const CampaignSave(),
              repository: repository,
              navigate: homeRoutes.add,
            ),
          ),
        );
        await tester.pump();
        // The phone ListView builds reserves lazily below the map controls.
        // Bring the whole panel into view before checking missing amounts.
        final reserves = find.widgetWithText(MarsPanel, 'Base reserves');
        await tester.scrollUntilVisible(
          reserves,
          300,
          scrollable: find
              .descendant(
                of: find.byType(HomeBaseScreen),
                matching: find.byType(Scrollable),
              )
              .first,
          continuous: true,
        );
        await tester.pump();
        expect(find.text('Not set yet'), findsNothing);
        expect(find.text('—'), findsWidgets);
        expect(reserves.hitTestable(), findsOneWidget);
        expect(
          find.descendant(of: reserves, matching: find.text('—')),
          findsNWidgets(4),
        );
        for (final resource in ['Power', 'Water', 'Food', 'Oxygen']) {
          expect(
            find.descendant(of: reserves, matching: find.text(resource)),
            findsOneWidget,
          );
        }
        final homeScrollable = find
            .descendant(
              of: find.byType(HomeBaseScreen),
              matching: find.byType(Scrollable),
            )
            .first;
        const navigation = {
          'Campaign Map': '/campaign',
          'Build': '/build',
          'Research': '/research',
          'Crew': '/crew',
          'Mars Notebook': '/notebook',
          'Badges': '/badges',
          'Mission Patch': '/patch',
          'Settings': '/settings',
          'About': '/about',
          'Credits': '/credits',
        };
        final expectedRoutes = <String>[];
        for (final entry in navigation.entries) {
          final button = find.widgetWithText(FilledButton, entry.key);
          await tester.scrollUntilVisible(
            button,
            300,
            scrollable: homeScrollable,
            continuous: true,
          );
          await tester.pump();
          _expectUsable(tester, button, tester.getRect(homeScrollable));
          await tester.tap(button);
          await tester.pump();
          expectedRoutes.add(entry.value);
          expect(homeRoutes, expectedRoutes);
        }
        expect(homeRoutes, navigation.values.toList());
        _expectNoHorizontalScrolling(tester);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
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

  for (final viewport in const [
    Size(360, 800),
    Size(800, 1100),
    Size(1024, 1366),
  ]) {
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
        _expectNoHorizontalScrolling(tester);
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
        const essentialActions = {
          '/settings': ['Replay prologue', 'Reset campaign'],
          '/build': ['Check job completion'],
          '/research': ['Check job completion'],
        };
        for (final route in routes) {
          navigator.pushNamed(route, arguments: 'L01_first_light');
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
          expect(
            tester.takeException(),
            isNull,
            reason: '$route at ${viewport.width}dp',
          );
          _expectNoHorizontalScrolling(tester);
          for (final label in essentialActions[route] ?? const <String>[]) {
            final action = find.widgetWithText(GameButton, label);
            final scrollable = find.byType(Scrollable).first;
            await tester.scrollUntilVisible(
              action,
              300,
              scrollable: scrollable,
              continuous: true,
            );
            await tester.pump();
            _expectUsable(tester, action, tester.getRect(scrollable));
            expect(tester.widget<GameButton>(action).onPressed, isNotNull);
            // Inspect these controls without resetting or mutating a campaign.
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '$route essential controls',
          );
          final back = find.byType(BackButton);
          if (back.evaluate().isNotEmpty) {
            expect(back, findsOneWidget);
            expect(back.hitTestable(), findsOneWidget);
            await tester.tap(back);
          } else {
            // Prologue has its own scene controls rather than an AppBar.
            navigator.pop();
          }
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
          expect(tester.takeException(), isNull, reason: 'closing $route');
        }
        _resetViewport(tester);
      },
    );
  }
  for (final width in [360.0, 800.0, 1024.0]) {
    testWidgets(
      'Splash scrolls, centers and navigates at $width dp with 1.4x text',
      (tester) async {
        // A compact viewport deliberately requires scrolling at every width.
        _setViewport(tester, Size(width, 420));
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          GameRouter(
            repository: repository,
            store: CampaignSaveStore(_MemoryStringStore()),
            save: const CampaignSave(
              prologueComplete: true,
              selectedSiteId: 'gale',
              buildingLevels: {'crew_habitat': 1},
              settings: {'textScale': 1.4, 'reduceMotion': true},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final scrollView = find.byType(SingleChildScrollView);
        expect(scrollView, findsOneWidget);
        final scrollable = find.descendant(
          of: scrollView,
          matching: find.byType(Scrollable),
        );
        final position = tester.state<ScrollableState>(scrollable).position;
        expect(position.maxScrollExtent, greaterThan(0));
        await tester.drag(scrollView, const Offset(0, -120));
        await tester.pumpAndSettle();
        expect(position.pixels, greaterThan(0));
        final home = find.widgetWithText(GameButton, 'Open Home Base');
        final prologue = find.widgetWithText(GameButton, 'Watch the prologue');
        for (final action in [home, prologue]) {
          await tester.ensureVisible(action);
          await tester.pump();
          _expectUsable(tester, action, tester.getRect(scrollView));
          expect(tester.widget<GameButton>(action).onPressed, isNotNull);
        }
        _expectNoHorizontalScrolling(tester);
        expect(tester.takeException(), isNull);

        // Resize the same route: fitting content must recenter and stop scrolling.
        tester.view.physicalSize = Size(width, 1600);
        await tester.pumpAndSettle();
        final viewport = tester.getRect(scrollView);
        final content = find
            .ancestor(of: home, matching: find.byType(Column))
            .first;
        final contentRect = tester.getRect(content);
        expect(position.maxScrollExtent, closeTo(0, .01));
        expect(position.pixels, closeTo(0, .01));
        expect(contentRect.center.dy, closeTo(viewport.center.dy, .01));
        final widthConstraint = find.ancestor(
          of: content,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is ConstrainedBox && widget.constraints.maxWidth == 480,
          ),
        );
        expect(widthConstraint, findsOneWidget);
        expect(
          tester.getSize(widthConstraint).width,
          closeTo(viewport.width < 480 ? viewport.width : 480, .01),
        );
        expect(
          contentRect.width,
          closeTo(
            tester.getSize(widthConstraint).width - GameSpacing.lg * 2,
            .01,
          ),
        );

        final heading = find.byType(ColonySectionHeading);
        final brand = find.text('BASE 67');
        final subtitle = find.text('A new home begins with one good plan.');
        expect(
          tester.widget<Text>(brand).style!.fontSize,
          GameTypography.displaySmall,
        );
        expect(
          tester.widget<Text>(subtitle).style!.fontSize,
          GameTypography.titleMedium,
        );
        expect(
          MediaQuery.textScalerOf(tester.element(brand))
              .scale(GameTypography.displaySmall),
          closeTo(GameTypography.displaySmall * 1.4, .01),
        );
        expect(
          tester.getTopLeft(brand).dy - tester.getBottomLeft(heading).dy,
          closeTo(GameSpacing.md, .01),
        );
        expect(
          tester.getTopLeft(subtitle).dy - tester.getBottomLeft(brand).dy,
          closeTo(GameSpacing.xs, .01),
        );
        expect(
          tester.getTopLeft(home).dy - tester.getBottomLeft(subtitle).dy,
          closeTo(28, .01),
        );
        expect(
          tester.getTopLeft(prologue).dy - tester.getBottomLeft(home).dy,
          closeTo(GameSpacing.iconGap, .01),
        );
        for (final action in [home, prologue]) {
          _expectUsable(tester, action, viewport);
        }
        _expectNoHorizontalScrolling(tester);
        expect(tester.takeException(), isNull);

        // Exercise the real router callbacks, including return from story replay.
        await tester.tap(prologue);
        await tester.pumpAndSettle();
        expect(find.byType(Prologue), findsOneWidget);
        expect(find.textContaining('THE LAST YEAR'), findsOneWidget);
        tester.state<NavigatorState>(find.byType(Navigator).last).pop();
        await tester.pumpAndSettle();
        _expectUsable(tester, home, tester.getRect(scrollView));
        await tester.tap(home);
        await tester.pump();
        await tester.pump();
        expect(find.byType(HomeBaseScreen), findsOneWidget);
        expect(find.text('Your Mars settlement'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

void _expectNoHorizontalScrolling(WidgetTester tester) {
  for (final scrollable in tester.widgetList<Scrollable>(
    find.byType(Scrollable),
  )) {
    expect(
      scrollable.axisDirection,
      anyOf(AxisDirection.down, AxisDirection.up),
    );
  }
}

void _expectUsable(WidgetTester tester, Finder target, Rect viewport) {
  expect(target, findsOneWidget);
  expect(target.hitTestable(), findsOneWidget);
  final bounds = tester.getRect(target);
  expect(bounds.width, greaterThanOrEqualTo(GameSpacing.touchTarget));
  expect(bounds.height, greaterThanOrEqualTo(GameSpacing.touchTarget));
  expect(bounds.left, greaterThanOrEqualTo(viewport.left - .01));
  expect(bounds.right, lessThanOrEqualTo(viewport.right + .01));
  expect(bounds.top, greaterThanOrEqualTo(viewport.top - .01));
  expect(bounds.bottom, lessThanOrEqualTo(viewport.bottom + .01));
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
