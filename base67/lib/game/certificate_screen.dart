import 'package:flutter/material.dart';

import '../app/campaign_controller.dart';
import '../data/models/data_class.dart';
import '../ui/game_widgets.dart';
import '../ui/theme.dart';
import 'rewards_screen.dart';

class CertificateScreen extends StatelessWidget {
  const CertificateScreen({super.key, required this.controller});
  final CampaignController controller;
  @override
  Widget build(BuildContext context) {
    final complete = controller.save.completedLevelIds.containsAll(
      controller.missions.levels,
    );
    final save = controller.save;
    final name = save.playerDisplayName?.trim();
    final displayName = name != null && name.isNotEmpty
        ? name
        : save.crewNames['Commander'] ?? 'Junior astronaut';
    final result = save.levelResults[controller.missions.levels.last];
    final date = result is Map
        ? DateTime.tryParse('${result['completed_at_utc']}')?.toLocal()
        : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Campaign certificate')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: GameSpacing.contentMaxWidth,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(GameSpacing.page),
              children: [
                if (complete) ...[
                  Center(child: MissionPatch(id: save.missionPatchId)),
                  const SizedBox(height: GameSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(GameSpacing.lg),
                    decoration: BoxDecoration(
                      color: GameColors.paper,
                      border: Border.all(color: GameColors.gold, width: 3),
                      borderRadius: BorderRadius.circular(GameRadii.card),
                    ),
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        color: GameColors.ink,
                        fontSize: 16,
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'BASE 67 • MARS EXPEDITION',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: GameSpacing.lg),
                          const Text(
                            'Junior Astronaut',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: GameSpacing.md),
                          const Text('Presented to'),
                          Text(
                            displayName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: GameColors.rust,
                            ),
                          ),
                          const SizedBox(height: GameSpacing.lg),
                          const Text(
                            'One crew. One lasting base.\nAll 15 missions completed.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: GameSpacing.md),
                          Text(
                            '${save.badgeIds.length} expedition badges earned',
                            textAlign: TextAlign.center,
                          ),
                          if (date != null)
                            Text(
                              'Completed ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: GameSpacing.lg),
                ],
                FactCard(
                  title: complete ? 'Campaign Completed' : 'Keep exploring',
                  body: complete
                      ? controller.missions.operations['certificate'] as String
                      : 'Complete every campaign level to unlock your BASE 67 certificate.',
                  dataClass: DataClass.game,
                ),
                if (complete) ...[
                  const SizedBox(height: GameSpacing.lg),
                  const GameCopy(
                    'You completed the BASE 67 game campaign. This is a game completion certificate, not NASA accreditation or a medical or engineering qualification.',
                  ),
                  const SizedBox(height: GameSpacing.lg),
                  GameButton(
                    label: 'Personalize patch and name',
                    onPressed: () => Navigator.of(context).pushNamed('/patch'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
