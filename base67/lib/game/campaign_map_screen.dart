import 'package:flutter/material.dart';

import '../app/campaign_save.dart';
import '../data/repositories/game_data_repository.dart';
import '../ui/game_widgets.dart';
import '../ui/theme.dart';

class CampaignMapScreen extends StatelessWidget {
  const CampaignMapScreen({
    super.key,
    required this.save,
    required this.repository,
    required this.openLevel,
  });

  final CampaignSave save;
  final GameDataRepository repository;
  final ValueChanged<String> openLevel;

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
    final width = MediaQuery.sizeOf(context).width;
    final nextId = levels
        .where(
          (level) =>
              save.unlockedLevelIds.contains(level['id']) &&
              !save.completedLevelIds.contains(level['id']),
        )
        .map((level) => level['id'] as String)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Campaign Map')),
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
              Text(
                'One base. Fifteen missions.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                '${save.completedLevelIds.length} of ${levels.length} missions completed · Your progress stays with your base.',
              ),
              const SizedBox(height: 12),
              const DaveBubble(
                message: 'Follow the path at your own pace. Locked missions open as you complete the earlier goals.',
              ),
              const SizedBox(height: 16),
              for (
                var chapterIndex = 0;
                chapterIndex < chapters.length;
                chapterIndex++
              ) ...[
                _ChapterSection(
                  title: chapters[chapterIndex]['name'] as String? ?? 'Chapter',
                  chapterIndex: chapterIndex,
                  levelIds:
                      (chapters[chapterIndex]['level_ids'] as List?)
                          ?.cast<String>() ??
                      const [],
                  levels: levels,
                  save: save,
                  nextLevelId: nextId,
                  wide: width >= 720,
                  openLevel: openLevel,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterSection extends StatelessWidget {
  const _ChapterSection({
    required this.title,
    required this.chapterIndex,
    required this.levelIds,
    required this.levels,
    required this.save,
    required this.nextLevelId,
    required this.wide,
    required this.openLevel,
  });

  final String title;
  final int chapterIndex;
  final List<String> levelIds;
  final List<Map<String, dynamic>> levels;
  final CampaignSave save;
  final String? nextLevelId;
  final bool wide;
  final ValueChanged<String> openLevel;

  @override
  Widget build(BuildContext context) => InfoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _chapterColor(chapterIndex).withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                _chapterIcon(chapterIndex),
                color: _chapterColor(chapterIndex),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CHAPTER ${chapterIndex + 1} · $title',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < levelIds.length; index++)
          _LevelRow(
            level: levels.firstWhere((item) => item['id'] == levelIds[index]),
            number:
                levels.indexWhere((item) => item['id'] == levelIds[index]) + 1,
            state: _stateFor(levelIds[index]),
            offset: wide && index.isOdd ? 36 : 0,
            open: save.unlockedLevelIds.contains(levelIds[index]),
            highlighted: levelIds[index] == nextLevelId,
            onTap: () => openLevel(levelIds[index]),
          ),
      ],
    ),
  );

  MapPinState _stateFor(String id) {
    if (save.completedLevelIds.contains(id)) {
      final result = save.levelResults[id];
      if (result is Map && result['stars'] == 3) return MapPinState.mastered;
      return MapPinState.completed;
    }
    if (save.unlockedLevelIds.contains(id)) return MapPinState.available;
    return MapPinState.locked;
  }

  Color _chapterColor(int index) => const [
    GameColors.rust,
    GameColors.colorBlindSafeBlue,
    GameColors.teal,
    Color(0xFF7553A6),
    Color(0xFF8A6B2F),
  ][index % 5];

  IconData _chapterIcon(int index) => const [
    Icons.bolt_rounded,
    Icons.cloud_rounded,
    Icons.spa_rounded,
    Icons.shield_rounded,
    Icons.groups_rounded,
  ][index % 5];
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.level,
    required this.number,
    required this.state,
    required this.offset,
    required this.open,
    required this.highlighted,
    required this.onTap,
  });

  final Map<String, dynamic> level;
  final int number;
  final MapPinState state;
  final double offset;
  final bool open;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: offset, bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MapPin(
          number: number,
          state: state,
          label: level['name'] as String?,
          onTap: open ? onTap : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Material(
            color: highlighted
                ? GameColors.tealLight.withValues(alpha: .4)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: open ? onTap : null,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level['name'] as String? ?? 'Mission $number',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      open
                          ? (level['mission_objective'] as String? ?? '')
                          : 'Complete the earlier mission to unlock this goal.',
                    ),
                    if (highlighted)
                      const Text(
                        'NEXT GOAL',
                        style: TextStyle(
                          color: GameColors.teal,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
