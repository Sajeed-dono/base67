import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';
import 'facility_architecture.dart';

enum PrologueScene { news, command, goodbye, launch, marsApproach, touchdown }

class PrologueScenery extends StatefulWidget {
  const PrologueScenery({
    super.key,
    required this.scene,
    required this.reducedMotion,
    this.launching = false,
  });

  final PrologueScene scene;
  final bool reducedMotion;
  final bool launching;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setMotion();
  }

  bool get _reduced =>
      widget.reducedMotion ||
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);

  @override
  void didUpdateWidget(covariant PrologueScenery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reducedMotion != widget.reducedMotion ||
        oldWidget.scene != widget.scene) {
      _setMotion();
    }
  }

  void _setMotion() {
    if (_reduced) {
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
          motion: _reduced ? .5 : _controller.value,
          launching: widget.launching,
        ),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class _PrologueSceneryPainter extends CustomPainter {
  const _PrologueSceneryPainter({
    required this.scene,
    required this.motion,
    required this.launching,
  });

  final PrologueScene scene;
  final double motion;
  final bool launching;

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
    if (scene == PrologueScene.launch) {
      _stars(canvas, size);
      _launchScene(canvas, size);
      return;
    }
    _stars(canvas, size);
    if (scene == PrologueScene.news) _staticLines(canvas, size);
    if (scene == PrologueScene.marsApproach) _marsApproach(canvas, size);
    if (scene == PrologueScene.touchdown) _mars(canvas, size);
    if (scene == PrologueScene.command || scene == PrologueScene.goodbye) {
      _horizon(canvas, size);
    }
  }

  void _stars(Canvas canvas, Size size) {
    final paint = Paint()..color = GameColors.sand.withValues(alpha: .64);
    for (final (index, point) in const [
      Offset(.12, .17),
      Offset(.32, .10),
      Offset(.79, .14),
      Offset(.90, .28),
      Offset(.22, .37),
      Offset(.70, .34),
    ].indexed) {
      final drift = scene == PrologueScene.launch
          ? (motion - .5) * (index.isEven ? .012 : .026)
          : 0.0;
      canvas.drawCircle(
        Offset(size.width * (point.dx + drift), size.height * point.dy),
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

  void _launchScene(Canvas canvas, Size size) {
    final horizon = size.height * .70;
    final glowCenter = Offset(size.width * .5, horizon - size.height * .08);
    canvas.drawCircle(
      glowCenter,
      size.shortestSide * .65,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                GameColors.prologueOrange.withValues(alpha: .38),
                GameColors.prologueAmber.withValues(alpha: .10),
                Colors.transparent,
              ],
              stops: const [0, .45, 1],
            ).createShader(
              Rect.fromCircle(
                center: glowCenter,
                radius: size.shortestSide * .65,
              ),
            ),
    );
    for (var i = 0; i < 16; i++) {
      final x = ((i * 149 + 29) % 997) / 997 * size.width;
      final y = ((i * 97 + 19) % 400) / 1000 * size.height;
      canvas.drawCircle(
        Offset(x, y),
        .7 + i % 3 * .35,
        Paint()..color = GameColors.paper.withValues(alpha: .32 + i % 3 * .1),
      );
    }
    for (var layer = 0; layer < 2; layer++) {
      final ridge = Path()
        ..moveTo(0, size.height * (.52 + layer * .10))
        ..lineTo(size.width * .15, size.height * (.48 + layer * .09))
        ..lineTo(size.width * .32, size.height * (.54 + layer * .10))
        ..lineTo(size.width * .61, size.height * (.47 + layer * .12))
        ..lineTo(size.width * .82, size.height * (.51 + layer * .10))
        ..lineTo(size.width, size.height * (.46 + layer * .13))
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        ridge,
        Paint()
          ..color = layer == 0
              ? const Color(0xFF704D55)
              : const Color(0xFF332D3A),
      );
    }
    final pad = Rect.fromCenter(
      center: Offset(size.width * .5, horizon),
      width: size.width * .48,
      height: size.shortestSide * .12,
    );
    canvas.drawOval(pad, Paint()..color = const Color(0xFF151E2B));
    canvas.drawOval(
      pad.deflate(size.shortestSide * .018),
      Paint()
        ..color = GameColors.prologueTeal.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    for (var i = 0; i < 6; i++) {
      final at = Offset(
        pad.left + pad.width * i / 5,
        pad.center.dy + math.sin(i * .8) * pad.height * .2,
      );
      canvas.drawCircle(at, 2.3, Paint()..color = GameColors.prologueAmber);
    }
    final gantryX = size.width * .65;
    final gantry = Paint()
      ..color = GameColors.machineryHighlight.withValues(alpha: .8)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(gantryX, size.height * .15),
      Offset(gantryX, horizon),
      gantry,
    );
    for (var y = size.height * .2; y < horizon; y += size.shortestSide * .10) {
      canvas.drawLine(
        Offset(gantryX - size.shortestSide * .045, y),
        Offset(gantryX + size.shortestSide * .045, y),
        gantry,
      );
    }
    for (var i = 0; i < 4; i++) {
      final light = Offset(
        gantryX - size.shortestSide * .045,
        size.height * (.22 + i * .13),
      );
      canvas.drawCircle(
        light,
        size.shortestSide * .045,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  GameColors.prologueAmber.withValues(alpha: .28),
                  Colors.transparent,
                ],
              ).createShader(
                Rect.fromCircle(
                  center: light,
                  radius: size.shortestSide * .045,
                ),
              ),
      );
      canvas.drawCircle(light, 2.4, Paint()..color = GameColors.prologueAmber);
    }
    _rocket(canvas, size, horizon);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        horizon - size.height * .08,
        size.width,
        size.height * .18,
      ),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            GameColors.prologueAmber.withValues(alpha: .11),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );
    final bar = size.height * .075;
    canvas
      ..drawRect(
        Rect.fromLTWH(0, 0, size.width, bar),
        Paint()..color = Colors.black.withValues(alpha: .8),
      )
      ..drawRect(
        Rect.fromLTWH(0, size.height - bar, size.width, bar),
        Paint()..color = Colors.black.withValues(alpha: .8),
      );
  }

  void _rocket(Canvas canvas, Size size, double horizon) {
    final x = size.width * .49;
    final height = math.min(size.height * .58, size.shortestSide * .95);
    final top = horizon - height;
    final width = height * .18;
    canvas.save();
    final push = 1 + (motion - .5) * .035;
    if (launching) canvas.translate(math.sin(motion * math.pi * 2) * 2.5, 0);
    canvas.translate(x, horizon - height * .5);
    canvas.scale(push);
    canvas.translate(-x, -(horizon - height * .5));
    canvas.drawPath(
      Path()
        ..moveTo(x - width * .38, horizon)
        ..lineTo(x - width * .12, top + height * .08)
        ..lineTo(x + width * .12, top + height * .08)
        ..lineTo(x + width * .38, horizon)
        ..close(),
      Paint()..color = GameColors.prologueAmber.withValues(alpha: .08),
    );
    final body = Path()
      ..moveTo(x, top)
      ..quadraticBezierTo(
        x + width * .44,
        top + height * .09,
        x + width * .42,
        top + height * .25,
      )
      ..lineTo(x + width * .42, horizon - height * .10)
      ..lineTo(x - width * .42, horizon - height * .10)
      ..lineTo(x - width * .42, top + height * .25)
      ..quadraticBezierTo(x - width * .44, top + height * .09, x, top)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [GameColors.moduleShade, GameColors.paper, Color(0xFF8D9AA6)],
        ).createShader(Rect.fromLTWH(x - width / 2, top, width, height)),
    );
    canvas.drawPath(
      body,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final boosterWidth = width * .22;
    for (final side in [-1.0, 1.0]) {
      final bx = x + side * width * .56;
      final booster = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          bx - boosterWidth / 2,
          top + height * .26,
          boosterWidth,
          height * .56,
        ),
        Radius.circular(boosterWidth / 2),
      );
      canvas.drawRRect(booster, Paint()..color = GameColors.machineryHighlight);
      canvas.drawRRect(
        booster,
        Paint()
          ..color = GameColors.ink
          ..style = PaintingStyle.stroke,
      );
      canvas.drawLine(
        Offset(bx, top + height * .35),
        Offset(bx, horizon - height * .22),
        Paint()
          ..color = GameColors.paper.withValues(alpha: .7)
          ..strokeWidth = 1,
      );
    }
    for (var i = 0; i < 5; i++) {
      final y = top + height * (.27 + i * .12);
      canvas.drawLine(
        Offset(x - width * .38, y),
        Offset(x + width * .38, y),
        Paint()
          ..color = GameColors.machinery.withValues(alpha: .65)
          ..strokeWidth = 1,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x - width * .22,
          top + height * .38,
          width * .44,
          height * .08,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = GameColors.prologueOrange,
    );
    final patch = Path()
      ..moveTo(x, top + height * .35)
      ..lineTo(x + width * .12, top + height * .39)
      ..lineTo(x + width * .12, top + height * .47)
      ..lineTo(x, top + height * .51)
      ..lineTo(x - width * .12, top + height * .47)
      ..lineTo(x - width * .12, top + height * .39)
      ..close();
    canvas.drawPath(patch, Paint()..color = GameColors.prologueTeal);
    canvas.drawCircle(
      Offset(x, top + height * .43),
      width * .045,
      Paint()..color = GameColors.prologueAmber,
    );
    if (launching) {
      final flicker = .82 + motion * .3;
      final flame = Path()
        ..moveTo(x - width * .28, horizon - height * .10)
        ..quadraticBezierTo(
          x,
          horizon + height * .30 * flicker,
          x + width * .28,
          horizon - height * .10,
        )
        ..close();
      canvas.drawPath(flame, Paint()..color = GameColors.prologueOrange);
      canvas.drawPath(
        flame,
        Paint()
          ..color = GameColors.prologueAmber.withValues(alpha: .86)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      for (var i = 0; i < 18; i++) {
        final puff = Offset(
          x + math.sin(i * 9.3) * width * (1 + i % 3),
          horizon + height * (.08 + i % 6 * .035),
        );
        canvas.drawCircle(
          puff,
          width * (.08 + i % 4 * .025),
          Paint()..color = GameColors.marsHaze.withValues(alpha: .16),
        );
      }
    }
    canvas.restore();
  }

  void _mars(Canvas canvas, Size size) {
    final distant = Path()
      ..moveTo(0, size.height * .72)
      ..lineTo(size.width * .16, size.height * .61)
      ..lineTo(size.width * .34, size.height * .70)
      ..lineTo(size.width * .72, size.height * .57)
      ..lineTo(size.width, size.height * .69)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(distant, Paint()..color = GameColors.marsDistant);
    final middle = Path()
      ..moveTo(0, size.height * .77)
      ..lineTo(size.width * .22, size.height * .68)
      ..lineTo(size.width * .41, size.height * .78)
      ..lineTo(size.width * .69, size.height * .66)
      ..lineTo(size.width, size.height * .75)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(middle, Paint()..color = const Color(0xFF95543F));
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
    canvas.drawPath(
      horizon,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFA44E36), GameColors.rust, Color(0xFF743E35)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .52, size.height * .84),
        width: size.width * .30,
        height: size.height * .07,
      ),
      Paint()
        ..color = GameColors.prologueAmber.withValues(alpha: .28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.save();
    canvas.translate(size.width * .52, size.height * (.68 - motion * .015));
    canvas.scale(size.shortestSide * .005);
    FacilityArchitecture.paint(
      canvas,
      'landing_craft',
      shell: GameColors.structuralSurface,
      trim: GameColors.architecturalAccent,
    );
    canvas.restore();
    for (var i = 0; i < 2; i++) {
      final at = Offset(size.width * (.43 + i * .16), size.height * .80);
      final person = RRect.fromRectAndRadius(
        Rect.fromLTWH(at.dx - 3, at.dy - 20, 6, 15),
        const Radius.circular(3),
      );
      canvas.drawCircle(
        at.translate(0, -23),
        3.2,
        Paint()..color = GameColors.ink,
      );
      canvas.drawRRect(person, Paint()..color = GameColors.ink);
      canvas.drawLine(
        at.translate(-2, -5),
        at.translate(-5, 3),
        Paint()
          ..color = GameColors.ink
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        at.translate(2, -5),
        at.translate(5, 3),
        Paint()
          ..color = GameColors.ink
          ..strokeWidth = 2,
      );
    }
    for (var i = 0; i < 18; i++) {
      final at = Offset(
        size.width * ((i * 191 + 37) % 997) / 997,
        size.height * (.76 + (i * 23 % 20) / 100 + motion * .005),
      );
      canvas.drawCircle(
        at,
        1 + i % 3,
        Paint()..color = GameColors.sand.withValues(alpha: .16),
      );
    }
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
      scene != oldDelegate.scene ||
      motion != oldDelegate.motion ||
      launching != oldDelegate.launching;
}
