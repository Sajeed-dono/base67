import 'package:flutter/material.dart';

import '../data/models/data_class.dart';
import 'theme.dart';

class DataClassChip extends StatelessWidget {
  const DataClassChip(this.dataClass, {super.key});

  final DataClass dataClass;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${dataClass.label} information',
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GameSpacing.sm,
        vertical: GameSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: GameBorders.subtle,
        ),
        borderRadius: BorderRadius.circular(GameRadii.chip),
      ),
      child: Text(
        dataClass.label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    ),
  );
}
