import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

enum PrologueScene { news, command, goodbye, launch, marsApproach, touchdown }

class PrologueScenery extends StatefulWidget {
  const PrologueScenery({
    super.key,
    required this.scene,
    required this.reducedMotion,
  });

  final PrologueScene scene;
  final bool reducedMotion;

  @override
  State<PrologueScenery> createState() => _PrologueSceneryState();
}

class _PrologueSceneryState extends State<PrologueScenery>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: GameMotion.idle,
  );

  @override
  void initState() {
    super.initState();
    _setMotion();
  }

  @override
  void didUpdateWidget(covariant PrologueScenery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reducedMotion != widget.reducedMotion ||
        oldWidget.scene != widget.scene) {
      _setMotion();
    }
  }

  void _setMotion() {
    if (widget.reducedMotion) {
      _controller.stop();
      _controller.value = .5;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _PrologueSceneryPainter(
          scene: widget.scene,
          motion: widget.reducedMotion ? .5 : _controller.value,
        ),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class _PrologueSceneryPainter extends CustomPainter {
  const _PrologueSceneryPainter({required this.scene, required this.motion});

  final PrologueScene scene;
  final double motion;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: switch (scene) {
          PrologueScene.news ||
          PrologueScene.command => const [GameColors.night, GameColors.ink],
          PrologueScene.goodbye ||
          PrologueScene.launch => const [GameColors.night, GameColors.rust],
          PrologueScene.marsApproach ||
          PrologueScene.touchdown => const [GameColors.night, GameColors.mars],
        },
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);
    _stars(canvas, size);
    if (scene == PrologueScene.news) _staticLines(canvas, size);
    if (scene == PrologueScene.launch) _rocket(canvas, size);
    if (scene == PrologueScene.marsApproach) _marsApproach(canvas, size);
    if (scene == PrologueScene.touchdown) _mars(canvas, size);
    if (scene == PrologueScene.command || scene == PrologueScene.goodbye) {
      _horizon(canvas, size);
    }
  }

  void _stars(Canvas canvas, Size size) {
    final paint = Paint()..color = GameColors.sand.withValues(alpha: .64);
    for (final point in const [
      Offset(.12, .17),
      Offset(.32, .10),
      Offset(.79, .14),
      Offset(.90, .28),
      Offset(.22, .37),
      Offset(.70, .34),
    ]) {
      canvas.drawCircle(
        Offset(size.width * point.dx, size.height * point.dy),
        1.6 + motion * .8,
        paint,
      );
    }
  }

  void _staticLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = GameColors.paper.withValues(alpha: .045 + motion * .05)
      ..strokeWidth = 1;
    for (var row = 1; row < 12; row++) {
      final y =
          size.height * row / 12 + (row.isEven ? motion * 2 : -motion * 2);
      canvas.drawLine(
        Offset.zero.translate(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _marsApproach(Canvas canvas, Size size) {
    final diameter = size.shortestSide * (.26 + motion * .025);
    final center = Offset(size.width * .72, size.height * .58);
    canvas.drawCircle(center, diameter / 2, Paint()..color = GameColors.mars);
    canvas.drawArc(
      Rect.fromCircle(
        center: center.translate(-diameter * .10, 0),
        radius: diameter / 2,
      ),
      math.pi * .52,
      math.pi * 1.05,
      false,
      Paint()
        ..color = GameColors.rust
        ..style = PaintingStyle.stroke
        ..strokeWidth = diameter * .10,
    );
    final craftCenter = Offset(
      size.width * (.36 + motion * .025),
      size.height * .64,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: craftCenter,
          width: diameter * .28,
          height: diameter * .12,
        ),
        const Radius.circular(GameRadii.button / 3),
      ),
      Paint()..color = GameColors.paper,
    );
  }

  void _rocket(Canvas canvas, Size size) {
    final x = size.width * (.48 + (motion - .5) * .08);
    final y = size.height * (.52 - motion * .12);
    final body = Paint()..color = GameColors.paper;
    final outline = Paint()
      ..color = GameColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final shape = Path()
      ..moveTo(x, y - size.shortestSide * .11)
      ..quadraticBezierTo(
        x + size.shortestSide * .07,
        y,
        x,
        y + size.shortestSide * .08,
      )
      ..quadraticBezierTo(
        x - size.shortestSide * .07,
        y,
        x,
        y - size.shortestSide * .11,
      )
      ..close();
    canvas.drawPath(shape, body);
    canvas.drawPath(shape, outline);
    canvas.drawCircle(
      Offset(x, y - size.shortestSide * .025),
      size.shortestSide * .018,
      Paint()..color = GameColors.teal,
    );
    final flame = Path()
      ..moveTo(x - size.shortestSide * .025, y + size.shortestSide * .06)
      ..lineTo(x, y + size.shortestSide * (.11 + motion * .03))
      ..lineTo(x + size.shortestSide * .025, y + size.shortestSide * .06)
      ..close();
    canvas.drawPath(flame, Paint()..color = GameColors.gold);
  }

  void _mars(Canvas canvas, Size size) {
    final horizon = Path()
      ..moveTo(0, size.height * .70)
      ..quadraticBezierTo(
        size.width * .50,
        size.height * (.62 - motion * .025),
        size.width,
        size.height * .69,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(horizon, Paint()..color = GameColors.rust);
    final craft = Rect.fromCenter(
      center: Offset(size.width * .52, size.height * (.68 - motion * .015)),
      width: size.width * .20,
      height: size.height * .09,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        craft,
        const Radius.circular(GameRadii.button / 2),
      ),
      Paint()..color = GameColors.sand,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        craft,
        const Radius.circular(GameRadii.button / 2),
      ),
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke,
    );
  }

  void _horizon(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * .76)
      ..quadraticBezierTo(
        size.width * .48,
        size.height * .67,
        size.width,
        size.height * .73,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = GameColors.rust.withValues(alpha: .72),
    );
  }

  @override
  bool shouldRepaint(covariant _PrologueSceneryPainter oldDelegate) =>
      scene != oldDelegate.scene || motion != oldDelegate.motion;
}
