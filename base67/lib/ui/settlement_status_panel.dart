import 'package:flutter/material.dart';

import '../data/models/data_class.dart';
import '../progression/progression_service.dart';
import '../sim/sim_state.dart';
import 'game_widgets.dart';
import 'theme.dart';

/// Read-only HUD. Values come from the canonical world, not a second model or
/// the unsaved forecast. This widget cannot advance either game clock.
class SettlementStatusPanel extends StatelessWidget {
  const SettlementStatusPanel({
    super.key,
    required this.world,
    this.generationKw,
    this.showStorage = true,
    this.showReserves = true,
  });
  final SimState world;
  final double? generationKw;
  final bool showStorage, showReserves;

  @override
  Widget build(BuildContext context) => MissionControlPanel(
    child: Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settlement telemetry',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: GameSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= GameSpacing.telemetryWide
                  ? 4
                  : 2;
              final width =
                  (constraints.maxWidth - GameSpacing.sm * (columns - 1)) /
                  columns;
              final entries = <(IconData, String, String)>[
                (
                  Icons.wb_sunny_outlined,
                  'Solar observed',
                  generationKw == null
                      ? '—'
                      : '${generationKw!.toStringAsFixed(2)} kW',
                ),
                if (showStorage)
                  (
                    Icons.battery_charging_full,
                    'Stored energy',
                    '${world.resources['battery_kwh']!.quantity.toStringAsFixed(1)} kWh',
                  ),
                if (showReserves) ...[
                  (
                    Icons.air,
                    'Oxygen',
                    '${world.resources['oxygen_kg']!.quantity.toStringAsFixed(1)} kg',
                  ),
                  (
                    Icons.water_drop_outlined,
                    'Water',
                    '${world.resources['water_kg']!.quantity.toStringAsFixed(1)} kg',
                  ),
                  (
                    Icons.restaurant_outlined,
                    'Food',
                    '${world.resources['food_kg']!.quantity.toStringAsFixed(1)} kg',
                  ),
                ],
              ];
              return Wrap(
                spacing: GameSpacing.sm,
                runSpacing: GameSpacing.md,
                children: [
                  for (final entry in entries)
                    SizedBox(
                      width: width,
                      child: Semantics(
                        label: '${entry.$2}: ${entry.$3}',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(entry.$1, size: GameIconSizes.button),
                            GameCopy(entry.$2),
                            Text(
                              entry.$3,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: GameSpacing.sm),
          const DataChip(DataClass.derived),
          if (generationKw == null)
            const GameCopy(
              'Solar output appears after a saved observation step.',
            ),
        ],
      ),
    ),
  );
}

/// Real-time progress as last reconciled by the existing controller/service.
/// Never guesses completion using DateTime.now or an old wall-clock deadline.
class SavedJobsPanel extends StatelessWidget {
  const SavedJobsPanel({super.key, required this.jobs, this.onManage});
  final Iterable<ProgressionJob> jobs;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) => InfoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Work in progress', style: Theme.of(context).textTheme.titleLarge),
        for (final job in jobs) ...[
          const SizedBox(height: GameSpacing.sm),
          GameCopy(
            '${job.recipe.targetId.replaceAll('_', ' ')} / ${job.status}',
          ),
          GameCopy(
            'Crew: ${job.crewId ?? 'checklist'}. ${job.clock?.remaining.inSeconds ?? job.recipe.duration.inSeconds} real seconds at last check.',
          ),
          if (job.clock != null)
            GaugeBar(
              label: 'Saved job progress',
              value:
                  1 -
                  job.clock!.remaining.inMicroseconds /
                      job.clock!.duration.inMicroseconds,
            ),
          if (job.blockReason != null)
            GameCopy(job.blockReason!.replaceAll('_', ' ')),
        ],
        const SizedBox(height: GameSpacing.sm),
        const DataChip(DataClass.game),
        const GameCopy(
          'Real-time work continues offline. It does not use survival supplies or advance the mission clock.',
        ),
        if (onManage != null)
          GameButton(
            label: 'Manage jobs',
            secondary: true,
            onPressed: onManage,
          ),
      ],
    ),
  );
}
