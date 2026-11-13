import 'package:flutter/material.dart';

import '../app/campaign_controller.dart';
import '../app/campaign_save.dart';
import '../data/models/data_class.dart';
import '../data/repositories/game_data_repository.dart';
import '../ui/game_widgets.dart';
import '../ui/theme.dart';

class NotebookScreen extends StatelessWidget {
  const NotebookScreen({
    super.key,
    required this.repository,
    required this.save,
  });
  final GameDataRepository repository;
  final CampaignSave save;

  @override
  Widget build(BuildContext context) {
    final cards = (repository.document('fact_cards.json')!['cards'] as List)
        .cast<Map<String, dynamic>>();
    final unlocked = cards.where(
      (card) => save.notebookFactIds.contains(card['id']),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Mars Notebook')),
      body: ListView(
        padding: const EdgeInsets.all(GameSpacing.page),
        children: [
          ColonySectionHeading(
            title: '${unlocked.length} / ${cards.length} discoveries',
            caption: 'Complete missions to collect science for your expedition. All sources are bundled for offline reading.',
            icon: Icons.menu_book_rounded,
          ),
          if (unlocked.isEmpty) ...[
            const SizedBox(height: GameSpacing.lg),
            const GameCopy(
              'Your notebook is ready. Complete First Light to discover how sunlight powers your base.',
            ),
          ],
          for (final card in unlocked) ...[
            const SizedBox(height: GameSpacing.lg),
            FactCard(
              title: card['title'] as String,
              body: card['body'] as String,
              dataClass: DataClass.game,
            ),
            if (repository.fact(card['fact_id'] as String)
                case final fact?) ...[
              const SizedBox(height: GameSpacing.sm),
              FactCard(
                title: fact.raw['label'] as String,
                body: '${fact.value} ${fact.raw['unit']}',
                dataClass: DataClass.nasa,
              ),
              for (final id in fact.sourceIds)
                if (repository.source(id) case final source?)
                  Padding(
                    padding: const EdgeInsets.only(top: GameSpacing.sm),
                    child: SelectableText(
                      '${source.raw['title']}\n${source.url}\nFact: ${fact.id} • Source: $id',
                    ),
                  ),
            ],
          ],
        ],
      ),
    );
  }
}

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key, required this.controller});
  final CampaignController controller;

  @override
  Widget build(BuildContext context) {
    final save = controller.save;
    final badges = controller.badgeDefinitions;
    return Scaffold(
      appBar: AppBar(title: const Text('Expedition badges')),
      body: ListView(
        padding: const EdgeInsets.all(GameSpacing.page),
        children: [
          ColonySectionHeading(
            title:
                '${badges.where((b) => save.badgeIds.contains(b['id'])).length} / ${badges.length} badges earned',
            caption: 'Celebrate real mission progress. Every badge is saved once with your base.',
            icon: Icons.military_tech_rounded,
          ),
          for (final badge in badges) ...[
            const SizedBox(height: GameSpacing.md),
            InfoCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    save.badgeIds.contains(badge['id'])
                        ? Icons.verified_rounded
                        : Icons.lock_outline_rounded,
                    color: save.badgeIds.contains(badge['id'])
                        ? GameColors.teal
                        : GameColors.muted,
                    size: 36,
                  ),
                  const SizedBox(width: GameSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GameCopy(
                          badge['name'] as String,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        GameCopy(
                          save.badgeIds.contains(badge['id'])
                              ? 'Earned'
                              : 'Locked',
                        ),
                        GameCopy(badge['description'] as String),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Original geometric patch, drawn with bundled Flutter shapes and icons.
class MissionPatch extends StatelessWidget {
  const MissionPatch({super.key, this.id});
  final String? id;

  @override
  Widget build(BuildContext context) {
    final parts = id?.split(':') ?? const ['orange', 'star'];
    final color = switch (parts.first) {
      'navy' => GameColors.night,
      'teal' => GameColors.teal,
      'white' => GameColors.paper,
      _ => GameColors.rust,
    };
    final ink = parts.first == 'white' ? GameColors.ink : GameColors.paper;
    final emblem = parts.length == 2 ? parts.last : 'star';
    return Semantics(
      label: 'BASE 67 ${parts.first} $emblem mission patch',
      image: true,
      child: Container(
        width: 196,
        height: 196,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: GameColors.gold, width: 5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'BASE 67',
              style: TextStyle(
                color: ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Icon(
              switch (emblem) {
                'rover' => Icons.directions_car_rounded,
                'sun' => Icons.wb_sunny_rounded,
                'habitat' => Icons.home_work_rounded,
                _ => Icons.star_rounded,
              },
              color: ink,
              size: 54,
            ),
            Text(
              'MARS CREW',
              style: TextStyle(color: ink, fontSize: 12, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class PatchScreen extends StatefulWidget {
  const PatchScreen({super.key, required this.controller});
  final CampaignController controller;
  @override
  State<PatchScreen> createState() => _PatchScreenState();
}

class _PatchScreenState extends State<PatchScreen> {
  late final TextEditingController _name;
  String _color = 'orange', _emblem = 'star';
  String? _message;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final save = widget.controller.save;
    _name = TextEditingController(
      text: save.playerDisplayName ?? save.crewNames['Commander'] ?? '',
    );
    final parts = save.missionPatchId?.split(':');
    if (parts?.length == 2) {
      _color = parts!.first;
      _emblem = parts.last;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final message = await widget.controller.selectMissionPatch(
        color: _color,
        emblem: _emblem,
        displayName: _name.text,
      );
      if (mounted) {
        setState(() => _message = message);
        FocusScope.of(context).unfocus();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Your patch could not be saved. Reopen BASE 67 to recover your save.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final unlocked = c.save.completedLevelIds.contains(c.missions.levels.first);
    final options =
        c.migration.repository.document('badges.json')!['mission_patch'] as Map;
    return Scaffold(
      appBar: AppBar(title: const Text('Mission Patch')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: GameSpacing.contentMaxWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.all(GameSpacing.page),
              children: [
                Center(child: MissionPatch(id: '$_color:$_emblem')),
                const SizedBox(height: GameSpacing.lg),
                if (!unlocked)
                  const RadioBubble(
                    speaker: 'Patch locked',
                    message: 'Complete First Light to choose a patch for your crew. This is a preview.',
                  )
                else ...[
                  const GameCopy(
                    'Make it yours. This patch also appears on your campaign certificate.',
                  ),
                  const SizedBox(height: GameSpacing.md),
                  TextField(
                    controller: _name,
                    maxLength: 40,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Certificate name (optional)',
                      helperText:
                          'Saved only on this device. A nickname is fine.',
                    ),
                    onSubmitted: (_) => _busy ? null : _save(),
                  ),
                  const SizedBox(height: GameSpacing.md),
                  const GameCopy('Patch color'),
                  Wrap(
                    spacing: GameSpacing.sm,
                    runSpacing: GameSpacing.sm,
                    children: [
                      for (final color
                          in (options['colors'] as List).cast<String>())
                        ChoiceChip(
                          label: Text(color),
                          selected: _color == color,
                          onSelected: _busy
                              ? null
                              : (_) => setState(() => _color = color),
                        ),
                    ],
                  ),
                  const SizedBox(height: GameSpacing.md),
                  const GameCopy('Emblem'),
                  Wrap(
                    spacing: GameSpacing.sm,
                    runSpacing: GameSpacing.sm,
                    children: [
                      for (final emblem
                          in (options['emblems'] as List).cast<String>())
                        ChoiceChip(
                          label: Text(emblem),
                          selected: _emblem == emblem,
                          onSelected: _busy
                              ? null
                              : (_) => setState(() => _emblem = emblem),
                        ),
                    ],
                  ),
                  const SizedBox(height: GameSpacing.lg),
                  GameButton(
                    label: 'Save patch',
                    expand: true,
                    onPressed: _busy ? null : _save,
                  ),
                ],
                if (_message != null) ...[
                  const SizedBox(height: GameSpacing.md),
                  RadioBubble(speaker: 'Mission Control', message: _message!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
