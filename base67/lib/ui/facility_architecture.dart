import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Original decorative architecture, clipped to the existing navigation hulls.
abstract final class FacilityArchitecture {
  static void paint(
    Canvas canvas,
    String id, {
    required Color shell,
    required Color trim,
    bool operational = true,
  }) {
    final half = switch (id) {
      'solar_array' => 42.0,
      'rover' => 33.0,
      'habitat' || 'crew_habitat' => 28.0,
      _ => 27.0,
    };
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(-half, -30, half, 25));
    if (!operational) {
      canvas.saveLayer(
        null,
        Paint()
          ..colorFilter = const ColorFilter.matrix([
            .2126,
            .7152,
            .0722,
            0,
            0,
            .2126,
            .7152,
            .0722,
            0,
            0,
            .2126,
            .7152,
            .0722,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
      );
    }
    final hull = Color.lerp(shell, Colors.white, .6)!;
    final shade = Color.lerp(shell, GameColors.machinery, .35)!;
    final edge = Paint()
      ..color = GameColors.ink.withValues(alpha: .8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    void line(
      Offset a,
      Offset b, [
      Color color = GameColors.machinery,
      double width = 1,
    ]) => canvas.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
    void box(Rect rect, Color color, [double radius = 1.5]) {
      final shape = RRect.fromRectAndRadius(rect, Radius.circular(radius));
      canvas.drawRRect(shape, Paint()..color = color);
      canvas.drawRRect(shape, edge);
      line(
        rect.topLeft.translate(2, 1),
        rect.topRight.translate(-2, 1),
        Colors.white.withValues(alpha: .55),
        .7,
      );
    }

    void oval(Rect rect, Color color) {
      canvas.drawOval(rect, Paint()..color = color);
      canvas.drawOval(rect, edge);
    }

    void polygon(List<Offset> points, Color color) {
      final shape = Path()..addPolygon(points, true);
      canvas.drawPath(shape, Paint()..color = color);
      canvas.drawPath(shape, edge);
    }

    void plate(double w, double h, {bool grating = false}) {
      polygon([
        Offset(-w / 2 + 5, -h / 2),
        Offset(w / 2 - 5, -h / 2),
        Offset(w / 2, -h / 2 + 5),
        Offset(w / 2, h / 2 - 4),
        Offset(w / 2 - 5, h / 2),
        Offset(-w / 2 + 5, h / 2),
        Offset(-w / 2, h / 2 - 4),
        Offset(-w / 2, -h / 2 + 5),
      ], GameColors.machinery);
      if (grating) {
        for (var x = -w / 2 + 5; x < w / 2 - 3; x += 3) {
          line(
            Offset(x, -h / 2 + 3),
            Offset(x, h / 2 - 3),
            GameColors.ink.withValues(alpha: .42),
            .6,
          );
        }
        for (var y = -h / 2 + 4; y < h / 2 - 3; y += 3) {
          line(
            Offset(-w / 2 + 3, y),
            Offset(w / 2 - 3, y),
            GameColors.machineryHighlight.withValues(alpha: .55),
            .6,
          );
        }
      }
    }

    void glow(Offset at, Color color, [double radius = 8]) {
      if (!operational) return;
      canvas.drawCircle(
        at,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: .28), Colors.transparent],
          ).createShader(Rect.fromCircle(center: at, radius: radius)),
      );
    }

    void screen(Rect rect) {
      glow(rect.center, GameColors.tealLight);
      box(rect, GameColors.solarGlass, 1);
      canvas.drawRect(
        rect.deflate(1),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [GameColors.solarCellLine, GameColors.solarGlass],
          ).createShader(rect),
      );
      line(
        rect.topLeft.translate(2, 2),
        rect.topRight.translate(-2, 2),
        GameColors.paper,
        .7,
      );
    }

    void hatch(Offset at) {
      box(Rect.fromCenter(center: at, width: 12, height: 17), shade, 4);
      box(
        Rect.fromCenter(center: at.translate(0, 1), width: 8, height: 13),
        GameColors.machineryHighlight,
        3,
      );
      line(at.translate(0, -3), at.translate(0, 6));
      line(at.translate(2, 1), at.translate(3, 1), GameColors.ink, 1.5);
    }

    void hazard(Offset at) {
      polygon([
        at.translate(0, -4),
        at.translate(4, 3),
        at.translate(-4, 3),
      ], GameColors.colorBlindSafeOrange);
      line(at.translate(0, -1), at.translate(0, 1), GameColors.ink, .9);
      canvas.drawCircle(
        at.translate(0, 2),
        .6,
        Paint()..color = GameColors.ink,
      );
    }

    void pod(double w, double h) {
      plate(w + 4, 43);
      final rect = Rect.fromLTWH(-w / 2, -h / 2, w, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()
          ..shader = LinearGradient(
            colors: [hull, shell, shade],
            stops: const [0, .5, 1],
          ).createShader(rect),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        edge,
      );
      oval(Rect.fromLTWH(-w / 2, -h / 2 - 7, w, 14), hull);
      canvas.drawArc(
        Rect.fromLTWH(-w / 2, -h / 2 - 7, w, 14),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      canvas.drawArc(
        Rect.fromLTWH(-w / 2, h / 2 - 8, w, 13),
        0,
        math.pi,
        false,
        edge,
      );
      for (final x in [-w * .33, w * .33]) {
        line(Offset(x, -h / 2 + 7), Offset(x, h / 2 - 4), shade, .8);
      }
      hatch(Offset(0, h / 2 - 6));
      hazard(Offset(-w * .32, 4));
      screen(Rect.fromLTWH(8, -5, 6, 4));
    }

    void vent(Rect rect) {
      box(rect, shade);
      for (var y = rect.top + 3; y < rect.bottom - 1; y += 2) {
        line(
          Offset(rect.left + 2, y),
          Offset(rect.right - 2, y),
          GameColors.ink,
          .8,
        );
      }
    }

    // Contact shadow and ambient occlusion share a top-left light source.
    canvas.drawOval(
      const Rect.fromLTWH(-22, 10, 48, 14),
      Paint()
        ..color = GameColors.ink.withValues(alpha: .30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawOval(
      const Rect.fromLTWH(-22, 13, 44, 8),
      Paint()..color = GameColors.ink.withValues(alpha: .32),
    );
    switch (id) {
      case 'habitat' || 'crew_habitat':
        pod(47, 31);
        box(
          const Rect.fromLTWH(-15, -22, 30, 5),
          GameColors.machineryHighlight,
          2,
        );
        for (var x = -12.0; x <= 12; x += 8) {
          screen(Rect.fromLTWH(x, -21, 6, 3));
        }
      case 'life_support_module':
        pod(34, 29);
        for (final x in [-22.0, 22.0]) {
          box(Rect.fromLTWH(x - 3, -13, 6, 28), hull, 3);
          oval(Rect.fromLTWH(x - 3, -15, 6, 4), shade);
          line(Offset(x, 14), Offset(x, 20), GameColors.machineryHighlight, 2);
        }
        line(
          const Offset(-22, 20),
          const Offset(22, 20),
          GameColors.machineryHighlight,
          2,
        );
      case 'food_storage':
        pod(40, 29);
        for (final x in [-22.0, 15.0]) {
          box(Rect.fromLTWH(x, 8, 8, 12), shade);
          line(Offset(x + 2, 10), Offset(x + 6, 18), GameColors.machinery, .8);
        }
      case 'radiation_shelter':
        pod(45, 25);
        for (final x in [-18.0, -11.0, 11.0, 18.0]) {
          line(Offset(x, -14), Offset(x, 10), GameColors.machineryHighlight, 3);
        }
        box(const Rect.fromLTWH(-12, -24, 24, 6), shade);
      case 'medical_area':
        pod(40, 29);
        line(const Offset(-3, -16), const Offset(3, -16), GameColors.teal, 2);
        line(const Offset(0, -19), const Offset(0, -13), GameColors.teal, 2);
      case 'solar_array':
        for (var row = 0; row < 2; row++) {
          final y = -26.0 + row * 25;
          line(
            Offset(-39, y + 21),
            Offset(38, y + 21),
            GameColors.machineryHighlight,
            1,
          );
          for (var col = 0; col < 4; col++) {
            final x = -38.0 + col * 19;
            line(
              Offset(x + 5, y + 16),
              Offset(x + 6, y + 22),
              GameColors.machinery,
              2,
            );
            final panel = Path()
              ..addPolygon([
                Offset(x + 3, y),
                Offset(x + 17, y - 2),
                Offset(x + 13, y + 16),
                Offset(x - 1, y + 18),
              ], true);
            canvas.drawPath(
              panel,
              Paint()
                ..shader = const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [GameColors.solarGlass, GameColors.ink],
                ).createShader(Rect.fromLTWH(x, y, 17, 18)),
            );
            for (var n = 1; n < 5; n++) {
              line(
                Offset(x + 3 - n * .7, y + n * 3),
                Offset(x + 16 - n * .7, y - 2 + n * 3),
                GameColors.solarCellLine.withValues(alpha: .6),
                .45,
              );
            }
            line(
              Offset(x + 9, y - 1),
              Offset(x + 5, y + 17),
              GameColors.solarCellLine,
              .45,
            );
            canvas.drawPath(
              panel,
              Paint()
                ..color = hull
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.3,
            );
          }
        }
      case 'battery_bank':
        plate(50, 42);
        for (var i = 0; i < 3; i++) {
          final x = -22.0 + i * 15;
          box(Rect.fromLTWH(x, -22, 13, 38), shade, 2);
          box(Rect.fromLTWH(x + 1, -25, 12, 6), hull);
          vent(Rect.fromLTWH(x + 2, -17, 9, 12));
          box(Rect.fromLTWH(x + 2, -1, 9, 12), shell);
          line(Offset(x + 4, 13), Offset(x + 4, 15), trim, 2);
          canvas.drawCircle(
            Offset(x + 9, 13),
            1.4,
            Paint()
              ..color = operational
                  ? GameColors.tealLight
                  : GameColors.machinery,
          );
        }
      case 'greenhouse':
        plate(51, 41);
        final dome = Path()
          ..moveTo(-24, 10)
          ..cubicTo(-27, -34, 27, -34, 24, 10)
          ..quadraticBezierTo(0, 23, -24, 10)
          ..close();
        canvas.drawPath(
          dome,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [GameColors.solarCellLine, GameColors.solarGlass],
            ).createShader(const Rect.fromLTWH(-25, -25, 50, 43)),
        );
        canvas.save();
        canvas.clipPath(dome);
        for (var row = 0; row < 3; row++) {
          for (var col = 0; col < 4; col++) {
            final at = Offset(-16.0 + col * 10, -5.0 + row * 7);
            box(
              Rect.fromCenter(center: at, width: 8, height: 4),
              GameColors.marsRockShade,
              1,
            );
            canvas.drawOval(
              Rect.fromCenter(
                center: at.translate(-1, -2),
                width: 5,
                height: 3,
              ),
              Paint()..color = GameColors.tealLight,
            );
            line(
              at.translate(-1, -2),
              at.translate(2, -4),
              GameColors.teal,
              1.5,
            );
          }
        }
        canvas.drawPath(
          dome,
          Paint()..color = GameColors.tealLight.withValues(alpha: .13),
        );
        for (final x in [-16.0, 0.0, 16.0]) {
          final rib = Path()
            ..moveTo(x * .2, -23)
            ..quadraticBezierTo(x * 1.3, -8, x, 15);
          canvas.drawPath(
            rib,
            edge
              ..color = hull
              ..strokeWidth = 1.4,
          );
        }
        line(const Offset(-24, 1), const Offset(24, 1), hull, 1.5);
        line(const Offset(-18, -14), const Offset(18, -14), hull, 1.5);
        line(
          const Offset(-16, -17),
          const Offset(-9, -20),
          Colors.white.withValues(alpha: .8),
          2,
        );
        canvas.restore();
        edge
          ..color = GameColors.ink.withValues(alpha: .8)
          ..strokeWidth = 1;
        canvas.drawPath(dome, edge);
        hatch(const Offset(0, 16));
      case 'ice_miner_water_storage':
        plate(50, 43, grating: true);
        for (var row = 0; row < 2; row++) {
          for (var i = 0; i < 3; i++) {
            final x = -22.0 + i * 10, y = -19.0 + row * 21;
            box(Rect.fromLTWH(x, y, 8, 17), GameColors.colorBlindSafeBlue, 3);
            oval(Rect.fromLTWH(x, y - 2, 8, 5), GameColors.solarCellLine);
            line(
              Offset(x + 1, y + 10),
              Offset(x + 7, y + 10),
              GameColors.machineryHighlight,
              .8,
            );
          }
        }
        box(const Rect.fromLTWH(10, -17, 14, 34), GameColors.teal, 5);
        oval(const Rect.fromLTWH(10, -20, 14, 7), GameColors.tealLight);
        line(
          const Offset(14, -11),
          const Offset(14, 11),
          GameColors.tealLight,
          2,
        );
        line(
          const Offset(-19, 21),
          const Offset(19, 21),
          GameColors.machineryHighlight,
          2,
        );
        line(
          const Offset(19, 21),
          const Offset(19, 13),
          GameColors.machineryHighlight,
          2,
        );
      case 'maintenance_bay':
        plate(51, 44, grating: true);
        for (final x in [-22.0, 22.0]) {
          box(Rect.fromLTWH(x - 2, -26, 4, 45), shade, 0);
          for (var j = 0; j < 4; j++) {
            final y = -22.0 + j * 10;
            line(
              Offset(x - 2, y),
              Offset(x + 2, y + 7),
              GameColors.machineryHighlight,
              .8,
            );
          }
        }
        box(const Rect.fromLTWH(-25, -28, 50, 7), GameColors.gold, 0);
        canvas.save();
        canvas.clipRect(const Rect.fromLTWH(-24, -27, 48, 5));
        for (var x = -28.0; x < 28; x += 9) {
          line(Offset(x, -28), Offset(x + 7, -20), GameColors.ink, 4);
        }
        canvas.restore();
        line(
          const Offset(-17, -19),
          const Offset(17, 16),
          GameColors.machineryHighlight,
        );
        line(
          const Offset(17, -19),
          const Offset(-17, 16),
          GameColors.machineryHighlight,
        );
        line(const Offset(7, -20), const Offset(7, -5), GameColors.ink, 1.5);
        canvas.drawArc(
          const Rect.fromLTWH(4, -7, 6, 8),
          0,
          math.pi,
          false,
          edge,
        );
        box(const Rect.fromLTWH(-17, 8, 13, 12), shell);
        vent(const Rect.fromLTWH(5, 6, 12, 14));
      case 'research_lab':
        plate(50, 43);
        for (var row = 0; row < 2; row++) {
          for (var col = 0; col < 2; col++) {
            final rect = Rect.fromLTWH(
              -23.0 + col * 25,
              -25.0 + row * 23,
              21,
              21,
            );
            box(rect, shade);
            box(Rect.fromLTWH(rect.left + 1, rect.top + 1, 19, 4), hull);
            final center = rect.center.translate(0, 2);
            oval(
              Rect.fromCircle(center: center, radius: 7),
              GameColors.machinery,
            );
            for (var blade = 0; blade < 4; blade++) {
              final angle = blade * math.pi / 2 + .4;
              line(
                center,
                center.translate(math.cos(angle) * 5, math.sin(angle) * 5),
                hull,
                2,
              );
            }
            canvas.drawCircle(center, 1.5, Paint()..color = GameColors.ink);
          }
        }
      case 'communications' || 'mission_control_hub':
        oval(const Rect.fromLTWH(-20, 7, 40, 16), shade);
        for (var i = 0; i < 9; i++) {
          final x = -17.0 + i * 4;
          line(
            Offset(x, 13),
            Offset(x * .7, 21),
            GameColors.machineryHighlight,
            1,
          );
        }
        line(const Offset(-13, 17), const Offset(-8, -12), hull, 3);
        line(const Offset(13, 17), const Offset(4, -10), hull, 3);
        final dish = const Rect.fromLTWH(-24, -28, 46, 37);
        canvas.drawOval(
          dish,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, hull, shade],
            ).createShader(dish),
        );
        canvas.drawOval(dish, edge);
        canvas.drawOval(
          dish.deflate(3),
          Paint()
            ..color = GameColors.machineryHighlight.withValues(alpha: .5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .7,
        );
        for (var n = 0; n < 4; n++) {
          final angle = n * math.pi / 2 + .4;
          line(
            const Offset(-1, -9),
            Offset(-1 + math.cos(angle) * 20, -9 + math.sin(angle) * 15),
            shade,
            .7,
          );
        }
        line(
          const Offset(8, 7),
          const Offset(-3, -15),
          GameColors.machinery,
          2,
        );
        oval(const Rect.fromLTWH(-6, -18, 6, 5), shell);
      case 'power_control_station':
        plate(51, 44, grating: true);
        polygon(const [
          Offset(-16, -6),
          Offset(-8, -17),
          Offset(9, -17),
          Offset(18, -5),
          Offset(12, 9),
          Offset(-12, 9),
        ], shade);
        oval(const Rect.fromLTWH(-17, -12, 34, 20), hull);
        for (final x in [-13.0, 6.0]) {
          screen(Rect.fromLTWH(x, -13, 8, 9));
        }
        box(const Rect.fromLTWH(-5, -21, 10, 11), shade);
        screen(const Rect.fromLTWH(-4, -19, 8, 6));
        for (final at in const [Offset(-22, 0), Offset(22, 0), Offset(0, 17)]) {
          box(
            Rect.fromCenter(center: at, width: 8, height: 7),
            GameColors.colorBlindSafeOrange,
            1,
          );
          line(at.translate(-2, -2), at.translate(2, -2), GameColors.sand, .7);
        }
      case 'landing_craft':
        polygon(const [
          Offset(-25, 11),
          Offset(-16, -18),
          Offset(15, -18),
          Offset(26, 10),
          Offset(13, 23),
          Offset(-14, 23),
        ], GameColors.machinery);
        for (final x in [-1.0, 1.0]) {
          line(Offset(x * 9, 3), Offset(x * 22, 18), hull, 3);
          box(Rect.fromLTWH(x * 21 - 4, 17, 8, 4), GameColors.ink, 1);
        }
        box(const Rect.fromLTWH(-12, -26, 24, 35), hull, 9);
        screen(const Rect.fromLTWH(-9, -18, 18, 9));
        hatch(const Offset(0, 7));
        hazard(const Offset(-7, -3));
      case 'rover':
        for (final x in [-26.0, 26.0]) {
          for (final y in [-8.0, 4.0, 17.0]) {
            box(
              Rect.fromCenter(center: Offset(x, y), width: 9, height: 10),
              GameColors.ink,
              3,
            );
            line(
              Offset(x - 3, y - 2),
              Offset(x + 3, y - 2),
              GameColors.machinery,
              1.5,
            );
          }
        }
        box(const Rect.fromLTWH(-23, -15, 46, 31), shade, 4);
        box(
          const Rect.fromLTWH(-21, -17, 42, 23),
          GameColors.colorBlindSafeOrange,
          3,
        );
        screen(const Rect.fromLTWH(-16, -14, 32, 10));
        for (var x = -10.0; x <= 10; x += 5) {
          line(Offset(x, -13), Offset(x, -5), GameColors.paper, .6);
        }
        box(const Rect.fromLTWH(-14, 8, 28, 7), hull);
        for (final x in [-17.0, 17.0]) {
          glow(Offset(x, 16), GameColors.workLight, 5);
        }
        line(
          const Offset(18, -13),
          const Offset(21, -27),
          GameColors.machinery,
        );
        canvas.drawCircle(const Offset(21, -27), 1.5, Paint()..color = trim);
      default:
        pod(40, 29);
    }
    if (!operational) canvas.restore();
    canvas.restore();
  }
}
