import 'package:flutter/material.dart';

import '../data/models/data_class.dart';
import 'data_class_chip.dart';
import 'theme.dart';

class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
    return secondary
        ? OutlinedButton(onPressed: onPressed, child: child)
        : FilledButton(onPressed: onPressed, child: child);
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.child, this.padding = 16});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: EdgeInsets.all(padding), child: child),
  );
}

/// Angular, high-contrast panel used by the Home Base and Campaign Map.
class MarsPanel extends StatelessWidget {
  const MarsPanel({super.key, required this.child, this.padding = 16});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Material(
    color: GameColors.paper,
    elevation: 4,
    shadowColor: GameColors.ink.withValues(alpha: .3),
    shape: BeveledRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: GameColors.ink, width: 2),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: EdgeInsets.all(padding), child: child),
  );
}

enum MapPinState { locked, available, completed, mastered }

class MapPin extends StatelessWidget {
  const MapPin({
    super.key,
    required this.number,
    required this.state,
    this.label,
    this.onTap,
    this.size = 56,
    this.strongOutline = false,
  });

  final int number;
  final MapPinState state;
  final String? label;
  final VoidCallback? onTap;
  final double size;
  final bool strongOutline;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      MapPinState.locked => GameColors.muted,
      MapPinState.available => GameColors.teal,
      MapPinState.completed => GameColors.colorBlindSafeBlue,
      MapPinState.mastered => GameColors.gold,
    };
    final icon = switch (state) {
      MapPinState.locked => Icons.lock_rounded,
      MapPinState.available => Icons.play_arrow_rounded,
      MapPinState.completed => Icons.check_rounded,
      MapPinState.mastered => Icons.star_rounded,
    };
    return Semantics(
      button: onTap != null,
      label: label == null
          ? 'Level $number, ${state.name}'
          : 'Level $number, $label, ${state.name}',
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: color,
          shape: CircleBorder(
            side: strongOutline
                ? const BorderSide(color: GameColors.ink, width: 3)
                : BorderSide.none,
          ),
          elevation: state == MapPinState.available ? 4 : 1,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                state == MapPinState.locked
                    ? Icon(icon, color: Colors.white, size: 21)
                    : Text(
                        '$number',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                if (state != MapPinState.locked)
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(icon, size: 12, color: color),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProgressPath extends StatelessWidget {
  const ProgressPath({super.key, required this.states, this.nodeSize = 52});

  final List<MapPinState> states;
  final double nodeSize;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < states.length; index++) ...[
        MapPin(number: index + 1, state: states[index], size: nodeSize),
        if (index < states.length - 1)
          Container(
            width: 4,
            height: 24,
            color: states[index] == MapPinState.locked
                ? GameColors.outline
                : GameColors.tealLight,
          ),
      ],
    ],
  );
}

class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.stars, this.total = 3});

  final int stars;
  final int total;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$stars of $total stars',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_border_rounded,
            color: GameColors.gold,
            size: 26,
          ),
      ],
    ),
  );
}

class DataChip extends StatelessWidget {
  const DataChip(this.dataClass, {super.key});

  final DataClass dataClass;

  @override
  Widget build(BuildContext context) => DataClassChip(dataClass);
}

class FactCard extends StatelessWidget {
  const FactCard({
    super.key,
    required this.title,
    required this.body,
    required this.dataClass,
  });

  final String title;
  final String body;
  final DataClass dataClass;

  @override
  Widget build(BuildContext context) => InfoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(body, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
        DataChip(dataClass),
      ],
    ),
  );
}

class DaveBubble extends StatelessWidget {
  const DaveBubble({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => _MessageBubble(
    label: 'DAVE',
    icon: Icons.smart_toy_outlined,
    message: message,
    color: GameColors.colorBlindSafeBlue.withValues(alpha: 0.10),
  );
}

class RadioBubble extends StatelessWidget {
  const RadioBubble({super.key, required this.speaker, required this.message});
  final String speaker;
  final String message;

  @override
  Widget build(BuildContext context) => _MessageBubble(
    label: speaker,
    icon: Icons.graphic_eq_rounded,
    message: message,
    color: GameColors.sand.withValues(alpha: 0.35),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.label,
    required this.icon,
    required this.message,
    required this.color,
  });
  final String label;
  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(GameRadii.card),
      border: Border.all(color: GameColors.outline),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: GameColors.teal),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(message, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    ),
  );
}

class GaugeBar extends StatelessWidget {
  const GaugeBar({
    super.key,
    required this.label,
    required this.value,
    this.color = GameColors.teal,
    this.trailing,
  });

  final String label;
  final double value;
  final Color color;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text(label)),
          if (trailing != null) Text(trailing!),
        ],
      ),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          minHeight: 12,
          value: value.clamp(0, 1),
          color: color,
          backgroundColor: GameColors.outline.withValues(alpha: 0.45),
        ),
      ),
    ],
  );
}

class ModalSheet extends StatelessWidget {
  const ModalSheet({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ModalSheet(title: title, child: child),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    ),
  );
}

class TimerCard extends StatelessWidget {
  const TimerCard({
    super.key,
    required this.activity,
    required this.deadlineUtc,
    required this.outcome,
    this.nowUtc,
  });

  final String activity;
  final DateTime deadlineUtc;
  final String outcome;
  final DateTime? nowUtc;

  @override
  Widget build(BuildContext context) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final remaining = deadlineUtc.toUtc().difference(now);
    final minutes = remaining.isNegative ? 0 : remaining.inMinutes;
    final timeLabel = minutes >= 60
        ? '${minutes ~/ 60} hr ${minutes % 60} min'
        : '$minutes min';
    return InfoCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.hourglass_bottom_rounded,
            color: GameColors.teal,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  remaining.isNegative
                      ? 'Ready to complete'
                      : '$timeLabel remaining',
                ),
                const SizedBox(height: 4),
                Text('When done: $outcome'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ResourceCard extends StatelessWidget {
  const ResourceCard({
    super.key,
    required this.name,
    required this.amount,
    required this.capacity,
    required this.change,
    this.dataClass = DataClass.game,
  });

  final String name;
  final double amount;
  final double capacity;
  final String change;
  final DataClass dataClass;

  @override
  Widget build(BuildContext context) => InfoCard(
    padding: 12,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          '${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 1)} / ${capacity.toStringAsFixed(0)}',
        ),
        const SizedBox(height: 6),
        GaugeBar(label: change, value: capacity <= 0 ? 0 : amount / capacity),
        const SizedBox(height: 6),
        DataChip(dataClass),
      ],
    ),
  );
}

class BuildingCard extends StatelessWidget {
  const BuildingCard({
    super.key,
    required this.name,
    required this.level,
    required this.state,
    this.upgrade,
    this.progress,
    this.onTap,
  });

  final String name;
  final int level;
  final String state;
  final String? upgrade;
  final double? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InfoCard(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GameRadii.card),
      child: Row(
        children: [
          const Icon(Icons.domain_rounded, size: 30, color: GameColors.rust),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text(level > 0 ? 'Level $level · $state' : state),
                if (upgrade != null) Text('Next upgrade: $upgrade'),
                if (progress != null) ...[
                  const SizedBox(height: 8),
                  GaugeBar(label: 'Build progress', value: progress!),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

class ResearchCard extends StatelessWidget {
  const ResearchCard({
    super.key,
    required this.name,
    required this.prerequisites,
    required this.state,
    this.progress,
    this.onTap,
  });

  final String name;
  final String prerequisites;
  final String state;
  final double? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InfoCard(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GameRadii.card),
      child: Row(
        children: [
          const Icon(Icons.science_rounded, size: 30, color: GameColors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text('$state · $prerequisites'),
                if (progress != null) ...[
                  const SizedBox(height: 8),
                  GaugeBar(label: 'Research progress', value: progress!),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

class CrewAssignmentCard extends StatelessWidget {
  const CrewAssignmentCard({
    super.key,
    required this.name,
    required this.role,
    required this.task,
    required this.status,
    this.duration,
  });

  final String name;
  final String role;
  final String task;
  final String status;
  final String? duration;

  @override
  Widget build(BuildContext context) => InfoCard(
    padding: 12,
    child: Row(
      children: [
        CrewRoleIcon(role: role),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleSmall),
              Text(
                '$role · $task · $status${duration == null ? '' : ' · $duration'}',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class CrewRoleIcon extends StatelessWidget {
  const CrewRoleIcon({super.key, required this.role});
  final String role;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    backgroundColor: GameColors.sand,
    foregroundColor: GameColors.ink,
    child: Icon(switch (role.toLowerCase()) {
      'commander' => Icons.star_rounded,
      'engineer' => Icons.build_rounded,
      'scientist' => Icons.science_rounded,
      'medic' => Icons.health_and_safety_rounded,
      _ => Icons.person_rounded,
    }),
  );
}
