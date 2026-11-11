import 'dart:convert';

import '../app/campaign_save.dart';
import 'mars_base_painter.dart';

/// Read-only projection; never infers stock, installations or elapsed job time.
List<MarsFacility> settlementFacilities(CampaignSave save) {
  final p = save.progressionJson == null
      ? const <String, dynamic>{}
      : jsonDecode(save.progressionJson!) as Map<String, dynamic>;
  final counts = p['facilities'] as Map?;
  final damage = p['damagedUnits'] as Map? ?? const {};
  final states = p['operatingStates'] as Map? ?? const {};
  final jobs = (p['jobs'] as Map? ?? const {}).values.whereType<Map>();
  return [
    for (final site in SettlementLayout.facilities(
      save.buildingLevels,
      unlocked: save.unlockedLevelIds,
    ))
      (() {
        final job = jobs
            .where(
              (j) =>
                  j['status'] == 'active' &&
                  (j['recipe'] as Map)['targetId'] == site.canonicalId,
            )
            .firstOrNull;
        final clock = job?['clock'] as Map?;
        final duration = clock?['durationMicros'] as num?;
        final remaining = clock?['remainingMicros'] as num?;
        return MarsFacility(
          site.id,
          site.label,
          site.position,
          level: site.level,
          available: site.available,
          referenceOnly: site.referenceOnly,
          installedUnits: (counts?[site.canonicalId] as int?) ?? site.count,
          damagedUnits: damage[site.canonicalId] as int? ?? 0,
          operatingState: states[site.canonicalId] as String?,
          jobLabel: job == null
              ? null
              : (job['recipe'] as Map)['kind'] as String,
          jobProgress: duration != null && duration > 0 && remaining != null
              ? (1 - remaining / duration).clamp(0, 1).toDouble()
              : null,
        );
      })(),
  ];
}
