import 'package:base67/app/campaign_controller.dart';
import 'package:base67/app/campaign_migration.dart';
import 'package:base67/app/campaign_save.dart';
import 'package:base67/app/campaign_save_store.dart';
import 'package:base67/data/repositories/game_data_repository.dart';
import 'package:base67/game/settlement_game_screen.dart';
import 'package:base67/prologue/prologue.dart';
import 'package:base67/ui/crew_movement.dart';
import 'package:base67/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameDataRepository repository;
  setUpAll(() async {
    repository = await GameDataRepository.load();
  });

  void viewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<CampaignController> game(
    WidgetTester tester,
    CrewMovement movement, {
    double scale = 1,
  }) async {
    final c = CampaignController(
      repository: repository,
      store: CampaignSaveStore(_Memory()),
      initial: CampaignMigration(repository).migrate(
        const CampaignSave(
          prologueComplete: true,
          selectedSiteId: 'gale',
          settings: {'reduceMotion': true},
          crewNames: {'Commander': 'Nova'},
          buildingLevels: {'crew_habitat': 1},
        ),
      ),
    );
    addTearDown(c.dispose);
    addTearDown(movement.dispose);
    await c.initialize();
    await tester.pumpWidget(
      MaterialApp(
        theme: Base67Theme.missionControl(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: ListenableBuilder(
          listenable: c,
          builder: (context, _) => SettlementGameScreen(
            controller: c,
            repository: repository,
            movement: movement,
            navigate: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    return c;
  }

  for (final size in [const Size(640, 360), const Size(960, 420)]) {
    testWidgets(
      'world fills $size with readable enlarged HUD and closable drawers',
      (tester) async {
        viewport(tester, size);
        final movement = CrewMovement();
        await game(tester, movement, scale: 1.4);
        expect(
          tester.getSize(find.byKey(const ValueKey('settlement-viewport'))),
          size,
        );
        expect(movement.selected, 'commander');
        expect(movement.manual, isTrue);
        final joystick = tester.getRect(
          find.byKey(const ValueKey('crew-joystick')),
        );
        expect(joystick.left, lessThan(size.width / 3));
        expect(joystick.bottom, lessThanOrEqualTo(size.height));
        expect(
          find.byKey(const ValueKey('mission-action')).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('world-interact')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Build'));
        await tester.pumpAndSettle();
        expect(find.text('Build'), findsWidgets);
        expect(movement.direction, Offset.zero);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('mission-action')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'joystick and mission action accept separate fingers; modals and cancel stop movement',
    (tester) async {
      viewport(tester, const Size(800, 400));
      final movement = CrewMovement();
      final c = await game(tester, movement);
      final actor = movement.actors['commander']!;
      final free =
          [
            for (double y = 100; y < 600; y += 40)
              for (double x = 100; x < 700; x += 40) Offset(x, y),
          ].firstWhere(
            (p) =>
                movement.segmentWalkable(p, p + const Offset(50, 0)) &&
                movement.actors.values.every(
                  (other) =>
                      other == actor || (p - other.position).distance > 80,
                ),
          );
      actor.position = free;
      final finger = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('crew-joystick'))),
        pointer: 1,
      );
      await finger.moveBy(const Offset(35, 0));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 34));
      }
      expect(actor.position.dx, greaterThan(free.dx));
      final actionFinger = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('mission-action'))),
        pointer: 2,
      );
      await actionFinger.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.mission?['phase'], 'briefing');
      expect(movement.direction.dx, greaterThan(0));
      await tester.tap(find.byTooltip('Build'), pointer: 3);
      await tester.pumpAndSettle();
      expect(movement.direction, Offset.zero);
      await finger.cancel();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(movement.direction, Offset.zero);
      final next = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('crew-joystick'))),
      );
      await next.moveBy(const Offset(25, 0));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(movement.direction, Offset.zero);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await next.cancel();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'landscape crew, site and cargo forms keep choices and keyboard usable',
    (tester) async {
      viewport(tester, const Size(640, 360));
      final mission = Mission(initial: const CampaignSave(), seed: 42);
      for (final screen in <Widget>[
        CrewScreen(mission: mission, onDone: () {}),
        SiteScreen(
          mission: mission,
          repository: repository,
          seed: 42,
          onDone: () {},
        ),
        CargoScreen(mission: mission, repository: repository, onDone: () {}),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: Base67Theme.light(),
            home: Scaffold(body: screen),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final fields = find.byType(TextField);
        if (fields.evaluate().isNotEmpty) {
          await tester.ensureVisible(fields.first);
          await tester.pumpAndSettle();
          expect(fields.first.hitTestable(), findsOneWidget);
          await tester.tap(fields.first);
          await tester.enterText(fields.first, 'Nova');
          tester.view.viewInsets = const FakeViewPadding(bottom: 150);
          await tester.pump();
          expect(tester.takeException(), isNull);
          tester.view.resetViewInsets();
          await tester.pump();
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
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
