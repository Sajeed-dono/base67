import 'package:flutter/material.dart';

import '../app/campaign_controller.dart';
import '../data/models/data_class.dart';
import '../ui/game_widgets.dart';
import '../ui/theme.dart';

class SettlementCrewScreen extends StatelessWidget {
  const SettlementCrewScreen({super.key, required this.controller});
  final CampaignController controller;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Crew')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(GameSpacing.page),
        children: [MissionCrewPanel(controller: controller)],
      ),
    ),
  );
}

class MissionCrewPanel extends StatefulWidget {
  const MissionCrewPanel({super.key, required this.controller});
  final CampaignController controller;
  @override
  State<MissionCrewPanel> createState() => _MissionCrewPanelState();
}

class _MissionCrewPanelState extends State<MissionCrewPanel> {
  bool _busy = false;
  String? _message, _role, _action;
  Future<void> _run(String action, {String? value}) async {
    final id = widget.controller.mission?['level'] as String?;
    if (id == null || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await widget.controller.missionAction(
        id,
        action,
        value: value,
      );
      if (mounted) {
        final String? message;
        if (result == 'saved') {
          final mission = widget.controller.mission;
          message = mission?['message'] as String?;
        } else {
          message = result;
        }
        setState(() => _message = message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'The change was not saved. Reopen the campaign before continuing.',
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
    final c = widget.controller, p = c.progression;
    final runtime = c.missions;
    final session = c.mission;
    final colony = runtime.settlement(p, session);
    final order = session == null
        ? 1
        : runtime.order(session['level'] as String);
    final actions = runtime.crew.actions
        .where((a) => order >= (a['from_level'] as int))
        .toList();
    final role = _role ?? p.crewRoles.keys.first;
    final action = actions.any((a) => a['id'] == _action)
        ? _action
        : actions.firstOrNull?['id'] as String?;
    final spec = actions.where((a) => a['id'] == action).firstOrNull;
    final specialist =
        spec?['specialist'] == null || p.crewRoles[role] == spec?['specialist'];
    final hours = spec?[specialist ? 'hours' : 'backup_hours'];
    String assignmentLabel(String role) {
      final id = p.crewAssignments[role];
      final job = p.jobs[id];
      if (job != null) {
        return '${job.recipe.kind.replaceAll('_', ' ')}: ${job.recipe.targetId.replaceAll('_', ' ')}';
      }
      return id?.replaceAll('mission:', '').replaceAll('_', ' ') ??
          'Available / resting';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameCopy(
          'Crew responsibilities',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const GameCopy(
          'Commander coordinates and rallies. Engineer builds and repairs. Scientist studies weather and ice. Medic supports wellbeing and drills. Any free astronaut can use the backup checklist for a simulation task.',
        ),
        for (final r in p.crewRoles.keys) ...[
          const SizedBox(height: GameSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GameCopy(
                  '${c.save.crewNames[r] ?? r} • $r',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                GameCopy('Assignment: ${assignmentLabel(r)}'),
                if ((colony['tasks'] as Map)[r] != null) ...[
                  GameCopy(
                    '${((colony['tasks'] as Map)[r] as Map)['remaining']} simulation hours remain.',
                  ),
                  const DataChip(DataClass.game),
                  GameButton(
                    label: 'Cancel crew task',
                    secondary: true,
                    onPressed: _busy
                        ? null
                        : () => _run('cancel_crew', value: r),
                  ),
                ],
                if (order >= 13) ...[
                  for (final stat in ['health', 'morale', 'fatigue'])
                    GameCopy(
                      '$stat: ${(((colony['crew'] as Map)[r] as Map)[stat] as num).toStringAsFixed(0)} / ${runtime.crew.number('maximum').toStringAsFixed(0)}',
                    ),
                  const DataChip(DataClass.game),
                ],
              ],
            ),
          ),
        ],
        if (order >= 13) ...[
          const SizedBox(height: GameSpacing.md),
          GameCopy(
            'Comfort: ${c.missionWorld.temperature >= runtime.config.number('min_safe_temp') ? 'habitat is warm enough for the game task' : 'restore heater power; crew need warmth'}. Health means readiness, morale means confidence, and fatigue means workload. These are game indicators.',
          ),
          const DataChip(DataClass.game),
        ],
        if (session == null)
          const GameCopy(
            'Open an available mission to plan simulation activities.',
          )
        else if (actions.isNotEmpty) ...[
          const SizedBox(height: GameSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: role,
            decoration: const InputDecoration(labelText: 'Astronaut'),
            items: [
              for (final r in p.crewRoles.keys)
                DropdownMenuItem(value: r, child: Text(r)),
            ],
            onChanged: _busy ? null : (value) => setState(() => _role = value),
          ),
          const SizedBox(height: GameSpacing.sm),
          DropdownButtonFormField<String>(
            key: ValueKey('crew-actions-$order'),
            initialValue: action,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Activity'),
            items: [
              for (final a in actions)
                DropdownMenuItem(
                  value: a['id'] as String,
                  child: Text(
                    a['name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _busy
                ? null
                : (value) => setState(() => _action = value),
          ),
          GameCopy(
            'Duration: $hours simulation hours. ${specialist ? 'Role advantage applies.' : 'Backup checklist; the specialist can be faster or give stronger support.'} No resource fee; simulation still uses normal power and supplies.',
          ),
          const DataChip(DataClass.game),
          GameButton(
            label: 'Assign activity',
            onPressed: _busy || action == null
                ? null
                : () => _run('crew', value: '$role:$action'),
          ),
          const GameCopy(
            'Advance a preparation or mission step to work or rest. Unassigned astronauts rest. Simulation activities pause when the app is closed; real-time jobs keep their own clocks.',
          ),
        ],
        if ((colony['survey_sites'] as List).isNotEmpty && order >= 10) ...[
          const SizedBox(height: GameSpacing.md),
          GameCopy(
            'Survey for ${c.missionWorld.siteId}: ${runtime.config.sites[c.missionWorld.siteId]!.iceTier} GAME VALUE tier. This is evidence for a plan, not confirmation of accessible ice. A low tier needs more careful supply planning.',
          ),
          const DataChip(DataClass.game),
        ],
        if (_message != null) RadioBubble(speaker: 'Crew', message: _message!),
      ],
    );
  }
}
