import 'package:flutter/material.dart';

import '../app/campaign_controller.dart';
import '../data/models/data_class.dart';
import '../ui/game_widgets.dart';
import '../ui/theme.dart';

class CertificateScreen extends StatelessWidget {
  const CertificateScreen({super.key, required this.controller});
  final CampaignController controller;
  @override
  Widget build(BuildContext context) {
    final complete = controller.save.completedLevelIds.containsAll(controller.missions.levels);
    return Scaffold(appBar: AppBar(title: const Text('Campaign certificate')),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: GameSpacing.contentMaxWidth),
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(GameSpacing.page), children: [
          FactCard(title: complete ? 'Campaign Completed' : 'Keep exploring',
            body: complete ? controller.missions.operations['certificate'] as String
              : 'Complete every campaign level to unlock your BASE 67 certificate.',
            dataClass: DataClass.game),
          if (complete) ...[
            const SizedBox(height: GameSpacing.lg),
            GameCopy(controller.save.playerDisplayName ?? controller.save.crewNames['Commander'] ?? 'Junior astronaut'),
            const GameCopy('You completed the BASE 67 game campaign. This is a game completion certificate, not NASA accreditation or a medical or engineering qualification.'),
          ],
        ]),
      ))));
  }
}
