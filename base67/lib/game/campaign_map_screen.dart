import 'package:flutter/material.dart';

import '../app/campaign_save.dart';
import '../data/repositories/game_data_repository.dart';
import '../ui/game_widgets.dart';
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

class _ChapterMap extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final points = _pathPoints(levelIds.length);
    const rowHeight = _chapterRowHeight;
    final height = levelIds.length * rowHeight;
    return MarsPanel(
      child: Column(
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
                        color: GameColors.rust.withValues(alpha: .55),
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
                onTap: isOpen ? () => openLevel(id) : null,
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: nodeWidth - 4,
                height: 28,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: state == MapPinState.locked
                          ? GameColors.muted
                          : GameColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  MapPinState _stateFor(String id) {
    if (save.completedLevelIds.contains(id)) {
      final result = save.levelResults[id];
      if (result is Map && result['stars'] == 3) return MapPinState.mastered;
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

class _WindingPathPainter extends CustomPainter {
  const _WindingPathPainter({required this.points, required this.color});

  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path();
    var current = Offset(
      points.first.dx * size.width,
      points.first.dy * size.height,
    );
    path.moveTo(current.dx, current.dy);
    for (var i = 1; i < points.length; i++) {
      final next = Offset(
        points[i].dx * size.width,
        points[i].dy * size.height,
      );
      final middleY = (current.dy + next.dy) / 2;
      path.cubicTo(current.dx, middleY, next.dx, middleY, next.dx, next.dy);
      current = next;
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = GameColors.ink.withValues(alpha: .35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = GameColors.sand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _WindingPathPainter oldDelegate) =>
      points != oldDelegate.points || color != oldDelegate.color;
}

IconData _chapterIcon(int index) => const [
  Icons.bolt_rounded,
  Icons.cloud_rounded,
  Icons.spa_rounded,
  Icons.shield_rounded,
  Icons.groups_rounded,
][index % 5];
