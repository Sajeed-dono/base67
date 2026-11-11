import 'dart:convert';
import 'dart:ui' as ui;

import 'package:base67/ui/crew_bean.dart';
import 'package:base67/ui/crew_movement.dart';
import 'package:base67/ui/mars_base_painter.dart';
import 'package:base67/ui/settlement_camera.dart';
import 'package:base67/ui/settlement_map.dart';
import 'package:base67/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'cached building art refreshes after canonical facility changes',
    (tester) async {
      var count = 0;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          theme: Base67Theme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return SettlementMap(
                    facilities: [
                      MarsFacility(
                        'solar_array',
                        'Solar',
                        const Offset(.23, .75),
                        installedUnits: count,
                      ),
                    ],
                    crew: const [],
                    reducedMotion: true,
                  );
                },
              ),
            ),
          ),
        ),
      );
      final viewport = find.byKey(const ValueKey('settlement-viewport'));
      Future<String?> capture() async {
        final painter = tester
            .widget<CustomPaint>(
              find.descendant(of: viewport, matching: find.byType(CustomPaint)),
            )
            .painter!;
        final size = tester.getSize(viewport);
        final recorder = ui.PictureRecorder();
        painter.paint(Canvas(recorder), size);
        final picture = recorder.endRecording();
        return tester.runAsync(() async {
          final image = await picture.toImage(
            size.width.toInt(),
            size.height.toInt(),
          );
          try {
            final bytes = await image.toByteData();
            return base64Encode(bytes!.buffer.asUint8List());
          } finally {
            image.dispose();
            picture.dispose();
          }
        });
      }

      final unbuilt = await capture();
      update(() => count = 1);
      await tester.pump();
      expect(await capture(), isNot(unbuilt));
      update(() => count = 0);
      await tester.pump();
      expect(await capture(), unbuilt);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final width in [360.0, 800.0, 1024.0]) {
    testWidgets(
      'selected crew inspection preserves real assignment at $width dp',
      (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final movement = CrewMovement();
        String? route;
        await tester.pumpWidget(
          MaterialApp(
            theme: Base67Theme.light(),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1100),
                textScaler: const TextScaler.linear(1.4),
                disableAnimations: true,
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: SettlementMap(
                    facilities: SettlementLayout.facilities({
                      'crew_habitat': 1,
                    }),
                    movement: movement,
                    reducedMotion: true,
                    crew: const [
                      MapCrew(
                        CrewRole.engineer,
                        'Sam',
                        task: 'construction',
                        target: 'solar_array',
                        progress: .4,
                        remainingLabel: '30 real seconds at last check',
                      ),
                    ],
                    onManage: (value) => route = value,
                  ),
                ),
              ),
            ),
          ),
        );
        final select = find.byKey(const ValueKey('select-engineer'));
        await tester.ensureVisible(select);
        await tester.tap(select);
        await tester.pump();
        final position = movement.actors['engineer']!.position;
        final inspect = find.byKey(const ValueKey('inspect-selected-crew'));
        await tester.ensureVisible(inspect);
        expect(inspect.hitTestable(), findsOneWidget);
        await tester.tap(inspect);
        await tester.pumpAndSettle();
        expect(find.text('Sam'), findsOneWidget);
        expect(find.text('Current assignment: construction'), findsOneWidget);
        expect(find.text('30 real seconds at last check'), findsWidgets);
        final manage = find.widgetWithText(
          OutlinedButton,
          'Manage crew responsibilities',
        );
        await tester.ensureVisible(manage);
        expect(manage.hitTestable(), findsOneWidget);
        await tester.tap(manage);
        await tester.pumpAndSettle();
        expect(route, '/crew');
        expect(movement.actors['engineer']!.member.task, 'construction');
        expect(movement.actors['engineer']!.position, position);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        movement.dispose();
      },
    );
  }
  testWidgets('camera gestures are explicit and cannot trap page scrolling', (
    tester,
  ) async {
    final movement = CrewMovement();
    await tester.pumpWidget(
      MaterialApp(
        theme: Base67Theme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SettlementMap(
                  facilities: const [],
                  movement: movement,
                  reducedMotion: true,
                  crew: const [MapCrew(CrewRole.commander, 'Alex')],
                ),
                const SizedBox(height: 500, child: Text('Page end')),
              ],
            ),
          ),
        ),
      ),
    );
    final select = find.byKey(const ValueKey('select-commander'));
    await tester.ensureVisible(select);
    await tester.tap(select);
    await tester.pump();
    final original = movement.actors['commander']!.position;
    final viewport = find.byKey(const ValueKey('settlement-viewport'));
    await tester.ensureVisible(viewport);
    await tester.pump();
    final scroll = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    final before = scroll.pixels;
    await tester.drag(viewport, const Offset(0, -80));
    await tester.pump();
    expect(scroll.pixels, greaterThan(before));
    final look = find.byTooltip('Look around');
    await tester.ensureVisible(look);
    await tester.tap(look);
    await tester.pump();
    await tester.ensureVisible(viewport);
    await tester.pump();
    final cameraModeOffset = scroll.pixels;
    await tester.drag(viewport, const Offset(60, -30));
    await tester.pump();
    expect(scroll.pixels, cameraModeOffset);
    expect(movement.actors['commander']!.position, original);
    expect(find.byTooltip('Scroll page'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    movement.dispose();
  });

  for (final width in [360.0, 800.0]) {
    testWidgets(
      'world picking and inspection preserve assignment at $width dp',
      (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final movement = CrewMovement();
        final facilities = SettlementLayout.facilities({
          'crew_habitat': 1,
          'solar_array': 1,
        });
        String? requestedRoute;
        await tester.pumpWidget(
          MaterialApp(
            theme: Base67Theme.light(),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1100),
                textScaler: const TextScaler.linear(1.4),
                disableAnimations: true,
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: SettlementMap(
                    facilities: facilities,
                    movement: movement,
                    reducedMotion: true,
                    crew: const [
                      MapCrew(CrewRole.engineer, 'Sam', task: 'clean'),
                    ],
                    onManage: (route) => requestedRoute = route,
                  ),
                ),
              ),
            ),
          ),
        );
        // This fixture has no Commander (the default selection). Choose its
        // Engineer through the real control before requesting a physical visit.
        final engineer = find.byKey(const ValueKey('select-engineer'));
        await tester.ensureVisible(engineer);
        await tester.tap(engineer);
        await tester.pump();
        expect(movement.selected, 'engineer');
        expect(movement.manual, isTrue);
        final overview = find.byTooltip('Settlement overview');
        await tester.ensureVisible(overview);
        await tester.tap(overview);
        await tester.pump();
        final viewport = find.byKey(const ValueKey('settlement-viewport'));
        await tester.ensureVisible(viewport);
        await tester.pump();
        final rect = tester.getRect(viewport);
        final camera = SettlementCamera()
          ..layout(rect.size, Offset.zero)
          ..overview();
        final solar = facilities.firstWhere((f) => f.id == 'solar_array');
        final point = Offset(
          solar.position.dx * SettlementView.world.width,
          solar.position.dy * SettlementView.world.height,
        );
        await tester.tapAt(rect.topLeft + camera.worldToScreen(point));
        await tester.pumpAndSettle();
        expect(find.text('Approach facility'), findsOneWidget);
        expect(find.text('Build, upgrade or repair plans'), findsOneWidget);
        expect(movement.actors['engineer']!.member.task, 'clean');
        final approach = find.widgetWithText(FilledButton, 'Approach facility');
        // The enlarged-text inspection sheet scrolls independently of the map.
        await tester.ensureVisible(approach);
        expect(approach.hitTestable(), findsOneWidget);
        await tester.tap(approach);
        await tester.pumpAndSettle();
        expect(movement.visiting, isTrue);
        expect(movement.manual, isFalse);
        expect(movement.actors['engineer']!.member.task, 'clean');
        expect(
          requestedRoute,
          isNull,
          reason: 'Approaching cannot submit a gameplay command.',
        );
        expect(movement.size, SettlementView.world);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        movement.dispose();
      },
    );
  }

  testWidgets('unbuilt reference stations explain unavailable interactions', (
    tester,
  ) async {
    final movement = CrewMovement();
    await tester.pumpWidget(
      MaterialApp(
        theme: Base67Theme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SettlementMap(
              facilities: SettlementLayout.facilities({'crew_habitat': 1}),
              movement: movement,
              reducedMotion: true,
              crew: const [MapCrew(CrewRole.scientist, 'Jo', task: 'research')],
            ),
          ),
        ),
      ),
    );
    final list = find.text('Facilities and interactions');
    await tester.ensureVisible(list);
    await tester.tap(list);
    await tester.pumpAndSettle();
    final lab = find.widgetWithText(ListTile, 'Lab');
    await tester.ensureVisible(lab);
    await tester.tap(lab);
    await tester.pumpAndSettle();
    expect(find.text('Station site / no construction recipe'), findsWidgets);
    final approach = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Approach facility'),
    );
    expect(approach.onPressed, isNull);
    expect(movement.actors['scientist']!.member.task, 'research');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    movement.dispose();
  });
}
