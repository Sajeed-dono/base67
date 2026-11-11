import 'package:base67/app/campaign_save.dart';
import 'package:base67/data/repositories/game_data_repository.dart';
import 'package:base67/game/home_base_screen.dart';
import 'package:base67/ui/crew_bean.dart';
import 'package:base67/ui/crew_movement.dart';
import 'package:base67/ui/game_widgets.dart';
import 'package:base67/ui/mars_base_painter.dart';
import 'package:base67/ui/settlement_map.dart';
import 'package:base67/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const members = [
  MapCrew(CrewRole.commander, 'Alex'),
  MapCrew(CrewRole.engineer, 'Sam', task: 'clean', mood: CrewMood.working),
  MapCrew(
    CrewRole.scientist,
    'Jo',
    task: 'forecast',
    mood: CrewMood.researching,
  ),
  MapCrew(CrewRole.medic, 'Lee', task: 'care', mood: CrewMood.working),
];

Future<void> animationFrames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 34));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameDataRepository repository;
  setUpAll(() async {
    repository = await GameDataRepository.load();
  });
  for (final width in [360.0, 800.0]) {
    testWidgets('movement controls at $width dp and 1.4 text', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final model = CrewMovement();
      await tester.pumpWidget(
        MaterialApp(
          theme: Base67Theme.light(),
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 900),
              textScaler: const TextScaler.linear(1.4),
              disableAnimations: true,
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: SettlementMap(
                  facilities: const [],
                  crew: members,
                  movement: model,
                ),
              ),
            ),
          ),
        ),
      );
      for (final member in members) {
        final selector = find.byKey(ValueKey('select-${member.id}'));
        expect(selector, findsOneWidget);
        final target = tester.getSize(selector);
        expect(target.height, greaterThanOrEqualTo(48));
        expect(target.width, greaterThanOrEqualTo(48));
      }
      await tester.ensureVisible(find.byKey(const ValueKey('select-engineer')));
      await tester.tap(find.byKey(const ValueKey('select-engineer')));
      await tester.pump();
      expect(model.selected, 'engineer');
      expect(model.manual, isTrue);
      // Put the selected actor in open ground to isolate input from collision.
      final actor = model.actors['engineer']!;
      actor.position = Offset(model.size.width * .1, model.size.height * .8);
      for (final other in model.actors.values) {
        other.path = [];
      }
      final keyboardStart = actor.position;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyW);
      await animationFrames(tester);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyW);
      expect(actor.position.dy, lessThan(keyboardStart.dy));
      final arrowStart = actor.position;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
      await animationFrames(tester);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
      expect(actor.position.dy, lessThan(arrowStart.dy));
      final joystick = find.byKey(const ValueKey('crew-joystick'));
      await tester.ensureVisible(joystick);
      await tester.pump();
      actor.position = Offset(model.size.width * .1, model.size.height * .8);
      final touchStart = actor.position;
      final gesture = await tester.startGesture(tester.getCenter(joystick));
      await gesture.moveBy(const Offset(0, -40));
      await animationFrames(tester);
      expect(actor.position.dy, lessThan(touchStart.dy));
      await gesture.up();
      await tester.pump();
      expect(model.direction, Offset.zero);
      final stopped = actor.position;
      await animationFrames(tester);
      expect(actor.position, stopped);
      expect(
        model.animationSeconds,
        0,
        reason: 'OS reduced motion disables decorative loops.',
      );
      expect(actor.member.task, 'clean');
      final release = find.byKey(const ValueKey('release-crew'));
      await tester.ensureVisible(release);
      await tester.tap(release);
      await tester.pump();
      expect(model.manual, isFalse);
      expect(actor.member.task, 'clean');
      expect(model.destinationId(actor.member), 'solar_array');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      model.dispose();
    });

    testWidgets(
      'Home Base uses the actual shared settlement map at $width dp',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const save = CampaignSave(
          buildingLevels: {'crew_habitat': 1, 'solar_array': 1},
          selectedSiteId: 'gale',
          settings: {'reduceMotion': true},
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: Base67Theme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.4)),
              child: child!,
            ),
            home: HomeBaseScreen(
              save: save,
              repository: repository,
              navigate: (_) {},
            ),
          ),
        );
        final map = tester.widget<SettlementMap>(find.byType(SettlementMap));
        expect(map.crew.length, 4);
        expect(
          map.facilities.firstWhere((f) => f.id == 'solar_array').position,
          SettlementLayout.facilities(save.buildingLevels)
              .firstWhere((f) => f.id == 'solar_array')
              .position,
        );
        expect(
          map.facilities.firstWhere((f) => f.id == 'solar_array').level,
          1,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'accessible direction buttons and joystick cancellation stop safely',
    (tester) async {
      final model = CrewMovement();
      await tester.pumpWidget(
        MaterialApp(
          theme: Base67Theme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SettlementMap(
                facilities: const [],
                crew: members,
                movement: model,
                reducedMotion: true,
              ),
            ),
          ),
        ),
      );
      model.actors['commander']!.position = Offset(
        model.size.width * .1,
        model.size.height * .8,
      );
      final up = find.byTooltip('Move up');
      await tester.ensureVisible(up);
      final before = model.actors['commander']!.position;
      await tester.tap(up);
      await tester.pump();
      expect(model.actors['commander']!.position.dy, lessThan(before.dy));
      final stick = find.byKey(const ValueKey('crew-joystick'));
      await tester.ensureVisible(stick);
      final touch = await tester.startGesture(tester.getCenter(stick));
      await touch.moveBy(const Offset(0, -30));
      await animationFrames(tester);
      await touch.cancel();
      await tester.pump();
      expect(model.direction, Offset.zero);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      model.dispose();
    },
  );

  testWidgets('Home and mission views share session positions without a save', (
    tester,
  ) async {
    final model = CrewMovement();
    final key = GlobalKey<NavigatorState>();
    const units = {'crew_habitat': 1, 'solar_array': 1};
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        theme: Base67Theme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SettlementMap(
              facilities: SettlementLayout.facilities(units),
              crew: members,
              movement: model,
              reducedMotion: true,
            ),
          ),
        ),
      ),
    );
    model.select('engineer');
    final before = model.actors['engineer']!.position;
    final originalSize = model.size;
    key.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: SingleChildScrollView(
            child: MissionBaseView(
              units: units,
              dust: 0,
              night: false,
              storm: false,
              crew: members,
              movement: model,
              reducedMotion: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    final missionMap = find.descendant(
      of: find.byType(MissionBaseView),
      matching: find.byType(SettlementMap),
    );
    expect(missionMap, findsOneWidget);
    expect(ModalRoute.of(tester.element(missionMap))?.isCurrent, isTrue);
    final active = tester.widget<SettlementMap>(missionMap);
    expect(identical(active.movement, model), isTrue);
    expect(model.selected, 'engineer');
    expect(model.manual, isTrue);
    expect(model.size, originalSize);
    expect(model.actors['engineer']!.position, before);
    expect(model.actors['engineer']!.member.task, 'clean');
    expect(
      model.actors['engineer']!.position.dx / model.size.width,
      closeTo(before.dx / originalSize.width, .05),
    );
    expect(
      model.actors['engineer']!.position.dy / model.size.height,
      closeTo(before.dy / originalSize.height, .05),
    );
    key.currentState!.pop();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(model.selected, 'engineer');
    expect(model.actors['engineer']!.member.task, 'clean');
    expect(model.walkable(model.actors['engineer']!.position), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    model.dispose();
  });
}
