import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/campaign_controller.dart';
import '../data/repositories/game_data_repository.dart';
import '../sim/simulation_clock.dart';
import '../ui/crew_movement.dart';
import '../ui/game_widgets.dart';
import '../ui/settlement_map.dart';
import '../ui/settlement_snapshot.dart';
import '../ui/theme.dart';
import 'campaign_map_screen.dart';
import 'certificate_screen.dart';
import 'mission_screen.dart';
import 'progression_screen.dart';
import 'rewards_screen.dart';
import 'settlement_crew_screen.dart';

/// One settlement surface. Every mission/job command goes through the existing
/// controller; walking and camera movement only change presentation.
class SettlementGameScreen extends StatefulWidget {
  const SettlementGameScreen({
    super.key,
    required this.controller,
    required this.repository,
    required this.movement,
    required this.navigate,
    this.levelId,
  });
  final CampaignController controller;
  final GameDataRepository repository;
  final CrewMovement movement;
  final ValueChanged<String> navigate;
  final String? levelId;
  @override
  State<SettlementGameScreen> createState() => _SettlementGameScreenState();
}

class _SettlementGameScreenState extends State<SettlementGameScreen> {
  bool _busy = false, _overlay = false, _objectiveExpanded = true;
  Timer? _objectiveTimer;

  void _showObjective() {
    _objectiveTimer?.cancel();
    setState(() => _objectiveExpanded = true);
    _objectiveTimer = Timer(GameMotion.objectiveTimeout, () {
      if (mounted) setState(() => _objectiveExpanded = false);
    });
  }

  @override
  void dispose() {
    _objectiveTimer?.cancel();
    super.dispose();
  }

  CampaignController get c => widget.controller;
  String get _level => c.mission?['level'] as String? ?? c.progression.levelId;

  @override
  void initState() {
    super.initState();
    _objectiveTimer = Timer(GameMotion.objectiveTimeout, () {
      if (mounted) setState(() => _objectiveExpanded = false);
    });
    if (widget.levelId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_run('open', level: widget.levelId)),
      );
    }
  }

  void _notice(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _run(String action, {String? value, String? level}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final phase = c.mission?['phase'];
    try {
      final result = await c.missionAction(
        level ?? _level,
        action,
        value: value,
      );
      if (!mounted) return;
      if (!const {'saved', 'resumed'}.contains(result)) {
        _notice(switch (result) {
          'mission_in_progress' => 'Your current mission is still open. Resume it before choosing another.',
          'level_locked' => 'Complete the earlier mission first.',
          _ => result.replaceAll('_', ' '),
        });
      } else if (phase != 'debrief' && c.mission?['phase'] == 'debrief') {
        _notice(
          c.mission?['result'] == 'success'
              ? 'Mission complete! Progress and discoveries saved.'
              : 'Your crew is safe. Review the debrief and try another plan.',
        );
        setState(() => _busy = false);
        await _panel('/mission-details');
      }
    } catch (_) {
      _notice(
        'The change could not be saved. Reopen BASE 67 to recover your campaign.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _quiz() async {
    final definition = c.missions.definition(_level);
    widget.movement.input(Offset.zero);
    setState(() => _overlay = true);
    final answer = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(definition['question'] as String),
        content: SingleChildScrollView(
          child: Text(definition['lesson'] as String),
        ),
        actions: [
          for (final key in ['answer', 'alternative'])
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, definition[key] as String),
              child: Text(definition[key] as String),
            ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _overlay = false);
    if (answer != null) await _run('learn', value: answer);
  }

  Future<void> _panel(String path) async {
    if (!mounted || _overlay) return;
    if (path == '/next-mission') {
      await _run('open', level: c.progression.levelId);
      return;
    }
    if (path == '/home') return;
    if (path == '/settings') {
      widget.movement.input(Offset.zero);
      widget.navigate(path);
      return;
    }
    widget.movement.input(Offset.zero);
    setState(() => _overlay = true);
    final route = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Return to settlement',
      barrierColor: Colors.black54,
      transitionDuration: c.save.settings['reduceMotion'] == true
          ? Duration.zero
          : const Duration(milliseconds: 160),
      pageBuilder: (context, _, _) => SafeArea(
        child: Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: math.min(500, MediaQuery.sizeOf(context).width * .64),
            height: double.infinity,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: Size(
                  math.min(500, MediaQuery.sizeOf(context).width * .64),
                  MediaQuery.sizeOf(context).height,
                ),
              ),
              child: Theme(
                data: Base67Theme.missionControl(),
                child: ListenableBuilder(
                  listenable: c,
                  builder: (context, _) => switch (path) {
                    '/build' => ProgressionScreen(
                      controller: c,
                      repository: widget.repository,
                    ),
                    '/research' => ProgressionScreen(
                      controller: c,
                      repository: widget.repository,
                      research: true,
                    ),
                    '/crew' => SettlementCrewScreen(controller: c),
                    '/notebook' => NotebookScreen(
                      repository: widget.repository,
                      save: c.save,
                    ),
                    '/badges' => BadgesScreen(controller: c),
                    '/patch' => PatchScreen(controller: c),
                    '/certificate' => CertificateScreen(controller: c),
                    '/campaign' => CampaignMapScreen(
                      save: c.save,
                      repository: widget.repository,
                      progression: c.progression,
                      openLevel: (id) => Navigator.pop(context, 'level:$id'),
                    ),
                    '/mission-details' => MissionScreen(
                      controller: c,
                      repository: widget.repository,
                      levelId: _level,
                      navigate: (route) => Navigator.pop(context, route),
                    ),
                    '/pause' => Scaffold(
                      appBar: AppBar(title: const Text('Expedition paused')),
                      body: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          const Text(
                            'Movement and mission decisions are paused. Real-time construction and research keep their own clocks.',
                          ),
                          const SizedBox(height: 16),
                          GameButton(
                            label: 'Resume expedition',
                            onPressed: () => Navigator.pop(context),
                          ),
                          for (final item in const [
                            ('/campaign', 'Missions'),
                            ('/research', 'Research'),
                            ('/notebook', 'Mars Notebook'),
                            ('/badges', 'Badges'),
                            ('/patch', 'Mission Patch'),
                          ])
                            Tooltip(
                              message: item.$2,
                              child: GameButton(
                                label: item.$2,
                                secondary: true,
                                onPressed: () =>
                                    Navigator.pop(context, item.$1),
                              ),
                            ),
                          GameButton(
                            label: 'Settings',
                            secondary: true,
                            onPressed: () =>
                                Navigator.pop(context, '/settings'),
                          ),
                        ],
                      ),
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _overlay = false);
    if (route?.startsWith('level:') == true) {
      await _run('open', level: route!.substring(6));
    } else if (route == '/settings') {
      widget.navigate('/settings');
    } else if (route != null) {
      await _panel(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final save = c.save, p = c.progression, mission = c.mission;
    final world = c.missionWorld;
    final phase = mission?['phase'] as String?;
    final levels = (widget.repository.campaign['levels'] as List)
        .cast<Map<String, dynamic>>();
    final level = levels.firstWhere((row) => row['id'] == _level);
    final complete = save.completedLevelIds.containsAll(c.missions.levels);
    final missing = c.migration.config.requiredUnits.entries
        .where(
          (entry) =>
              c.missions.order(
                    c
                        .migration
                        .config
                        .recipes['construction:${entry.key}']!
                        .levelId,
                  ) <=
                  c.missions.order(_level) &&
              (p.facilities[entry.key] ?? 0) < entry.value,
        )
        .map((entry) => entry.key)
        .toList();
    final learned =
        mission != null &&
        (mission['learned'] as List).contains(
          c.missions.definition(_level)['interaction'],
        );
    final button = mission == null
        ? 'Open first mission'
        : switch (phase) {
            'briefing' => 'Review base',
            'review' => 'Make a plan',
            'planning' =>
              missing.isNotEmpty
                  ? 'Build equipment'
                  : !learned
                  ? 'Discuss lesson'
                  : 'Start mission',
            'play' => 'Advance one step',
            'debrief' =>
              mission['result'] != 'success'
                  ? 'Retry mission'
                  : complete
                  ? 'Certificate'
                  : 'Next mission',
            _ => 'Mission details',
          };
    Future<void> action() async {
      if (mission == null) {
        await _run('open');
        return;
      }
      switch (phase) {
        case 'briefing':
          await _run('review');
        case 'review':
          await _run('plan');
        case 'planning':
          if (missing.isNotEmpty) {
            await _panel('/build');
          } else if (!learned) {
            await _quiz();
          } else {
            await _run('begin');
          }
        case 'play':
          await _run('step');
        case 'debrief':
          if (mission['result'] != 'success') {
            await _run('retry');
          } else if (complete) {
            await _panel('/certificate');
          } else {
            await _run('open', level: p.levelId);
          }
        default:
          await _panel('/mission-details');
      }
    }

    final hour = SimulationClock.hourOfSol(
      world.elapsedHours,
      c.missions.config.number('sol_hours'),
    );
    return Theme(
      data: Base67Theme.missionControl(),
      child: Scaffold(
        key: const ValueKey('settlement-game'),
        backgroundColor: hour >= c.missions.config.number('daylight_hours')
            ? GameColors.marsNight
            : GameColors.marsGround,
        body: Stack(
          fit: StackFit.expand,
          children: [
            SettlementMap(
              key: const ValueKey('game-world'),
              facilities: settlementFacilities(save),
              crew: MapCrew.fromSave(save),
              movement: widget.movement,
              fullScreen: true,
              inputEnabled: !_overlay,
              reducedMotion: save.settings['reduceMotion'] == true,
              night: hour >= c.missions.config.number('daylight_hours'),
              dust: world.dust,
              storm:
                  world.activeEvents['dust_storm'] != null &&
                  world.activeEvents['dust_storm']!.endHour >
                      world.elapsedHours,
              onManage: (route) => unawaited(_panel(route)),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, bounds) {
                  final narrow = bounds.maxWidth < GameSpacing.telemetryWide;
                  final objective =
                      '${level['name']} \u2022 ${mission == null
                          ? 'Walk with the joystick. Tap a building to interact.'
                          : phase == 'debrief'
                          ? mission['message']
                          : level['mission_objective']}';
                  return Stack(
                    children: [
                      Positioned(
                        left: GameSpacing.sm,
                        top: narrow
                            ? GameSpacing.touchTarget + GameSpacing.sm
                            : GameSpacing.sm,
                        right: narrow
                            ? GameSpacing.sm
                            : GameSpacing.touchTarget * 3 + GameSpacing.md,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final counter in const [
                              (
                                'Power',
                                'battery_kwh',
                                'kWh',
                                Icons.bolt_rounded,
                              ),
                              ('Oxygen', 'oxygen_kg', 'kg', Icons.air_rounded),
                              (
                                'Water',
                                'water_kg',
                                'kg',
                                Icons.water_drop_outlined,
                              ),
                              (
                                'Food',
                                'food_kg',
                                'kg',
                                Icons.restaurant_outlined,
                              ),
                            ])
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    right: GameSpacing.xs,
                                  ),
                                  child: _WorldCounter(
                                    label: counter.$1,
                                    quantity:
                                        world.resources[counter.$2]!.quantity,
                                    unit: counter.$3,
                                    icon: counter.$4,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: GameSpacing.sm,
                        top: GameSpacing.xs,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _WorldTool(
                              'Build',
                              Icons.construction_rounded,
                              () => _panel('/build'),
                            ),
                            _WorldTool(
                              'Crew',
                              Icons.groups_rounded,
                              () => _panel('/crew'),
                            ),
                            _WorldTool(
                              'Pause',
                              Icons.pause_rounded,
                              () => _panel('/pause'),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: GameSpacing.sm,
                        top: narrow
                            ? GameSpacing.touchTarget * 2 + GameSpacing.md
                            : GameSpacing.touchTarget + GameSpacing.sm,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: bounds.maxWidth * (narrow ? .8 : .55),
                          ),
                          child: Semantics(
                            label: objective,
                            button: true,
                            onTap: _showObjective,
                            child: Material(
                              color: GameColors.hudGlass,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  GameRadii.chip,
                                ),
                                side: const BorderSide(
                                  color: GameColors.hudBorder,
                                ),
                              ),
                              child: InkWell(
                                key: const ValueKey('mission-objective'),
                                onTap: _showObjective,
                                onLongPress: () => _panel('/mission-details'),
                                borderRadius: BorderRadius.circular(
                                  GameRadii.chip,
                                ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: GameSpacing.touchTarget,
                                    minWidth: GameSpacing.touchTarget,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: GameSpacing.sm,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.flag_outlined,
                                          size: GameIconSizes.button,
                                          color: GameColors.tealLight,
                                        ),
                                        if (_objectiveExpanded) ...[
                                          const SizedBox(width: GameSpacing.xs),
                                          Flexible(
                                            child: Text(
                                              objective,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize:
                                                    GameTypography.labelMedium,
                                                color: GameColors.paper,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: GameSpacing.compact,
                        bottom: GameSpacing.compact,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: narrow
                                ? bounds.maxWidth -
                                      GameSpacing.compactJoystick -
                                      GameSpacing.xl
                                : bounds.maxWidth * .45,
                          ),
                          child: FilledButton(
                            key: const ValueKey('mission-action'),
                            style: FilledButton.styleFrom(
                              backgroundColor: GameColors.rust,
                              foregroundColor: GameColors.paper,
                              minimumSize: const Size(
                                GameSpacing.touchTarget,
                                GameSpacing.touchTarget,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: GameSpacing.compact,
                                vertical: GameSpacing.xs,
                              ),
                              textStyle: const TextStyle(
                                fontSize: GameTypography.label,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  GameRadii.chip,
                                ),
                              ),
                            ),
                            onPressed: _busy || _overlay ? null : action,
                            child: Text(
                              button,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldCounter extends StatelessWidget {
  const _WorldCounter({
    required this.label,
    required this.quantity,
    required this.unit,
    required this.icon,
  });
  final String label, unit;
  final double quantity;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: ${quantity.toStringAsFixed(1)} $unit',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GameSpacing.resourceGap,
        vertical: GameSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: GameColors.hudGlass,
        borderRadius: BorderRadius.circular(GameRadii.chip),
        border: Border.all(color: GameColors.hudBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: GameIconSizes.button, color: GameColors.tealLight),
          const SizedBox(width: GameSpacing.xs),
          Flexible(
            child: Text(
              quantity.toStringAsFixed(0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: GameTypography.labelMedium,
                fontWeight: FontWeight.bold,
                color: GameColors.paper,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _WorldTool extends StatelessWidget {
  const _WorldTool(this.label, this.icon, this.action);
  final String label;
  final IconData icon;
  final VoidCallback action;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: action,
    iconSize: GameIconSizes.button,
    icon: Icon(icon),
    style: IconButton.styleFrom(
      minimumSize: const Size(GameSpacing.touchTarget, GameSpacing.touchTarget),
      backgroundColor: GameColors.hudGlass,
      foregroundColor: GameColors.paper,
      side: const BorderSide(color: GameColors.hudBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GameRadii.chip),
      ),
    ),
  );
}
