import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

class MarsFacility {
  const MarsFacility(
    this.id,
    this.label,
    this.position, {
    this.level = 0,
    this.available = false,
  });
  final String id;
  final String label;
  final Offset position;
  final int level;
  final bool available;
}

class MarsBasePainter extends CustomPainter {
  const MarsBasePainter({required this.facilities, this.sunset = false});

  final List<MarsFacility> facilities;
  final bool sunset;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: sunset
            ? const [Color(0xFF5B4155), Color(0xFFCF8058), Color(0xFFEDB66B)]
            : const [Color(0xFF283F58), Color(0xFF9D634F), Color(0xFFD98B62)],
      ).createShader(rect);
    canvas.drawRect(rect, sky);
    final ground = Path()
      ..moveTo(0, size.height * 0.45)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.31,
        size.width * 0.30,
        size.height * 0.49,
        size.width * 0.48,
        size.height * 0.38,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.27,
        size.width * 0.83,
        size.height * 0.46,
        size.width,
        size.height * 0.34,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(ground, Paint()..color = const Color(0xFFB9694D));
    canvas.drawOval(
      Rect.fromLTWH(
        -size.width * .12,
        size.height * .68,
        size.width * 1.25,
        size.height * .40,
      ),
      Paint()..color = const Color(0xFFD58A61).withValues(alpha: .60),
    );
    _drawDistantHills(canvas, size);
    _drawPath(canvas, size);
    for (final facility in facilities) {
      _drawFacility(canvas, size, facility);
    }
    _drawLights(canvas, size);
  }

  void _drawDistantHills(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF874D46).withValues(alpha: .68);
    final path = Path()
      ..moveTo(0, size.height * .50)
      ..lineTo(size.width * .17, size.height * .32)
      ..lineTo(size.width * .30, size.height * .46)
      ..lineTo(size.width * .53, size.height * .26)
      ..lineTo(size.width * .69, size.height * .43)
      ..lineTo(size.width * .82, size.height * .31)
      ..lineTo(size.width, size.height * .42)
      ..lineTo(size.width, size.height * .60)
      ..lineTo(0, size.height * .61)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawPath(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .12, size.height * .90)
      ..cubicTo(
        size.width * .35,
        size.height * .82,
        size.width * .55,
        size.height * .92,
        size.width * .80,
        size.height * .76,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE9BB8A).withValues(alpha: .70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF8C5044).withValues(alpha: .25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawFacility(Canvas canvas, Size size, MarsFacility facility) {
    final center = Offset(
      facility.position.dx * size.width,
      facility.position.dy * size.height,
    );
    final scale = (size.shortestSide / 360).clamp(.72, 1.35);
    final shadow = Paint()..color = GameColors.ink.withValues(alpha: .24);
    final structure = Paint()
      ..color = facility.level > 0
          ? const Color(0xFFF2D8AA)
          : const Color(0xFF8C7163);
    final darkPaint = Paint()..color = GameColors.ink;
    final trim = Paint()
      ..color = facility.level > 0 ? GameColors.teal : const Color(0xFF544B4A);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, 21 * scale),
        width: 66 * scale,
        height: 15 * scale,
      ),
      shadow,
    );
    switch (facility.id) {
      case 'habitat':
        canvas.drawArc(
          Rect.fromCenter(
            center: center,
            width: 54 * scale,
            height: 49 * scale,
          ),
          3.14,
          3.14,
          true,
          structure,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: center,
            width: 54 * scale,
            height: 49 * scale,
          ),
          3.14,
          3.14,
          true,
          trim
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        canvas.drawLine(
          center.translate(0, -22 * scale),
          center.translate(0, 2 * scale),
          Paint()
            ..color = trim.color
            ..strokeWidth = 2,
        );
      case 'solar_array':
        for (var i = 0; i < 3; i++) {
          final panel = Rect.fromCenter(
            center: center.translate((i - 1) * 29 * scale, 0),
            width: 24 * scale,
            height: 16 * scale,
          );
          canvas.drawRect(panel, trim);
          canvas.drawRect(
            panel,
            Paint()
              ..color = Colors.white.withValues(alpha: .45)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
          canvas.drawLine(
            panel.topCenter,
            panel.bottomCenter,
            Paint()..color = Colors.white.withValues(alpha: .35),
          );
          for (var fleck = 0; fleck < 2; fleck++) {
            canvas.drawCircle(
              Offset(
                panel.left + 6 * scale + fleck * 10 * scale,
                panel.top + 5 * scale,
              ),
              1.5 * scale,
              Paint()..color = GameColors.rust.withValues(alpha: .72),
            );
          }
        }
        canvas.drawLine(
          center.translate(0, 10 * scale),
          center.translate(0, 18 * scale),
          structure..strokeWidth = 3,
        );
      case 'greenhouse':
        final dome = Rect.fromCenter(
          center: center,
          width: 52 * scale,
          height: 40 * scale,
        );
        canvas.drawArc(
          dome,
          3.14,
          3.14,
          true,
          Paint()..color = const Color(0xFF8DD1B2).withValues(alpha: .85),
        );
        canvas.drawArc(
          dome,
          3.14,
          3.14,
          true,
          Paint()
            ..color = trim.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        canvas.drawLine(
          center.translate(-24 * scale, 0),
          center.translate(24 * scale, 0),
          Paint()
            ..color = trim.color
            ..strokeWidth = 2,
        );
      case 'battery_bank':
        final r = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: 46 * scale,
            height: 36 * scale,
          ),
          Radius.circular(7 * scale),
        );
        canvas.drawRRect(r, structure);
        canvas.drawRRect(
          r,
          Paint()
            ..color = trim.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 13 * scale, height: 4 * scale),
          trim,
        );
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 4 * scale, height: 16 * scale),
          trim,
        );
      case 'life_support_module':
        for (var i = -1; i <= 1; i++) {
          final tank = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center.translate(i * 15 * scale, 0),
              width: 12 * scale,
              height: 34 * scale,
            ),
            Radius.circular(6 * scale),
          );
          canvas.drawRRect(tank, structure);
          canvas.drawRRect(
            tank,
            Paint()
              ..color = trim.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
        canvas.drawLine(
          center.translate(-24 * scale, 12 * scale),
          center.translate(25 * scale, 12 * scale),
          Paint()
            ..color = trim.color
            ..strokeWidth = 2,
        );
      case 'radiation_shelter':
        final shield = Path()
          ..moveTo(center.dx, center.dy - 22 * scale)
          ..lineTo(center.dx + 25 * scale, center.dy - 12 * scale)
          ..lineTo(center.dx + 20 * scale, center.dy + 12 * scale)
          ..lineTo(center.dx, center.dy + 25 * scale)
          ..lineTo(center.dx - 20 * scale, center.dy + 12 * scale)
          ..lineTo(center.dx - 25 * scale, center.dy - 12 * scale)
          ..close();
        canvas.drawPath(shield, structure);
        canvas.drawPath(
          shield,
          Paint()
            ..color = trim.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        canvas.drawCircle(center, 7 * scale, trim);
      case 'ice_miner_water_storage':
        final hull = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: 42 * scale,
            height: 20 * scale,
          ),
          Radius.circular(5 * scale),
        );
        canvas.drawRRect(hull, structure);
        canvas.drawRRect(
          hull,
          Paint()
            ..color = trim.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        canvas.drawCircle(
          center.translate(-13 * scale, 13 * scale),
          6 * scale,
          darkPaint,
        );
        canvas.drawCircle(
          center.translate(13 * scale, 13 * scale),
          6 * scale,
          darkPaint,
        );
        canvas.drawLine(
          center.translate(0, -10 * scale),
          center.translate(0, -25 * scale),
          Paint()
            ..color = trim.color
            ..strokeWidth = 4,
        );
        canvas.drawLine(
          center.translate(0, -25 * scale),
          center.translate(14 * scale, -25 * scale),
          Paint()
            ..color = trim.color
            ..strokeWidth = 4,
        );
      case 'food_storage':
        for (var i = -1; i <= 1; i++) {
          final crate = Rect.fromCenter(
            center: center.translate(i * 15 * scale, 4 * scale),
            width: 14 * scale,
            height: 22 * scale,
          );
          canvas.drawRect(crate, structure);
          canvas.drawRect(
            crate,
            Paint()
              ..color = trim.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
          canvas.drawLine(
            crate.topLeft,
            crate.bottomRight,
            Paint()
              ..color = trim.color
              ..strokeWidth = 1.5,
          );
        }
      case 'maintenance_bay':
        final bay = Path()
          ..moveTo(center.dx - 24 * scale, center.dy + 15 * scale)
          ..lineTo(center.dx - 24 * scale, center.dy - 7 * scale)
          ..lineTo(center.dx, center.dy - 25 * scale)
          ..lineTo(center.dx + 24 * scale, center.dy - 7 * scale)
          ..lineTo(center.dx + 24 * scale, center.dy + 15 * scale)
          ..close();
        canvas.drawPath(bay, structure);
        canvas.drawPath(
          bay,
          Paint()
            ..color = trim.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: center.translate(0, 6 * scale),
            width: 12 * scale,
            height: 18 * scale,
          ),
          trim,
        );
      case 'research_lab':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center,
              width: 45 * scale,
              height: 31 * scale,
            ),
            Radius.circular(5 * scale),
          ),
          structure,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center,
              width: 45 * scale,
              height: 31 * scale,
            ),
            Radius.circular(5 * scale),
          ),
          Paint()
            ..color = trim.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        canvas.drawCircle(center.translate(0, -17 * scale), 9 * scale, trim);
        canvas.drawLine(
          center.translate(0, -17 * scale),
          center.translate(10 * scale, -28 * scale),
          Paint()
            ..color = trim.color
            ..strokeWidth = 2,
        );
      case 'communications':
        canvas.drawLine(
          center.translate(0, 18 * scale),
          center.translate(0, -4 * scale),
          Paint()
            ..color = structure.color
            ..strokeWidth = 4,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: center.translate(0, -11 * scale),
            width: 34 * scale,
            height: 30 * scale,
          ),
          3.9,
          1.6,
          false,
          Paint()
            ..color = trim.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: center.translate(0, -11 * scale),
            width: 52 * scale,
            height: 48 * scale,
          ),
          3.9,
          1.6,
          false,
          Paint()
            ..color = trim.color.withValues(alpha: .55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        canvas.drawCircle(center.translate(0, -11 * scale), 4 * scale, trim);
      case 'rover':
        final rover = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center.translate(0, -1 * scale),
            width: 43 * scale,
            height: 21 * scale,
          ),
          Radius.circular(5 * scale),
        );
        canvas.drawRRect(rover, structure);
        canvas.drawCircle(
          center.translate(-14 * scale, 12 * scale),
          6 * scale,
          darkPaint,
        );
        canvas.drawCircle(
          center.translate(14 * scale, 12 * scale),
          6 * scale,
          darkPaint,
        );
        canvas.drawLine(
          center.translate(0, -11 * scale),
          center.translate(8 * scale, -24 * scale),
          Paint()
            ..color = trim.color
            ..strokeWidth = 2,
        );
        canvas.drawCircle(
          center.translate(8 * scale, -24 * scale),
          4 * scale,
          trim,
        );
        final dock = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center.translate(26 * scale, -2 * scale),
            width: 12 * scale,
            height: 22 * scale,
          ),
          Radius.circular(3 * scale),
        );
        canvas.drawRRect(dock, trim);
        canvas.drawLine(
          center.translate(15 * scale, 3 * scale),
          center.translate(20 * scale, 3 * scale),
          Paint()
            ..color = GameColors.gold
            ..strokeWidth = 2 * scale,
        );
      case 'medical_area':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center,
              width: 44 * scale,
              height: 30 * scale,
            ),
            Radius.circular(6 * scale),
          ),
          structure,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center,
              width: 44 * scale,
              height: 30 * scale,
            ),
            Radius.circular(6 * scale),
          ),
          Paint()
            ..color = trim.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 7 * scale, height: 22 * scale),
          Paint()..color = GameColors.danger,
        );
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 22 * scale, height: 7 * scale),
          Paint()..color = GameColors.danger,
        );
      default:
        final box = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: 48 * scale,
            height: 34 * scale,
          ),
          Radius.circular(6 * scale),
        );
        canvas.drawRRect(box, structure);
        canvas.drawRRect(
          box,
          Paint()
            ..color = trim.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: center.translate(0, -7 * scale),
            width: 22 * scale,
            height: 8 * scale,
          ),
          trim,
        );
    }
    if (facility.level <= 0) {
      final marker = Paint()..color = Colors.white.withValues(alpha: .9);
      canvas.drawCircle(center.translate(0, -25 * scale), 9 * scale, marker);
      if (facility.available) {
        canvas.drawLine(
          center.translate(-4 * scale, -25 * scale),
          center.translate(4 * scale, -25 * scale),
          Paint()
            ..color = GameColors.teal
            ..strokeWidth = 2.4 * scale,
        );
        canvas.drawLine(
          center.translate(0, -29 * scale),
          center.translate(0, -21 * scale),
          Paint()
            ..color = GameColors.teal
            ..strokeWidth = 2.4 * scale,
        );
      } else {
        final lockPaint = Paint()..color = GameColors.muted;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center.translate(0, -24 * scale),
              width: 10 * scale,
              height: 8 * scale,
            ),
            Radius.circular(2 * scale),
          ),
          lockPaint,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: center.translate(0, -29 * scale),
            width: 7 * scale,
            height: 8 * scale,
          ),
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = GameColors.muted
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 * scale,
        );
      }
    } else {
      final window = Paint()..color = const Color(0xFF8BD4D0);
      canvas.drawCircle(center.translate(0, 5 * scale), 3 * scale, window);
      if (facility.level > 1) {
        canvas.drawCircle(
          center.translate(20 * scale, -23 * scale),
          9 * scale,
          Paint()..color = GameColors.gold,
        );
        final levelText = TextPainter(
          text: TextSpan(
            text: '${facility.level}',
            style: TextStyle(
              color: GameColors.ink,
              fontSize: 10 * scale,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        levelText.paint(
          canvas,
          center.translate(
            20 * scale - levelText.width / 2,
            -23 * scale - levelText.height / 2,
          ),
        );
      }
    }
    final labelStyle = TextStyle(
      color: Colors.white,
      fontSize: 12 * scale,
      fontWeight: FontWeight.w700,
      shadows: const [Shadow(color: GameColors.ink, blurRadius: 3)],
    );
    final tp = TextPainter(
      text: TextSpan(text: facility.label, style: labelStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 88 * scale);
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + 25 * scale));
  }

  void _drawLights(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD58A).withValues(alpha: .85);
    for (final fraction in const [
      Offset(.20, .64),
      Offset(.48, .56),
      Offset(.80, .62),
    ]) {
      canvas.drawCircle(
        Offset(size.width * fraction.dx, size.height * fraction.dy),
        2.8,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MarsBasePainter oldDelegate) =>
      facilities != oldDelegate.facilities || sunset != oldDelegate.sunset;
}
