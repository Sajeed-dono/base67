import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../repositories/game_data_repository.dart';

class DataCheckScreen extends StatelessWidget {
  const DataCheckScreen({super.key, required this.repository});

  final GameDataRepository repository;

  @override
  Widget build(BuildContext context) {
    assert(kDebugMode, 'Data Check is only available in debug builds.');
    if (!kDebugMode) return const SizedBox.shrink();
    final issues = repository.validate();
    return Scaffold(
      appBar: AppBar(title: const Text('Data Check')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            issues.isEmpty
                ? 'All bundled data checks passed.'
                : '${issues.length} issue(s) found.',
          ),
          for (final issue in issues)
            ListTile(
              leading: const Icon(Icons.warning_amber),
              title: Text(issue),
            ),
        ],
      ),
    );
  }
}
