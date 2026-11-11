import 'package:flutter/material.dart';

import '../data/models/data_class.dart';
import '../missions/mission_runtime.dart';
import '../ui/game_widgets.dart';
import '../ui/theme.dart';

/// Presentation only. All commands use the existing screens/controller, and the
/// detached forecast is never treated as an observed result or a saved step.
class PowerMissionPanel extends StatelessWidget {
  const PowerMissionPanel({
    super.key,
    required this.report,
    required this.storageLesson,
    required this.expanded,
    required this.jobs,
    required this.onBuild,
    required this.onCrew,
  });

  final PowerMissionReport report;
  final bool storageLesson, expanded;
  final List<String> jobs;
  final VoidCallback? onBuild, onCrew;

  @override
  Widget build(BuildContext context) => MissionControlPanel(
    child: Builder(
      builder: (context) => ExpansionTile(
        initiallyExpanded: expanded,
        tilePadding: EdgeInsets.zero,
        title: Text(
          'Power mission control',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: GameCopy(
          storageLesson
              ? 'Store daylight energy for the night.'
              : 'Turn sunlight into useful electricity.',
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GameCopy(
                'Live base checklist. Only saved gameplay can complete a mission.',
              ),
              const SizedBox(height: GameSpacing.sm),
              for (final objective in report.objectives)
                Padding(
                  padding: const EdgeInsets.only(bottom: GameSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        objective.$2
                            ? Icons.check_circle_outline
                            : Icons.radio_button_unchecked,
                        size: GameIconSizes.button,
                        color: objective.$2
                            ? GameColors.informationOnControl
                            : GameColors.onControlSecondary,
                      ),
                      const SizedBox(width: GameSpacing.sm),
                      Expanded(
                        child: GameCopy(
                          '${objective.$2 ? 'Done' : 'Pending'}: ${objective.$1}',
                        ),
                      ),
                    ],
                  ),
                ),
              GameCopy(
                'Working solar units: ${report.solarUnits}. Working storage units: ${report.batteryUnits}.',
              ),
              const DataChip(DataClass.game),
              if (storageLesson) ...[
                const SizedBox(height: GameSpacing.md),
                GaugeBar(
                  label:
                      'Stored energy: ${report.storedKwh.toStringAsFixed(2)} / ${report.capacityKwh.toStringAsFixed(2)} kWh',
                  value: report.capacityKwh <= 0
                      ? 0
                      : report.storedKwh / report.capacityKwh,
                  color: GameColors.informationOnControl,
                ),
                const DataChip(DataClass.derived),
                GameCopy(
                  'Game reserve floor: ${report.reserveKwh.toStringAsFixed(2)} kWh. Capacity holds energy; it does not create charge.',
                ),
                const DataChip(DataClass.game),
              ],
              const SizedBox(height: GameSpacing.md),
              GameCopy(
                'Observation: ${report.elapsedHours.toStringAsFixed(2)} / ${report.observationHours.toStringAsFixed(2)} simulation hours.',
              ),
              const Wrap(
                spacing: GameSpacing.sm,
                children: [
                  DataChip(DataClass.derived),
                  DataChip(DataClass.game),
                ],
              ),
              const SizedBox(height: GameSpacing.md),
              Text(
                'Next step / unsaved preview',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              GameCopy(
                'Over ${report.previewHours.toStringAsFixed(2)} simulation hours: solar ${report.generationKw.toStringAsFixed(2)} kW; power used ${report.demandKw.toStringAsFixed(2)} kW; ending battery ${report.projectedKwh.toStringAsFixed(2)} kWh.',
              ),
              const DataChip(DataClass.derived),
              const GameCopy(
                'This uses your current charge and load settings. It spends nothing. A preview does not count as mission evidence or guarantee the whole mission.',
              ),
              if (report.previewNeedsReview)
                GameCopy('Review before advancing: ${report.previewMessage}'),
              const SizedBox(height: GameSpacing.md),
              const GameCopy(
                'Build assigns an Engineer or uses the existing checklist. Construction uses real time; mission observations use simulation time.',
              ),
              for (final job in jobs) GameCopy(job),
              const SizedBox(height: GameSpacing.sm),
              Wrap(
                spacing: GameSpacing.sm,
                runSpacing: GameSpacing.sm,
                children: [
                  GameButton(label: 'Power build plans', onPressed: onBuild),
                  GameButton(
                    label: 'Crew assignments',
                    onPressed: onCrew,
                    secondary: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
