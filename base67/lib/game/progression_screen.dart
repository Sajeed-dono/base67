import 'package:flutter/material.dart';

import '../app/campaign_controller.dart';
import '../data/models/data_class.dart';
import '../data/repositories/game_data_repository.dart';
import '../progression/progression_service.dart';
import '../ui/game_widgets.dart';
import '../ui/theme.dart';

/// Presentation of existing recipes and jobs, without a parallel job system.
class ProgressionScreen extends StatefulWidget {
  const ProgressionScreen({super.key, required this.controller,
    required this.repository, this.research = false});
  final CampaignController controller;
  final GameDataRepository repository;
  final bool research;
  @override
  State<ProgressionScreen> createState() => _ProgressionScreenState();
}

class _ProgressionScreenState extends State<ProgressionScreen> {
  bool _busy = false;
  String? _message;
  CampaignController get c => widget.controller;

  Future<void> _perform(Future<String> Function() command) async {
    if (_busy) { return; }
    setState(() => _busy = true);
    try {
      final result = await command();
      if (mounted) { setState(() => _message = result.replaceAll('_', ' ')); }
    } catch (_) {
      if (mounted) { setState(() => _message = 'Save failed. Reopen BASE 67 before continuing.'); }
    } finally {
      if (mounted) { setState(() => _busy = false); }
    }
  }

  String _benefit(String id, String kind) => kind == 'research'
      ? 'Optional research: ${(c.missions.config.researchBonuses[id] ?? {}).entries.map((e) => '${e.key.replaceAll('_', ' ')} ${(e.value * 100).toStringAsFixed(0)}%').join(', ')}. These are game bonuses; no mission requires this timer.'
      : kind == 'major_repair' ? 'Restores one damaged installed unit. Spare parts are consumed through the existing repair recipe. An assigned Engineer uses the configured repair-time bonus; the checklist uses normal time.'
      : kind == 'upgrade' ? 'Applies the configured upgrade tier to existing units. Research and upgrade bonuses on the same stat add together.'
      : switch (id) {
        'solar_array' => 'Adds one installed solar unit. Only daylight makes electricity.',
        'battery_bank' => 'Adds storage capacity, not free charge. Charge it with daylight generation.',
        'greenhouse' => 'Adds food and oxygen production when its lights receive power. Also adds a power load.',
        'life_support_module' => 'Expands oxygen storage capacity; does not fill it or generate oxygen.',
        'radiation_shelter' => 'Installed shielding reduces the game radiation dose. Use the shelter procedure when warned.',
        'ice_miner_water_storage' => 'Powered extraction uses the site game yield and expands water capacity. Finding ice is not the same as extracting it.',
        'food_storage' => 'Expands food storage; it does not create or refill food.',
        'mission_control_hub' => 'Supports the final coordination milestone: review forecasts, crew and resource plans.',
        _ => 'Adds this facility to your persistent base. Review its catalogue role before confirming.',
      };

  Future<void> _confirm(ProgressionRecipe recipe) async {
    final assigned = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Confirm crew plan'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          GameCopy(_benefit(recipe.targetId, recipe.kind)),
          const SizedBox(height: GameSpacing.md),
          GameCopy('Cost: ${recipe.cost.isEmpty ? 'no resource cost' : recipe.cost.entries.map((e) => '${e.value} ${e.key}').join(', ')}'),
          GameCopy('Duration: ${recipe.duration.inSeconds} seconds, real time. Crew: ${recipe.crewRole}.'),
          if (recipe.kind == 'major_repair') GameCopy('With Engineer: ${(recipe.duration.inSeconds * c.migration.config.repairDurationMultiplier).ceil()} seconds. Parts cost is unchanged.'),
          GameCopy('Requires facilities: ${recipe.buildings.isEmpty ? 'none' : recipe.buildings.join(', ')}. Research: ${recipe.research.isEmpty ? 'none' : recipe.research.join(', ')}.'),
          const DataChip(DataClass.game),
          const SizedBox(height: GameSpacing.md),
          const GameCopy('Engineer votes: check the power budget. Scientist votes: compare the benefit. Medic votes: protect the crew reserve. Commander, you decide.'),
          const GameCopy('You can keep planning or return to base while this job runs. Cancelling an active job refunds the configured ordinary fraction; time is lost.'),
        ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep planning')),
        TextButton(onPressed: () => Navigator.pop(context, ''), child: const Text('Use checklist')),
        TextButton(onPressed: c.progression.crewAssignments.containsKey(recipe.crewRole) ? null
          : () => Navigator.pop(context, recipe.crewRole), child: Text('Assign ${recipe.crewRole}'))],
    ));
    if (assigned == null || !mounted) { return; }
    // IDs derive from the retained job ledger. No timestamp/random ID dependency.
    var serial = c.progression.jobs.length;
    var id = 'mission:${recipe.kind}:${recipe.targetId}:$serial';
    while (c.progression.jobs.containsKey(id) || c.progression.completedActivityIds.contains(id)) {
      id = 'mission:${recipe.kind}:${recipe.targetId}:${++serial}';
    }
    await _perform(() => c.startMissionJob(jobId: id, kind: recipe.kind,
      targetId: recipe.targetId, crewId: assigned.isEmpty ? null : assigned));
  }

  Future<void> _cancel(ProgressionJob job) async {
    final accepted = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Cancel this job?'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        GameCopy('Active work loses time and returns ${(c.migration.config.refundFraction * 100).toStringAsFixed(0)}% of ordinary payments, rounded down for whole items. Restricted assistance returns to its own entitlement. Uninstalled reserved cargo returns once. Unpaid queued work refunds nothing. A due completion happens first.'),
        const DataChip(DataClass.game),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep job')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel job'))],
    ));
    if (accepted == true && mounted) { await _perform(() => c.cancel(job.id)); }
  }

  @override
  Widget build(BuildContext context) {
    final runtime = c.missions, p = c.progression;
    final frontier = runtime.order(p.levelId);
    final researchVisible = frontier >= (runtime.rules['research_from_level'] as int);
    final recipes = c.migration.config.recipes.values.where((r) =>
      (widget.research ? r.kind == 'research' : const {'construction','upgrade','major_repair'}.contains(r.kind)) &&
      runtime.order(r.levelId) <= frontier &&
      (r.kind != 'upgrade' || (p.facilities[r.targetId] ?? 0) > 0 && (p.upgradeTiers[r.targetId] ?? 0) == 0) &&
      (r.kind != 'major_repair' || (p.damagedUnits[r.targetId] ?? 0) > 0));
    final rows = (widget.repository.document(widget.research ? 'research.json' : 'buildings.json')![widget.research ? 'projects' : 'buildings'] as List).cast<Map<String, dynamic>>();
    String name(String id) => rows.where((r) => r['id'] == id).firstOrNull?['name'] as String? ?? id.replaceAll('_', ' ');
    return Scaffold(appBar: AppBar(title: Text(widget.research ? 'Research' : 'Build')),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: GameSpacing.contentMaxWidth),
        child: ListView(padding: const EdgeInsets.all(GameSpacing.page), children: [
          const GameCopy('Your base stays with you. Jobs use real time; survival supplies change only when you advance simulation.'),
          if (widget.research && !researchVisible) ...[
            const SizedBox(height: GameSpacing.md),
            const GameCopy('Research planning is introduced with the greenhouse. Your existing research is retained.'),
          ] else ...[
            const SizedBox(height: GameSpacing.md),
            GameCopy('Materials available: ${p.materials.toStringAsFixed(0)}'), const DataChip(DataClass.game),
            if (!widget.research) GameButton(label: 'Request required recovery',
              secondary: true, onPressed: _busy ? null : () => _perform(() => c.recover())),
            for (final recipe in recipes) ...[
              const SizedBox(height: GameSpacing.md),
              InfoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GameCopy('${name(recipe.targetId)} • ${recipe.kind.replaceAll('_', ' ')}', style: Theme.of(context).textTheme.titleMedium),
                GameCopy(_benefit(recipe.targetId, recipe.kind)),
                if (!widget.research) GameCopy('Installed: ${p.facilities[recipe.targetId] ?? 0}. Packed: ${p.packedStock[c.migration.config.stockEquipment[recipe.targetId]] ?? 0}. Limit: ${c.migration.config.maxUnits[recipe.targetId] ?? 1}.'),
                GameCopy('Cost: ${recipe.cost.isEmpty ? 'no resources' : recipe.cost.entries.map((e) => '${e.value} ${e.key}').join(', ')}. Duration: ${recipe.duration.inSeconds} seconds.'),
                const DataChip(DataClass.game),
                if (widget.research && p.completedResearch.contains(recipe.targetId)) const GameCopy('Completed; bonus retained.')
                else GameButton(label: 'Review plan', onPressed: _busy ? null : () => _confirm(recipe)),
              ])),
            ],
          ],
          const SizedBox(height: GameSpacing.lg),
          GameCopy('Crew jobs', style: Theme.of(context).textTheme.titleMedium),
          for (final job in p.jobs.values.where((j) => !const {'cancelled','completed'}.contains(j.status))) ...[
            const SizedBox(height: GameSpacing.md),
            InfoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GameCopy('${job.recipe.targetId.replaceAll('_', ' ')}: ${job.status}'),
              GameCopy('Crew: ${job.crewId ?? 'unassigned'}; ${job.clock?.remaining.inSeconds ?? job.recipe.duration.inSeconds} seconds remain at last check.'),
              const DataChip(DataClass.game),
              if (job.blockReason != null) GameCopy(job.blockReason!.replaceAll('_', ' ')),
              if (job.status != 'active') GameButton(label: 'Try activation', onPressed: _busy ? null : () => _perform(() => c.activate(job.id))),
              GameButton(label: 'Cancel job', secondary: true, onPressed: _busy ? null : () => _cancel(job)),
            ])),
          ],
          GameButton(label: 'Check job completion', onPressed: _busy ? null : () => _perform(() async {
            await c.reconcile(); return 'Timers checked. Simulation time unchanged.';
          })),
          if (_message != null) RadioBubble(speaker: 'Mission Control', message: _message!),
          const SizedBox(height: GameSpacing.md),
          const DaveBubble(message: 'While jobs run, review your mission forecast, compare reserves, consult crew, or practise power planning. No optional research timer blocks a goal.'),
        ]),
      ))));
  }
}
