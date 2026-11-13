import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'mars_base_painter.dart';
import 'theme.dart';

abstract final class MarsTerrain {
  static final Paint _slowHaze = Paint()
    ..color = GameColors.marsHaze.withValues(alpha: .055);
  static final Paint _slowHazeHighlight = Paint()
    ..color = GameColors.paper.withValues(alpha: .019);
  static final Paint _fastHaze = Paint()
    ..color = GameColors.marsHaze.withValues(alpha: .035);
  static final Paint _fastHazeHighlight = Paint()
    ..color = GameColors.paper.withValues(alpha: .012);
  static final Paint _stormTint = Paint()
    ..color = GameColors.sand.withValues(alpha: .17);
  static final Paint _stormStreak = Paint()
    ..color = GameColors.sand.withValues(alpha: .20)
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;

  static void paint(Canvas canvas, Size size, {required bool night}) {
    _paintSky(canvas, size, night: night);
    _paintRidges(canvas, size, seed: 0);
    canvas.save();
    canvas.clipPath(SettlementLayout.ground(size));
    _paintGround(canvas, size, night: night);
    final hulls = SettlementLayout.facilities(const {})
        .map((site) => SettlementLayout.hull(site, size).inflate(20))
        .toList();
    _paintRocks(canvas, size, hulls);
    _paintDunes(canvas, size);
    canvas.restore();
  }

  static void paintBackdrop(
    Canvas canvas,
    Size size, {
    required int seed,
  }) {
    _paintSky(canvas, size, night: false);
    _paintRidges(canvas, size, seed: seed + 17);
    final ground = Path()
      ..moveTo(0, size.height * .58)
      ..quadraticBezierTo(
        size.width * .48,
        size.height * .48,
        size.width,
        size.height * .57,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.save();
    canvas.clipPath(ground);
    _paintGround(canvas, size, night: false);
    _paintCrater(canvas, Offset(size.width * .76, size.height * .76), 1.0);
    _paintCrater(canvas, Offset(size.width * .24, size.height * .88), .62);
    canvas.restore();
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const RadialGradient(
          colors: [Colors.transparent, Color(0x44301518)],
          stops: [.56, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * .30, size.width, size.height * .42),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GameColors.marsHaze.withValues(alpha: .02),
            GameColors.marsHaze.withValues(alpha: .10),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );
  }

  static void _paintSky(Canvas canvas, Size size, {required bool night}) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night
              ? const [
                  GameColors.marsNight,
                  GameColors.marsRock,
                  GameColors.marsGround,
                ]
              : const [
                  GameColors.marsSkyHigh,
                  GameColors.marsSky,
                  GameColors.marsHaze,
                ],
          stops: const [0, .56, 1],
        ).createShader(rect),
    );
    if (night) {
      for (var i = 0; i < 38; i++) {
        final x = ((i * 193 + 41) % 997) / 997 * size.width;
        final y = ((i * 127 + 17) % 389) / 1000 * size.height;
        final radius = .6 + (i % 3) * .35;
        canvas.drawCircle(
          Offset(x, y),
          radius,
          Paint()..color = GameColors.paper.withValues(alpha: .42 + i % 4 * .1),
        );
      }
      canvas.drawRect(
        Rect.fromLTWH(0, size.height * .30, size.width, size.height * .13),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              GameColors.rust.withValues(alpha: .24),
              GameColors.marsHaze.withValues(alpha: .28),
            ],
          ).createShader(rect),
      );
      return;
    }

    final sun = Offset(size.width * .17, size.height * .14);
    final radius = size.shortestSide * .20;
    canvas.drawCircle(
      sun,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            GameColors.paper.withValues(alpha: .52),
            GameColors.gold.withValues(alpha: .14),
            Colors.transparent,
          ],
          stops: const [0, .25, 1],
        ).createShader(Rect.fromCircle(center: sun, radius: radius)),
    );
    canvas.drawCircle(
      sun,
      size.shortestSide * .027,
      Paint()..color = GameColors.paper.withValues(alpha: .76),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * .32, size.width, size.height * .12),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            GameColors.marsHaze.withValues(alpha: .34),
            GameColors.marsHaze.withValues(alpha: .06),
          ],
        ).createShader(rect),
    );
  }

  static void _paintRidges(Canvas canvas, Size size, {required int seed}) {
    for (var layer = 0; layer < 4; layer++) {
      final points = <Offset>[];
      for (var i = 0; i <= 8; i++) {
        final jitter = ((i * 37 + layer * 29 + seed * 11) % 13 - 6) * .0032;
        final x = i / 8;
        final y = .285 + layer * .037 + jitter;
        points.add(Offset(x * size.width, y * size.height));
      }
      final ridge = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        final previous = points[i - 1];
        final point = points[i];
        final middle = (previous.dx + point.dx) / 2;
        ridge.cubicTo(middle, previous.dy, middle, point.dy, point.dx, point.dy);
      }
      ridge
        ..lineTo(size.width, size.height)
        ..close();
      final depth = layer / 3;
      final base = Color.lerp(GameColors.marsDistant, GameColors.marsRock, depth)!
          .withValues(alpha: .64 + depth * .23);
      canvas.drawPath(ridge, Paint()..color = base);

      for (var i = 1; i < points.length - 1; i++) {
        final left = points[i - 1];
        final peak = points[i];
        final right = points[i + 1];
        final litFace = Path()
          ..moveTo(left.dx, left.dy)
          ..lineTo(peak.dx, peak.dy)
          ..lineTo(peak.dx, peak.dy + (right.dy - peak.dy) * .5)
          ..close();
        final shadeFace = Path()
          ..moveTo(peak.dx, peak.dy)
          ..lineTo(right.dx, right.dy)
          ..lineTo(peak.dx, peak.dy + (right.dy - peak.dy) * .5)
          ..close();
        canvas.drawPath(
          litFace,
          Paint()
            ..color = Color.lerp(base, GameColors.marsLit, .19)!.withValues(
              alpha: .56,
            ),
        );
        canvas.drawPath(
          shadeFace,
          Paint()
            ..color = Color.lerp(base, GameColors.marsRockShade, .3)!.withValues(
              alpha: .58,
            ),
        );
      }
    }
  }

  static void _paintGround(Canvas canvas, Size size, {required bool night}) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: night
              ? const [GameColors.marsRock, GameColors.marsRockShade]
              : const [
                  GameColors.marsLit,
                  GameColors.marsGround,
                  GameColors.marsRock,
                ],
        ).createShader(rect),
    );
    for (var i = 0; i < 8; i++) {
      final x = ((i * 157 + 47) % 997) / 997 * size.width;
      final y = size.height * (.48 + ((i * 83) % 47) / 100);
      final width = size.shortestSide * (.22 + (i % 3) * .08);
      final height = width * (.12 + (i % 2) * .05);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: width, height: height),
        Paint()
          ..color = (i.isEven ? GameColors.marsLit : GameColors.marsRockShade)
              .withValues(alpha: night ? .09 : .12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
    for (var i = 0; i < 4; i++) {
      final center = Offset(
        size.width * (.17 + (i * 23 % 71) / 100),
        size.height * (.53 + (i * 11 % 38) / 100),
      );
      _paintCrater(canvas, center, .64 + (i % 3) * .16);
    }
    final speckles = <Offset>[];
    for (var i = 0; i < 260; i++) {
      final x = ((i * 269 + 73) % 997) / 997 * size.width;
      final y = (.47 + ((i * 149 + 19) % 527) / 1000) * size.height;
      speckles.add(Offset(x, y));
    }
    canvas.drawPoints(
      ui.PointMode.points,
      speckles,
      Paint()
        ..color = GameColors.marsRockShade.withValues(alpha: night ? .22 : .25)
        ..strokeWidth = .8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          colors: [Colors.transparent, Color(0x403B211F)],
          stops: [.52, 1],
        ).createShader(rect),
    );
  }

  static void _paintCrater(Canvas canvas, Offset center, double scale) {
    final width = 24 * scale;
    final height = 8 * scale;
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(2 * scale, 2 * scale),
        width: width * 1.12,
        height: height * 1.4,
      ),
      Paint()
        ..color = GameColors.marsRockShade.withValues(alpha: .38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: width, height: height),
      Paint()..color = GameColors.marsRockShade.withValues(alpha: .48),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: center.translate(0, -.8 * scale),
        width: width * 1.08,
        height: height * 1.25,
      ),
      math.pi * 1.05,
      math.pi * .92,
      false,
      Paint()
        ..color = GameColors.marsLit.withValues(alpha: .62)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, 1.5 * scale),
        width: width * .77,
        height: height * .44,
      ),
      Paint()..color = GameColors.ink.withValues(alpha: .16),
    );
  }

  static void _paintRocks(Canvas canvas, Size size, List<Rect> hulls) {
    final scale = size.shortestSide / 360;
    for (var i = 0; i < 58; i++) {
      final x = ((i * 137 + 29) % 997) / 997 * size.width;
      final y = (.46 + ((i * 73 + 13) % 530) / 590 * .54) * size.height;
      final center = Offset(x, y);
      if (hulls.any((hull) => hull.contains(center))) continue;
      final perspective = .45 + (y / size.height) * 1.1;
      final radius = (1.3 + (i * 7 % 8) * .55) * scale * perspective;
      _drawRock(canvas, center, radius, i);
      if (i % 3 == 0) {
        final satellite = center.translate(radius * 1.25, radius * .18);
        if (!hulls.any((hull) => hull.contains(satellite))) {
          _drawRock(canvas, satellite, radius * .56, i + 71);
        }
      }
    }
  }

  static void _drawRock(Canvas canvas, Offset center, double radius, int seed) {
    final sides = 5 + seed % 3;
    final points = <Offset>[];
    for (var i = 0; i < sides; i++) {
      final angle = math.pi * 2 * i / sides - math.pi / 2;
      final variation = .68 + ((seed * 31 + i * 17) % 29) / 100;
      points.add(
        center.translate(
          math.cos(angle) * radius * variation,
          math.sin(angle) * radius * variation * .72,
        ),
      );
    }
    final shadow = Path()..addPolygon(
      points.map((point) => point.translate(radius * .3, radius * .36)).toList(),
      true,
    );
    canvas.drawPath(
      shadow,
      Paint()
        ..color = GameColors.ink.withValues(alpha: .26)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    final rock = Path()..addPolygon(points, true);
    canvas.drawPath(
      rock,
      Paint()..color = GameColors.marsRock,
    );
    final ridge = points.length ~/ 2;
    final lit = Path()
      ..moveTo(points.first.dx, points.first.dy)
      ..lineTo(points[ridge].dx, points[ridge].dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..close();
    canvas.drawPath(
      lit,
      Paint()..color = GameColors.marsLit.withValues(alpha: .62),
    );
    final shade = Path()
      ..moveTo(points[ridge].dx, points[ridge].dy)
      ..lineTo(points.last.dx, points.last.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(
      shade,
      Paint()..color = GameColors.marsRockShade.withValues(alpha: .52),
    );
  }

  static void _paintDunes(Canvas canvas, Size size) {
    for (var i = 0; i < 13; i++) {
      final y = size.height * (.48 + i * .039);
      final ripple = Path()
        ..moveTo(0, y)
        ..cubicTo(
          size.width * .24,
          y - 11 - i % 3 * 3,
          size.width * .63,
          y + 15 + i % 4 * 3,
          size.width,
          y - 7,
        );
      canvas.drawPath(
        ripple,
        Paint()
          ..color = GameColors.marsHaze.withValues(alpha: .10 + i % 3 * .025)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7 + i % 2 * .35,
      );
    }
  }

  static void atmosphere(
    Canvas canvas,
    Size size, {
    required double seconds,
    required bool reducedMotion,
    required bool storm,
  }) {
    final slow = reducedMotion ? 0.0 : seconds * 7;
    final fast = reducedMotion ? 0.0 : seconds * 15;
    for (var i = 0; i < 5; i++) {
      final y = size.height * (.43 + i * .082);
      final slowX = ((i * 263 + slow) % (size.width + 260)) - 130;
      final slowBand = Rect.fromLTWH(
        slowX,
        y + slow * .005,
        176,
        10 + i % 3 * 4,
      );
      canvas
        ..drawOval(slowBand, _slowHaze)
        ..drawOval(slowBand.deflate(3), _slowHazeHighlight);
      final fastX = ((i * 263 + fast) % (size.width + 260)) - 130;
      final fastBand = Rect.fromLTWH(
        fastX,
        y + fast * .005,
        118,
        10 + i % 3 * 4,
      );
      canvas
        ..drawOval(fastBand, _fastHaze)
        ..drawOval(fastBand.deflate(3), _fastHazeHighlight);
    }
    if (storm) {
      canvas.drawRect(Offset.zero & size, _stormTint);
      final phase = reducedMotion ? 0.0 : (seconds * 48) % 96;
      for (var i = 0; i < 20; i++) {
        final x = ((i * 83 + phase) % (size.width + 100)) - 50;
        final y = size.height * (.38 + i % 9 * .065);
        canvas.drawLine(
          Offset(x, y),
          Offset(x - 20 - i % 4 * 4, y + 5),
          _stormStreak,
        );
      }
    }
  }
}
