import 'package:flutter/material.dart';

import '../data/models/data_class.dart';

class DataClassChip extends StatelessWidget {
  const DataClassChip(this.dataClass, {super.key});

  final DataClass dataClass;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${dataClass.label} information',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        dataClass.label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    ),
  );
}
