import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

enum CrewMood {
  okay,
  cold,
  hungry,
  worried,
  working,
  resting,
  sheltering,
  researching,
  celebrating,
}

enum CrewRole { commander, engineer, scientist, medic }

const crewSuitColors = <Color>[
  Color(0xFFEF6C4D),
  Color(0xFF3B86A8),
  Color(0xFF38A58C),
  Color(0xFF9C6BC1),
  Color(0xFFE0A838),
  Color(0xFF4F91D1),
  Color(0xFFCA6686),
  Color(0xFF6B9A4C),
  Color(0xFFAE5D32),
  Color(0xFF56748A),
  Color(0xFF8B78C5),
  Color(0xFFB64C48),
];

class CrewBean extends StatefulWidget {
  const CrewBean({
    super.key,
    required this.role,
    this.mood = CrewMood.okay,
    this.suitColorIndex = 0,
    this.reducedMotion = false,
    this.size = 88,
    this.label,
  });

  final CrewRole role;
  final CrewMood mood;
  final int suitColorIndex;
  final bool reducedMotion;
  final double size;
  final String? label;

  @override
  State<CrewBean> createState() => _CrewBeanState();
}

class _CrewBeanState extends State<CrewBean>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: GameMotion.idle,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reducedMotion) _breath.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant CrewBean oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = crewSuitColors[widget.suitColorIndex % crewSuitColors.length];
    final painter = AnimatedBuilder(
      animation: _breath,
      builder: (context, _) => CustomPaint(
        size: Size(widget.size, widget.size * 1.16),
        painter: CrewBeanPainter(
          role: widget.role,
          mood: widget.mood,
          suitColor: color,
          breath: widget.reducedMotion ? 0 : _breath.value,
        ),
      ),
    );
    return Semantics(
      label:
          widget.label ?? '${widget.role.name} astronaut, ${widget.mood.name}',
      image: true,
      child: SizedBox(
        width: widget.size,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            painter,
            if (widget.label != null) ...[
              const SizedBox(height: 3),
              SizedBox(
                width: widget.size,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label!,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CrewBeanPainter extends CustomPainter {
  const CrewBeanPainter({
    required this.role,
    required this.mood,
    required this.suitColor,
    required this.breath,
  });

  final CrewRole role;
  final CrewMood mood;
  final Color suitColor;
  final double breath;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100;
    final sy = size.height / 116;
    canvas.save();
    canvas.scale(sx, sy);
    final rise = mood == CrewMood.celebrating ? -4.0 : breath * 1.5;
    final suit = Paint()..color = suitColor;
    final trim = Paint()..color = Colors.white.withValues(alpha: 0.92);
    final dark = Paint()..color = GameColors.ink;
    final shadow = Paint()..color = GameColors.ink.withValues(alpha: 0.15);
    final visor = Paint()..color = const Color(0xFF9BD8D7);
    final stroke = Paint()
      ..color = GameColors.ink.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawOval(const Rect.fromLTWH(20, 99, 62, 10), shadow);
    canvas.save();
    canvas.translate(0, rise);
    // Backpack sits behind the rounded suit.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(67, 40, 22, 40),
        const Radius.circular(8),
      ),
      suit,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(68, 47, 18, 14),
        const Radius.circular(5),
      ),
      trim,
    );
    // Legs and boots.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(31, 78, 15, 24),
        const Radius.circular(7),
      ),
      suit,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(55, 78, 15, 24),
        const Radius.circular(7),
      ),
      suit,
    );
    canvas.drawOval(const Rect.fromLTWH(25, 95, 25, 9), dark);
    canvas.drawOval(const Rect.fromLTWH(52, 95, 25, 9), dark);
    // Bean shaped body with a broad shoulder and narrow waist.
    final body = Path()
      ..moveTo(26, 75)
      ..cubicTo(18, 65, 17, 41, 25, 27)
      ..cubicTo(31, 13, 68, 13, 75, 28)
      ..cubicTo(83, 44, 80, 67, 71, 77)
      ..cubicTo(58, 87, 39, 86, 26, 75)
      ..close();
    canvas.drawPath(body, suit);
    canvas.drawPath(body, stroke);
    // Visor, shine and lower suit panel.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(31, 30, 39, 26),
        const Radius.circular(13),
      ),
      dark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(35, 33, 31, 19),
        const Radius.circular(10),
      ),
      visor,
    );
    canvas.drawArc(
      const Rect.fromLTWH(39, 34, 20, 12),
      3.2,
      1.1,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(39, 62, 24, 12),
        const Radius.circular(5),
      ),
      trim,
    );
    _drawMood(canvas);
    _drawBadge(canvas);
    _drawMoodDetails(canvas);
    canvas.restore();
    canvas.restore();
  }

  void _drawMood(Canvas canvas) {
    final face = Paint()..color = GameColors.ink;
    final white = Paint()..color = Colors.white;
    final eyeY = mood == CrewMood.worried ? 43.0 : 45.0;
    final eyeRadius = mood == CrewMood.resting ? 1.8 : 2.5;
    if (mood == CrewMood.resting) {
      final line = Paint()
        ..color = GameColors.ink
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(42, 45), const Offset(47, 45), line);
      canvas.drawLine(const Offset(56, 45), const Offset(61, 45), line);
    } else {
      canvas.drawCircle(Offset(44, eyeY), eyeRadius + 1, white);
      canvas.drawCircle(Offset(59, eyeY), eyeRadius + 1, white);
      canvas.drawCircle(Offset(45, eyeY + 1), eyeRadius, face);
      canvas.drawCircle(Offset(60, eyeY + 1), eyeRadius, face);
    }
    final mouth = Paint()
      ..color = GameColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final path = Path();
    switch (mood) {
      case CrewMood.worried:
      case CrewMood.hungry:
        path.moveTo(48, 53);
        path.quadraticBezierTo(52, 49, 57, 53);
      case CrewMood.cold:
        path.moveTo(49, 53);
        path.lineTo(55, 53);
      case CrewMood.celebrating:
        path.moveTo(47, 51);
        path.quadraticBezierTo(52, 60, 59, 51);
      case CrewMood.resting:
        path.moveTo(49, 53);
        path.lineTo(55, 53);
      default:
        path.moveTo(47, 51);
        path.quadraticBezierTo(52, 57, 59, 51);
    }
    canvas.drawPath(path, mouth);
  }

  void _drawMoodDetails(Canvas canvas) {
    final accent = Paint()..color = GameColors.gold;
    final ink = Paint()
      ..color = GameColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    switch (mood) {
      case CrewMood.cold:
        final frost = Paint()..color = Colors.white.withValues(alpha: 0.9);
        canvas.drawCircle(const Offset(76, 25), 3, frost);
        canvas.drawCircle(const Offset(20, 48), 2, frost);
      case CrewMood.hungry:
        canvas.drawCircle(const Offset(73, 69), 7, accent);
        canvas.drawLine(const Offset(73, 62), const Offset(73, 76), ink);
      case CrewMood.worried:
        canvas.drawCircle(
          const Offset(74, 43),
          3,
          Paint()..color = const Color(0xFF78B9D0),
        );
      case CrewMood.working:
        canvas.drawLine(const Offset(77, 65), const Offset(85, 57), ink);
        canvas.drawLine(const Offset(81, 54), const Offset(87, 60), ink);
      case CrewMood.sheltering:
        final shield = Path()
          ..moveTo(20, 24)
          ..lineTo(27, 27)
          ..lineTo(26, 35)
          ..lineTo(20, 39)
          ..lineTo(14, 35)
          ..lineTo(13, 27)
          ..close();
        canvas.drawPath(shield, accent);
      case CrewMood.researching:
        canvas.drawLine(const Offset(76, 35), const Offset(82, 48), ink);
        canvas.drawLine(const Offset(82, 48), const Offset(76, 53), ink);
        canvas.drawLine(const Offset(76, 53), const Offset(71, 48), ink);
        canvas.drawCircle(
          const Offset(77, 44),
          2,
          Paint()..color = GameColors.teal,
        );
      case CrewMood.celebrating:
        for (final point in const [
          Offset(17, 20),
          Offset(81, 18),
          Offset(82, 72),
        ]) {
          canvas.drawCircle(point, 3, accent);
        }
      case CrewMood.okay:
      case CrewMood.resting:
        break;
    }
  }

  void _drawBadge(Canvas canvas) {
    final center = const Offset(34, 69);
    canvas.drawCircle(center, 12, Paint()..color = GameColors.sand);
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final badge = Paint()
      ..color = GameColors.rust
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (role) {
      case CrewRole.commander:
        final points = <Offset>[];
        for (var index = 0; index < 10; index++) {
          final angle = -math.pi / 2 + index * math.pi / 5;
          final radius = index.isEven ? 8.0 : 4.0;
          points.add(
            Offset(
              center.dx + radius * math.cos(angle),
              center.dy + radius * math.sin(angle),
            ),
          );
        }
        final star = Path()..addPolygon(points, true);
        canvas.drawPath(star, Paint()..color = GameColors.rust);
      case CrewRole.engineer:
        canvas.drawCircle(const Offset(36, 64), 4, badge);
        canvas.drawLine(const Offset(36, 68), const Offset(31, 76), badge);
        canvas.drawLine(const Offset(31, 76), const Offset(27, 73), badge);
        canvas.drawLine(const Offset(31, 76), const Offset(35, 78), badge);
      case CrewRole.scientist:
        final flask = Path()
          ..moveTo(31, 61)
          ..lineTo(37, 61)
          ..moveTo(33, 61)
          ..lineTo(33, 67)
          ..lineTo(28, 75)
          ..quadraticBezierTo(27, 78, 31, 78)
          ..lineTo(38, 78)
          ..quadraticBezierTo(41, 78, 39, 75)
          ..lineTo(35, 67)
          ..lineTo(35, 61);
        canvas.drawPath(flask, badge);
        canvas.drawLine(const Offset(30, 73), const Offset(38, 73), badge);
      case CrewRole.medic:
        final cross = Paint()..color = GameColors.teal;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(31, 62, 6, 14),
            const Radius.circular(2),
          ),
          cross,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(27, 66, 14, 6),
            const Radius.circular(2),
          ),
          cross,
        );
    }
  }

  @override
  bool shouldRepaint(covariant CrewBeanPainter oldDelegate) =>
      role != oldDelegate.role ||
      mood != oldDelegate.mood ||
      suitColor != oldDelegate.suitColor ||
      breath != oldDelegate.breath;
}
