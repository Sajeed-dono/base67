import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:base67/ui/crew_bean.dart';
import 'package:base67/ui/mars_base_painter.dart';
import 'package:base67/ui/mars_terrain.dart';
import 'package:base67/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<String> frame(
    void Function(Canvas, Size) paint, {
    Size size = const Size(360, 280),
    String? capture,
  }) async {
    final recorder = ui.PictureRecorder();
    paint(Canvas(recorder), size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    try {
      const output = String.fromEnvironment('BASE67_REVIEW_DIR');
      if (output.isNotEmpty && capture != null) {
        final directory = Directory(output)..createSync(recursive: true);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${directory.path}${Platform.pathSeparator}$capture.png')
            .writeAsBytes(png!.buffer.asUint8List());
      }
      final data = await image.toByteData();
      return base64Encode(data!.buffer.asUint8List());
    } finally {
      image.dispose();
      picture.dispose();
    }
  }

  test(
    'pixel astronauts have distinct default uniforms and retain motion',
    () async {
      expect(
        {for (final role in CrewRole.values) crewSuitColor(role, 0)}.length,
        4,
      );
      await frame(
        (canvas, _) {
          for (final role in CrewRole.values) {
            canvas.save();
            canvas.translate(role.index * 120.0 + 10, 8);
            CrewBeanPainter(
              role: role,
              mood: CrewMood.okay,
              suitColor: crewSuitColor(role, 0),
              visorTint: crewVisorColors.first,
              faceStyleIndex: 0,
              breath: 0,
            ).paint(canvas, const Size(100, 116));
            canvas.restore();
          }
        },
        size: const Size(480, 140),
        capture: 'crew-pixel-colours',
      );
      Future<String> astronaut(int choice, double phase) => frame(
        (canvas, size) => CrewBeanPainter(
          role: CrewRole.commander,
          mood: CrewMood.okay,
          suitColor: crewSuitColor(CrewRole.commander, choice),
          visorTint: crewVisorColors.first,
          faceStyleIndex: 0,
          breath: 0,
          walking: true,
          walkPhase: phase,
        ).paint(canvas, size),
        size: const Size(100, 116),
      );
      final still = await astronaut(0, 0);
      expect(await astronaut(0, 0), still);
      expect(await astronaut(1, 0), isNot(still));
      expect(await astronaut(0, .25), isNot(still));
    },
  );

  test(
    'whole colony composes distinct day and night in the stable world',
    () async {
      Future<String> colony(bool night) => frame(
        (canvas, size) => MarsBasePainter(
          facilities: SettlementLayout.facilities({
            'crew_habitat': 1,
            'solar_array': 8,
            'battery_bank': 6,
          }),
          sunset: night,
        ).paint(canvas, size),
        size: SettlementView.world,
        capture: night ? 'colony-night' : 'colony-day',
      );
      expect(await colony(false), isNot(await colony(true)));
    },
  );

  test(
    'terrain is deterministic and distinguishes daylight from night',
    () async {
      void day(Canvas c, Size s) => MarsTerrain.paint(c, s, night: false);
      final first = await frame(day);
      expect(await frame(day), first);
      expect(
        await frame((c, s) => MarsTerrain.paint(c, s, night: true)),
        isNot(first),
      );
    },
  );

  test(
    'reduced-motion atmosphere stays fixed while ordinary wisps move',
    () async {
      Future<String> dust(double time, bool reduced) => frame(
        (c, s) => MarsTerrain.atmosphere(
          c,
          s,
          seconds: time,
          reducedMotion: reduced,
          storm: false,
        ),
      );
      expect(await dust(0, true), await dust(20, true));
      expect(await dust(0, false), isNot(await dust(20, false)));
    },
  );

  for (final id in ['habitat', 'solar_array', 'battery_bank']) {
    test(
      '$id has distinct built, unbuilt, damaged, off and construction art',
      () async {
        Future<String> building({
          int count = 1,
          int damage = 0,
          String? status,
          double? progress,
        }) => frame(
          (c, s) => MarsBasePainter.paintFacility(
            c,
            s,
            MarsFacility(
              id,
              id,
              const Offset(.5, .5),
              installedUnits: count,
              damagedUnits: damage,
              operatingState: status,
              jobProgress: progress,
            ),
          ),
        );
        final built = await building();
        final unbuilt = await building(count: 0);
        expect(unbuilt, isNot(built));
        expect(await building(damage: 1), isNot(built));
        expect(await building(status: 'off'), isNot(built));
        expect(
          await building(count: 0, status: 'underConstruction', progress: .4),
          isNot(unbuilt),
        );
      },
    );
  }
}
