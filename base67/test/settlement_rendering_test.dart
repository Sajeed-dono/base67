import 'dart:ui' as ui;

import 'package:base67/ui/crew_bean.dart';
import 'package:base67/ui/crew_movement.dart';
import 'package:base67/ui/mars_base_painter.dart';
import 'package:base67/ui/settlement_map.dart';
import 'package:base67/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('idle animation keeps the crew HUD stable', (tester) async {
    final movement = CrewMovement();
    await tester.pumpWidget(
      MaterialApp(
        theme: Base67Theme.missionControl(),
        home: Scaffold(
          body: SettlementMap(
            fullScreen: true,
            movement: movement,
            facilities: SettlementLayout.facilities({
              'crew_habitat': 1,
              'solar_array': 1,
              'battery_bank': 1,
              'greenhouse': 1,
              'power_control_station': 1,
              'life_support_module': 1,
              'radiation_shelter': 1,
              'ice_miner_water_storage': 1,
              'food_storage': 1,
              'maintenance_bay': 1,
              'mission_control_hub': 1,
            }),
            crew: const [
              MapCrew(CrewRole.commander, 'Alex'),
              MapCrew(CrewRole.engineer, 'Sam'),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final avatar = find.descendant(
      of: find.byKey(const ValueKey('crew-chip')),
      matching: find.byType(CrewBean),
    );
    final before = tester.widget<CrewBean>(avatar);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 34));
    }
    final after = tester.widget<CrewBean>(avatar);
    final viewport = find.byKey(const ValueKey('settlement-viewport'));
    final paint = tester
        .widget<CustomPaint>(
          find.descendant(of: viewport, matching: find.byType(CustomPaint)),
        )
        .painter!;
    final size = tester.getSize(viewport);
    await tester.runAsync(() async {
      final times = <int>[];
      for (var i = 0; i < 12; i++) {
        final clock = Stopwatch()..start();
        final recorder = ui.PictureRecorder();
        paint.paint(Canvas(recorder), size);
        final picture = recorder.endRecording();
        final image = await picture.toImage(
          size.width.toInt(),
          size.height.toInt(),
        );
        await image.toByteData();
        times.add(clock.elapsedMicroseconds);
        image.dispose();
        picture.dispose();
      }
      times.sort();
      debugPrint(
        'Local scene raster + readback median: ${times[6] / 1000} ms (12 samples; not device FPS).',
      );
    });
    expect(movement.animationSeconds, greaterThan(0));
    await tester.pumpWidget(const SizedBox.shrink());
    movement.dispose();
    expect(
      identical(before, after),
      isTrue,
      reason:
          'Idle animation must repaint actors without rebuilding the crew HUD.',
    );
  });
}
