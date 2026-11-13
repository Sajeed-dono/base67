import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Original code-drawn colony architecture. Local hulls match the shared
/// navigation footprint; no decorative object creates gameplay capacity.
abstract final class FacilityArchitecture {
  static void paint(
    Canvas canvas,
    String id, {
    required Color shell,
    required Color trim,
    bool operational = true,
  }) {
    final edge = Paint()
      ..color = GameColors.machinery
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    void line(Offset a, Offset b, [Color? color, double width = 2]) =>
        canvas.drawLine(
          a,
          b,
          Paint()
            ..color = color ?? trim
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round,
        );
    void box(Rect rect, Color color, [double radius = 3]) {
      final shape = RRect.fromRectAndRadius(rect, Radius.circular(radius));
      canvas.drawRRect(shape, Paint()..color = color);
      canvas.drawRRect(shape, edge);
    }

    void circle(Offset center, double radius, Color color) {
      canvas.drawCircle(center, radius, Paint()..color = color);
      canvas.drawCircle(center, radius, edge);
    }

    void module(double width, double height) {
      // Elevated deck and lit roof share the same north-west sun direction.
      box(
        Rect.fromLTWH(-width / 2 - 1, height / 2 - 3, width + 3, 6),
        GameColors.machinery,
        1,
      );
      final bodyRect = Rect.fromLTWH(-width / 2, -height / 2, width, height);
      final body = RRect.fromRectAndRadius(bodyRect, const Radius.circular(5));
      canvas.drawRRect(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(shell, Colors.white, .24)!,
              shell,
              Color.lerp(shell, GameColors.ink, .20)!,
            ],
          ).createShader(bodyRect),
      );
      canvas.drawRRect(body, edge);
      final roof = Path()
        ..moveTo(-width / 2, -height / 2)
        ..lineTo(-width / 2 + 7, -height / 2 - 9)
        ..lineTo(width / 2 + 2, -height / 2 - 9)
        ..lineTo(width / 2, -height / 2)
        ..close();
      canvas.drawPath(roof, Paint()..color = GameColors.paper);
      canvas.drawPath(roof, edge);
      final side = Path()
        ..moveTo(width / 2, -height / 2)
        ..lineTo(width / 2 + 2, -height / 2 - 9)
        ..lineTo(width / 2 + 2, height / 2 - 4)
        ..lineTo(width / 2, height / 2)
        ..close();
      canvas.drawPath(side, Paint()..color = GameColors.moduleShade);
      canvas.drawPath(side, edge);
      line(
        Offset(-width / 2 + 4, height / 2 - 4),
        Offset(width / 2 - 4, height / 2 - 4),
      );
      box(
        Rect.fromLTWH(-width / 2 + 4, -height / 2 - 5, width * .35, 3),
        GameColors.machinery,
        1,
      );
      for (var slot = 0; slot < 3; slot++) {
        line(
          Offset(width / 2 - 9, -height / 2 - 5 + slot * 1.8),
          Offset(width / 2 - 2, -height / 2 - 5 + slot * 1.8),
          GameColors.machinery,
          .8,
        );
      }
      line(
        Offset(-width / 2 + 1, -height / 2 + 4),
        Offset(width / 2 - 1, -height / 2 + 4),
        trim,
        3,
      );
    }

    void airlock(Offset at) {
      box(
        Rect.fromCenter(center: at, width: 13, height: 12),
        GameColors.outline,
      );
      box(
        Rect.fromCenter(center: at, width: 7, height: 10),
        GameColors.marsNight,
        2,
      );
      line(
        at.translate(0, -4),
        at.translate(0, 4),
        GameColors.machineryHighlight,
        .7,
      );
      line(at.translate(-7, 7), at.translate(7, 7), GameColors.sand, 3);
      for (var step = 0; step < 3; step++) {
        line(
          at.translate(-5 + step * 4, 6),
          at.translate(-3 + step * 4, 8),
          GameColors.machinery,
          1,
        );
      }
    }

    void windows(int count) {
      for (var i = 0; i < count; i++) {
        final rect = Rect.fromLTWH(-18 + i * 12, -6, 9, 8);
        if (operational) {
          final center = rect.center;
          canvas.drawCircle(
            center,
            9,
            Paint()
              ..shader = RadialGradient(
                colors: [
                  GameColors.gold.withValues(alpha: .42),
                  GameColors.gold.withValues(alpha: .04),
                  Colors.transparent,
                ],
              ).createShader(Rect.fromCircle(center: center, radius: 9)),
          );
        }
        box(
          rect,
          operational ? const Color(0xFFFFD88B) : GameColors.machinery,
          2,
        );
        line(
          Offset(-17 + i * 12, -5),
          Offset(-13 + i * 12, -3),
          GameColors.solarCellLine,
          .8,
        );
      }
    }

    switch (id) {
      case 'habitat':
        module(49, 26);
        windows(3);
        airlock(const Offset(0, 18));
        for (final x in [-19.0, 18.0]) {
          line(Offset(x, -22), Offset(x, 11), GameColors.muted, 2);
        }
        box(
          const Rect.fromLTWH(-13, -23, 22, 5),
          GameColors.colorBlindSafeBlue,
          1,
        );
      case 'research_lab':
        module(44, 25);
        windows(2);
        airlock(const Offset(18, 15));
        circle(const Offset(-12, -20), 7, trim);
        line(const Offset(-12, -20), const Offset(-5, -28), GameColors.ink);
        box(const Rect.fromLTWH(-26, 3, 10, 16), GameColors.outline);
        for (var i = 0; i < 3; i++) {
          line(Offset(-24, 7.0 + i * 4), Offset(-18, 7.0 + i * 4));
        }
      case 'maintenance_bay':
        final roof = Path()
          ..moveTo(-25, -6)
          ..lineTo(0, -24)
          ..lineTo(25, -6)
          ..lineTo(25, 18)
          ..lineTo(-25, 18)
          ..close();
        canvas.drawPath(roof, Paint()..color = shell);
        canvas.drawPath(roof, edge);
        box(const Rect.fromLTWH(-18, -3, 36, 22), GameColors.ink, 2);
        for (var i = 0; i < 3; i++) {
          line(
            Offset(-15, 2.0 + i * 4),
            Offset(15, 2.0 + i * 4),
            GameColors.muted,
            1,
          );
        }
        line(const Offset(-24, 17), const Offset(-24, -23), trim, 3);
        line(const Offset(-24, -23), const Offset(-5, -23), trim, 3);
        line(const Offset(-7, -23), const Offset(-7, -12), GameColors.gold);
        circle(const Offset(-7, -10), 2, GameColors.gold);
      case 'greenhouse':
        box(const Rect.fromLTWH(-25, 3, 50, 14), shell, 5);
        final dome = Path()
          ..moveTo(-25, 5)
          ..cubicTo(-26, -32, 26, -32, 25, 5)
          ..close();
        canvas.drawPath(
          dome,
          Paint()..color = GameColors.tealLight.withValues(alpha: .85),
        );
        canvas.drawPath(dome, edge);
        for (final x in [-16.0, 0.0, 16.0]) {
          line(Offset(x, -15), Offset(x, 5), trim, 1.5);
          circle(Offset(x, 2), 3, GameColors.teal);
        }
        line(const Offset(-21, -7), const Offset(21, -7), trim, 1);
        airlock(const Offset(0, 17));
      case 'solar_array':
        for (var i = -1; i <= 1; i++) {
          final x = i * 27.0;
          line(Offset(x, 5), Offset(x + 3, 17), GameColors.outline, 3);
          final panel = Path()
            ..moveTo(x - 12, -17)
            ..lineTo(x + 12, -17)
            ..lineTo(x + 10, 6)
            ..lineTo(x - 14, 6)
            ..close();
          canvas.drawPath(
            panel,
            Paint()
              ..shader = const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [GameColors.solarGlass, GameColors.marsNight],
              ).createShader(Rect.fromLTWH(x - 14, -17, 26, 23)),
          );
          canvas.drawPath(panel, edge);
          for (var grid = 1; grid < 4; grid++) {
            line(
              Offset(x - 12 + grid * 6, -16),
              Offset(x - 14 + grid * 6, 5),
              GameColors.solarCellLine,
              .6,
            );
          }
          line(
            Offset(x - 13, -6),
            Offset(x + 11, -6),
            GameColors.solarCellLine,
            .6,
          );
        }
      case 'battery_bank':
        box(const Rect.fromLTWH(-25, 14, 50, 6), GameColors.outline, 1);
        for (var i = -1; i <= 1; i++) {
          final x = i * 15.0;
          box(Rect.fromLTWH(x - 6, -19, 12, 33), shell, 3);
          box(Rect.fromLTWH(x - 3, -23, 6, 4), GameColors.machinery, 1);
          line(Offset(x - 5, -15), Offset(x + 5, -15), trim, 3);
          for (var slot = 0; slot < 3; slot++) {
            line(
              Offset(x - 3, -11.0 + slot * 7),
              Offset(x + 3, -11.0 + slot * 7),
              operational ? GameColors.information : GameColors.machinery,
            );
          }
        }
      case 'ice_miner_water_storage':
        box(const Rect.fromLTWH(-24, -13, 17, 31), shell, 7);
        box(const Rect.fromLTWH(-3, -9, 17, 27), GameColors.tealLight, 7);
        line(const Offset(-16, 18), const Offset(18, 18), trim, 3);
        line(const Offset(20, 15), const Offset(20, -26), trim, 4);
        line(const Offset(20, -26), const Offset(7, -26), trim, 4);
        line(const Offset(8, -26), const Offset(8, -13), GameColors.ink);
        circle(const Offset(-15, -3), 4, GameColors.colorBlindSafeBlue);
        line(const Offset(-16, -19), const Offset(-16, -13));
      case 'life_support_module':
        for (var i = -1; i <= 1; i++) {
          final x = i * 16.0;
          box(Rect.fromLTWH(x - 6, -22, 12, 36), shell, 6);
          line(Offset(x - 5, -13), Offset(x + 5, -13), trim, 3);
          line(Offset(x, 14), Offset(x, 21), GameColors.outline, 3);
        }
        line(const Offset(-23, 21), const Offset(23, 21), trim, 3);
        box(const Rect.fromLTWH(-6, -5, 12, 8), GameColors.tealLight, 2);
      case 'rover':
        module(50, 22);
        box(const Rect.fromLTWH(-19, -6, 38, 18), GameColors.ink, 1);
        box(const Rect.fromLTWH(-19, 1, 31, 13), shell, 3);
        box(const Rect.fromLTWH(-12, -6, 15, 10), GameColors.tealLight, 3);
        circle(const Offset(-13, 16), 5, GameColors.ink);
        circle(const Offset(7, 16), 5, GameColors.ink);
        line(const Offset(3, -9), const Offset(10, -24), trim);
        circle(const Offset(10, -24), 3, trim);
      case 'communications':
        box(const Rect.fromLTWH(-20, 4, 40, 17), shell);
        line(const Offset(0, 3), const Offset(0, -19), trim, 4);
        canvas.drawArc(
          const Rect.fromLTWH(-23, -30, 44, 30),
          .1,
          math.pi,
          true,
          Paint()..color = GameColors.paper,
        );
        canvas.drawArc(
          const Rect.fromLTWH(-23, -30, 44, 30),
          .1,
          math.pi,
          false,
          edge,
        );
        line(const Offset(0, -14), const Offset(15, -29), GameColors.ink);
        circle(const Offset(15, -29), 2, GameColors.gold);
        windows(2);
      case 'radiation_shelter':
        final berm = Path()
          ..moveTo(-27, 18)
          ..lineTo(-21, -8)
          ..lineTo(-10, -21)
          ..lineTo(19, -17)
          ..lineTo(27, 18)
          ..close();
        canvas.drawPath(berm, Paint()..color = GameColors.muted);
        canvas.drawPath(berm, edge);
        for (var i = 0; i < 3; i++) {
          line(
            Offset(-16, -10.0 + i * 5),
            Offset(16, -8.0 + i * 5),
            GameColors.outline,
            2,
          );
        }
        airlock(const Offset(0, 14));
        line(const Offset(-4, -14), const Offset(0, -8), GameColors.sand);
        line(const Offset(0, -8), const Offset(7, -16), GameColors.sand);
      case 'medical_area':
        module(44, 24);
        airlock(const Offset(-16, 16));
        box(const Rect.fromLTWH(8, -25, 14, 10), GameColors.paper);
        line(const Offset(15, -23), const Offset(15, -17), trim, 3);
        line(const Offset(12, -20), const Offset(18, -20), trim, 3);
        windows(2);
        box(const Rect.fromLTWH(17, 2, 9, 17), GameColors.outline, 4);
      case 'power_control_station':
        module(38, 22);
        box(const Rect.fromLTWH(-13, -8, 25, 12), GameColors.ink, 1);
        line(const Offset(-10, -1), const Offset(-5, -5), GameColors.tealLight);
        line(const Offset(-5, -5), const Offset(1, 1), GameColors.tealLight);
        line(const Offset(1, 1), const Offset(9, -6), GameColors.gold);
        for (final x in [-17.0, 17.0]) {
          line(Offset(x, 13), Offset(x, 22), trim, 3);
        }
        circle(const Offset(15, -19), 3, GameColors.gold);
      case 'food_storage':
        module(48, 24);
        for (var i = -1; i <= 1; i++) {
          box(Rect.fromLTWH(i * 14.0 - 5, -5, 11, 19), shell, 1);
          line(Offset(i * 14.0 - 4, -3), Offset(i * 14.0 + 5, 12), trim, 1);
        }
      case 'landing_craft':
        box(const Rect.fromLTWH(-14, -25, 28, 35), shell, 12);
        box(const Rect.fromLTWH(-9, -19, 18, 10), GameColors.tealLight, 5);
        for (final x in [-1.0, 1.0]) {
          line(Offset(x * 11, 5), Offset(x * 23, 20), GameColors.outline, 3);
          line(Offset(x * 18, 21), Offset(x * 27, 21), GameColors.ink, 3);
        }
        line(const Offset(0, -25), const Offset(0, -30), trim);
      default:
        module(44, 24);
        airlock(const Offset(0, 17));
    }
  }
}
