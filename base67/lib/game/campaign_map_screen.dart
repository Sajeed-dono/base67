import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/campaign_save.dart';
import '../data/repositories/game_data_repository.dart';
import '../ui/game_widgets.dart';
import '../ui/mars_terrain.dart';
import '../ui/theme.dart';
import '../data/models/data_class.dart';
import '../progression/progression_service.dart';

const _chapterRowHeight = 108.0;
const _campaignNodeHeight = 104.0;

class CampaignMapScreen extends StatelessWidget {
  const CampaignMapScreen({
    super.key,
    required this.save,
    required this.repository,
    required this.openLevel,
    this.progression,
  });

  final CampaignSave save;
  final GameDataRepository repository;
  final ValueChanged<String> openLevel;
  final ProgressionState? progression;

  Future<void> _details(BuildContext context, String id) async {
    final level = (repository.campaign['levels'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((row) => row['id'] == id);
    final materials =
        repository.document('progression_rules.json')?['materials'] as Map?;
    final eligible = (materials?['eligible_level_ids'] as List? ?? const [])
        .contains(id);
    final receipt = progression?.receipts['resupply:$id'];
    final complete = save.completedLevelIds.contains(id);
    final result = save.levelResults[id];
    final open = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .75,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(GameSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  level['name'] as String,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                GameCopy(
                  complete
                      ? 'Completed / progress saved'
                      : 'Available / next challenge',
                ),
                const SizedBox(height: GameSpacing.md),
                FactCard(
                  title: 'What you will learn',
                  body: level['learning_objective'] as String,
                  dataClass: DataClass.game,
                ),
                FactCard(
                  title: 'Mission goal',
                  body: level['mission_objective'] as String,
                  dataClass: DataClass.game,
                ),
                if (receipt != null)
                  GameCopy(
                    'Recorded resupply: ${receipt.amount.toStringAsFixed(0)} materials. This receipt is retained; replay does not award it again.',
                  )
                else if (eligible)
                  GameCopy(
                    'First success: ${materials!['per_first_mission']} construction materials, once. Survival supplies are not refilled. These reward values are provisional.',
                  )
                else
                  const GameCopy(
                    'Completion and any existing rewards stay with the campaign.',
                  ),
                const DataChip(DataClass.game),
                if (result is Map && result['assisted'] == true)
                  const GameCopy(
                    'The saved result records emergency support. Practice is always welcome.',
                  ),
                const SizedBox(height: GameSpacing.md),
                const GameCopy(
                  'Your current crew, facilities and supplies carry into this mission. Replay uses this same base.',
                ),
                GameButton(
                  label: 'Open mission briefing',
                  reducedMotion: save.settings['reduceMotion'] == true,
                  onPressed: () => Navigator.pop(context, true),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Back to campaign'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (open == true) openLevel(id);
  }

  @override
  Widget build(BuildContext context) {
    final chapters =
        (repository.campaign['chapters'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const [];
    final levels =
        (repository.campaign['levels'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const [];
    final nextId = levels
        .where(
          (level) =>
              save.unlockedLevelIds.contains(level['id']) &&
              !save.completedLevelIds.contains(level['id']),
        )
        .map((level) => level['id'] as String)
        .firstOrNull;

    return Scaffold(
      backgroundColor: GameColors.night,
      appBar: AppBar(
        title: const Text('Campaign Map'),
        backgroundColor: GameColors.night,
        foregroundColor: GameColors.sand,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              GameSpacing.page,
              8,
              GameSpacing.page,
              28,
            ),
            children: [
              const ColonySectionHeading(
                title: 'Mission route',
                caption: 'Five chapters, one settlement. Return to earlier missions with your existing base.',
                icon: Icons.explore_outlined,
              ),
              const SizedBox(height: GameSpacing.md),
              Text(
                'One base. Fifteen missions.',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: GameColors.sand),
              ),
              const SizedBox(height: 6),
              Text(
                '${save.completedLevelIds.length} of ${levels.length} missions completed. Your progress stays with your base.',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              if (nextId != null) ...[
                MissionControlPanel(
                  child: Builder(
                    builder: (context) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GameCopy(
                          'Next mission: ${levels.firstWhere((level) => level['id'] == nextId)['name']}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: GameSpacing.sm),
                        GameButton(
                          label: 'Mission details',
                          secondary: true,
                          reducedMotion:
                              save.settings['reduceMotion'] == true,
                          onPressed: () => _details(context, nextId),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: GameSpacing.md),
              ],
              for (var i = 0; i < chapters.length; i++) ...[
                _ChapterMap(
                  title: chapters[i]['name'] as String? ?? 'Chapter',
                  chapterIndex: i,
                  levelIds:
                      (chapters[i]['level_ids'] as List?)?.cast<String>() ??
                      const [],
                  levels: levels,
                  save: save,
                  nextLevelId: nextId,
                  openLevel: openLevel,
                  showDetails: (id) => _details(context, id),
                ),
                const SizedBox(height: 14),
              ],
              const MarsPanel(
                child: Row(
                  children: [
                    Icon(Icons.flag_rounded, color: GameColors.teal),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Follow the winding path. Locked missions open as you complete earlier goals.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterMap extends StatefulWidget {
  const _ChapterMap({
    required this.title,
    required this.chapterIndex,
    required this.levelIds,
    required this.levels,
    required this.save,
    required this.nextLevelId,
    required this.openLevel,
    required this.showDetails,
  });

  final String title;
  final int chapterIndex;
  final List<String> levelIds;
  final List<Map<String, dynamic>> levels;
  final CampaignSave save;
  final String? nextLevelId;
  final ValueChanged<String> openLevel;
  final ValueChanged<String> showDetails;

  @override
  State<_ChapterMap> createState() => _ChapterMapState();
}

class _ChapterMapState extends State<_ChapterMap>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final AnimationController _route = AnimationController(
    vsync: this,
    duration: GameMotion.idle,
  );
  String get title => widget.title;
  int get chapterIndex => widget.chapterIndex;
  List<String> get levelIds => widget.levelIds;
  List<Map<String, dynamic>> get levels => widget.levels;
  CampaignSave get save => widget.save;
  String? get nextLevelId => widget.nextLevelId;
  ValueChanged<String> get openLevel => widget.openLevel;
  ValueChanged<String> get showDetails => widget.showDetails;
  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMotion();
  }

  @override
  void didUpdateWidget(covariant _ChapterMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateMotion();
  }

  void _updateMotion() {
    final reduced =
        save.settings['reduceMotion'] == true ||
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (reduced != _reducedMotion) {
      _reducedMotion = reduced;
      if (reduced) {
        _entrance.value = 1;
        _route.stop();
      }
    }
    if (!_reducedMotion && !_entrance.isAnimating && _entrance.value < 1) {
      _entrance.forward();
    }
    if (_reducedMotion || _nextSegment() == null) {
      _route.stop();
    } else if (!_route.isAnimating) {
      _route.repeat();
    }
  }

  int? _nextSegment() {
    for (var i = 0; i < levelIds.length - 1; i++) {
      if (save.unlockedLevelIds.contains(levelIds[i]) &&
          !save.completedLevelIds.contains(levelIds[i])) {
        return i;
      }
    }
    return null;
  }

  Set<int> _completedSegments() => {
    for (var i = 0; i < levelIds.length - 1; i++)
      if (save.completedLevelIds.contains(levelIds[i]) &&
          save.unlockedLevelIds.contains(levelIds[i + 1]))
        i,
  };

  @override
  void dispose() {
    _entrance.dispose();
    _route.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = _pathPoints(levelIds.length);
    const rowHeight = _chapterRowHeight;
    final height = levelIds.length * rowHeight;
    return MarsPanel(
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _ChapterBackdropPainter(chapterIndex),
              ),
            ),
          ),
          Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: GameColors.night,
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Material(
                    color: GameColors.rust,
                    shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                      side: const BorderSide(color: GameColors.sand, width: 1),
                    ),
                    child: SizedBox(
                      width: 40,
                      height: 38,
                      child: Center(
                        child: Text(
                          '${chapterIndex + 1}'.padLeft(2, '0'),
                          style: const TextStyle(
                            color: GameColors.sand,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(_chapterIcon(chapterIndex), color: GameColors.tealLight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: GameColors.sand,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: height,
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _WindingPathPainter(
                        points: points,
                        completedSegments: _completedSegments(),
                        nextSegment: _nextSegment(),
                        phase: _route.value,
                        routeAnimation: _route,
                      ),
                    ),
                  ),
                  for (var i = 0; i < levelIds.length; i++)
                    _positionedNode(
                      context,
                      constraints.maxWidth,
                      points[i],
                      i,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }

  Widget _positionedNode(
    BuildContext context,
    double width,
    Offset point,
    int index,
  ) {
    final id = levelIds[index];
    final level = levels.firstWhere((item) => item['id'] == id);
    final number = levels.indexWhere((item) => item['id'] == id) + 1;
    final isOpen = save.unlockedLevelIds.contains(id);
    final state = _stateFor(id);
    final title = level['name'] as String? ?? 'Mission $number';
    final nodeWidth = width < 380 ? 118.0 : 144.0;
    const nodeHeight = _campaignNodeHeight;
    final left = (point.dx * width - nodeWidth / 2).clamp(
      0.0,
      width - nodeWidth,
    );
    final top = point.dy * levelIds.length * _chapterRowHeight - nodeHeight / 2;
    return Positioned(
      left: left,
      top: top,
      width: nodeWidth,
      height: nodeHeight,
      child: Semantics(
        button: isOpen,
        label: isOpen
            ? 'Level $number, $title, ${state.name}'
            : 'Locked: $title',
        child: AnimatedBuilder(
          animation: _entrance,
          child: InkWell(
            key: ValueKey('campaign-node-$id'),
            borderRadius: BorderRadius.circular(16),
            onTap: isOpen ? () => openLevel(id) : null,
            onLongPress: isOpen ? () => showDetails(id) : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MapPin(
                  number: number,
                  state: state,
                  size: 52,
                  strongOutline: true,
                  reducedMotion: save.settings['reduceMotion'] == true,
                  onTap: isOpen ? () => openLevel(id) : null,
                ),
                const SizedBox(height: 2),
                Container(
                  width: nodeWidth - 4,
                  height: 24,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: GameColors.night.withValues(alpha: .84),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: GameColors.sand.withValues(alpha: .45),
                      width: .7,
                    ),
                  ),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: GameColors.paper,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          builder: (context, child) {
            final stagger = index * 40 / 520;
            final progress = _reducedMotion
                ? 1.0
                : ((_entrance.value - stagger) / (1 - stagger))
                      .clamp(0, 1)
                      .toDouble();
            final value = GameMotion.popIn.transform(progress);
            return Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 9),
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }

  MapPinState _stateFor(String id) {
    if (save.completedLevelIds.contains(id)) {
      return MapPinState.completed;
    }
    if (save.unlockedLevelIds.contains(id)) return MapPinState.available;
    return MapPinState.locked;
  }
}

List<Offset> _pathPoints(int count) {
  const xPositions = <double>[.23, .77, .30, .72, .24];
  if (count == 1) return const [Offset(.5, .5)];
  return List.generate(
    count,
    (i) => Offset(xPositions[i % xPositions.length], (i + .5) / count),
  );
}

class _ChapterBackdropPainter extends CustomPainter {
  const _ChapterBackdropPainter(this.seed);
  final int seed;
  @override
  void paint(Canvas canvas, Size size) =>
      MarsTerrain.paintBackdrop(canvas, size, seed: seed);
  @override
  bool shouldRepaint(covariant _ChapterBackdropPainter oldDelegate) =>
      seed != oldDelegate.seed;
}

class _WindingPathPainter extends CustomPainter {
  _WindingPathPainter({
    required this.points,
    required this.completedSegments,
    required this.nextSegment,
    required this.phase,
    required this.routeAnimation,
  }) : super(repaint: routeAnimation);
  final List<Offset> points;
  final Set<int> completedSegments;
  final int? nextSegment;
  final double phase;
  final Animation<double> routeAnimation;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final pointsInPixels = [
      for (final point in points)
        Offset(point.dx * size.width, point.dy * size.height),
    ];
    for (var i = 0; i < pointsInPixels.length - 1; i++) {
      final start = pointsInPixels[i];
      final end = pointsInPixels[i + 1];
      final middleY = (start.dy + end.dy) / 2;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(start.dx, middleY, end.dx, middleY, end.dx, end.dy);
      canvas.drawPath(
        path,
        Paint()
          ..color = GameColors.ink.withValues(alpha: .36)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round,
      );
      if (completedSegments.contains(i)) {
        canvas.drawPath(
          path,
          Paint()
            ..color = GameColors.tealLight.withValues(alpha: .34)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 9
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = GameColors.tealLight
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round,
        );
      } else if (nextSegment == i) {
        canvas.drawPath(
          path,
          Paint()
            ..color = GameColors.sand.withValues(alpha: .48)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round,
        );
        _drawDashed(
          canvas,
          path,
          GameColors.tealLight,
          routeAnimation.value * 18,
        );
      } else {
        _drawDashed(canvas, path, GameColors.muted.withValues(alpha: .76), 0);
      }
    }
  }

  void _drawDashed(Canvas canvas, Path path, Color color, double offset) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      final spacing = 15.0;
      for (var start = -offset; start < metric.length; start += spacing) {
        final from = math.max(0.0, start).toDouble();
        final to = math.min(metric.length, start + 7).toDouble();
        if (to > from) {
          canvas.drawPath(metric.extractPath(from, to), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WindingPathPainter oldDelegate) =>
      points != oldDelegate.points ||
      completedSegments != oldDelegate.completedSegments ||
      nextSegment != oldDelegate.nextSegment ||
      phase != oldDelegate.phase;
}

IconData _chapterIcon(int index) => const [
  Icons.bolt_rounded,
  Icons.cloud_rounded,
  Icons.spa_rounded,
  Icons.shield_rounded,
  Icons.groups_rounded,
][index % 5];
