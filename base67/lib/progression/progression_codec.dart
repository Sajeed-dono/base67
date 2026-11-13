part of 'progression_service.dart';

/// Schema-3 aggregate boundary. No IO, clock reads, grants or reconciliation.
/// A part shares private damage constructors without exposing a claim factory.
class ProgressionCodec {
  ProgressionCodec(this.config, {required Iterable<String> equipmentIds})
    : equipmentIds = Set.unmodifiable(equipmentIds);

  final ProgressionConfig config;
  final Set<String> equipmentIds;

  Map<String, dynamic> encode(ProgressionState state) {
    final result = <String, dynamic>{
      'levelId': state.levelId,
      'resources': state.resources,
      'pending': state.pending,
      'assistance': state.assistance,
      'packedStock': state.packedStock,
      'confirmedDamage': state.confirmedDamage,
      'damageObservations': {
        for (final e in state.damageObservations.entries)
          e.key: {'targetId': e.value.targetId, 'units': e.value.units,
            'remaining': e.value.remaining},
      },
      'operatingStates': state.operatingStates,
      'externalCrewAssignments': state.externalCrewAssignments,
      'externalFacilityReservations': state.externalFacilityReservations.toList()..sort(),
      'facilities': state.facilities,
      'upgradeTiers': state.upgradeTiers,
      'damagedUnits': state.damagedUnits,
      'crewRoles': state.crewRoles,
      'completedLevels': state.completedLevels.toList()..sort(),
      'completedResearch': state.completedResearch.toList()..sort(),
      'completedActivityIds': state.completedActivityIds.toList()..sort(),
      'jobs': {for (final e in state.jobs.entries) e.key: _job(e.value)},
      'receipts': {
        for (final e in state.receipts.entries)
          e.key: {'kind': e.value.kind, 'amount': e.value.amount,
            'targetId': e.value.targetId, 'levelId': e.value.levelId},
      },
      'log': state.log,
      'lastObservedUtc': state.lastObservedUtc?.toIso8601String(),
      'lastObservationToken': state.lastObservationToken,
    };
    decode(result); // Validate outgoing mutations with the same boundary.
    return result;
  }

  Map<String, dynamic> _job(ProgressionJob job) => {
    'id': job.id, 'recipe': {
      'kind': job.recipe.kind, 'targetId': job.recipe.targetId,
      'levelId': job.recipe.levelId, 'durationMicros': job.recipe.duration.inMicroseconds,
      'cost': job.recipe.cost, 'buildings': job.recipe.buildings.toList()..sort(),
      'research': job.recipe.research.toList()..sort(), 'crewRole': job.recipe.crewRole,
    },
    'crewId': job.crewId, 'status': job.status,
    'clock': job.clock == null ? null : {
      'startedAtUtc': job.clock!.startedAtUtc.toIso8601String(),
      'originalDeadlineUtc': job.clock!.originalDeadlineUtc.toIso8601String(),
      'durationMicros': job.clock!.duration.inMicroseconds,
      'remainingMicros': job.clock!.remaining.inMicroseconds,
      'observedAtUtc': job.clock!.observedAtUtc.toIso8601String(),
      'rollbackCount': job.clock!.rollbackCount,
      'observationToken': job.clock!.observationToken,
    },
    'finishedAtUtc': job.finishedAtUtc?.toIso8601String(),
    'recoveryId': job.recoveryId, 'repairDamageId': job.repairDamageId,
    'paid': job.paid, 'assistancePaid': job.assistancePaid,
    'reservedStock': job.reservedStock, 'blockReason': job.blockReason,
  };

  ProgressionState decode(Object? raw) {
    final row = _map(raw);
    _keys(row, {'levelId','resources','pending','assistance','packedStock',
      'confirmedDamage','damageObservations','operatingStates',
      'externalCrewAssignments','externalFacilityReservations','facilities',
      'upgradeTiers','damagedUnits','crewRoles','completedLevels',
      'completedResearch','completedActivityIds','jobs','receipts','log',
      'lastObservedUtc','lastObservationToken'});
    final observations = <String, DamageObservation>{};
    for (final e in _map(row['damageObservations']).entries) {
      final v = _map(e.value);
      _keys(v, {'targetId','units','remaining'});
      observations[e.key] = DamageObservation._(
        _string(v['targetId']), _int(v['units']), _int(v['remaining']),
      );
    }
    final jobs = <String, ProgressionJob>{};
    for (final e in _map(row['jobs']).entries) {
      final v = _map(e.value);
      _keys(v, {'id','recipe','crewId','status','clock','finishedAtUtc',
        'recoveryId','repairDamageId','paid','assistancePaid','reservedStock','blockReason'});
      final r = _map(v['recipe']);
      _keys(r, {'kind','targetId','levelId','durationMicros','cost','buildings','research','crewRole'});
      final recipe = ProgressionRecipe(
        kind: _string(r['kind']), targetId: _string(r['targetId']),
        levelId: _string(r['levelId']), duration: Duration(microseconds: _int(r['durationMicros'])),
        cost: _numbers(r['cost']), buildings: _strings(r['buildings']),
        research: _strings(r['research']), crewRole: _string(r['crewRole']),
      );
      ProgressionClock? clock;
      if (v['clock'] != null) {
        final c = _map(v['clock']);
        _keys(c, {'startedAtUtc','originalDeadlineUtc','durationMicros',
          'remainingMicros','observedAtUtc','rollbackCount','observationToken'});
        clock = ProgressionClock.restore(
          startedAtUtc: _utc(c['startedAtUtc']),
          originalDeadlineUtc: _utc(c['originalDeadlineUtc']),
          duration: Duration(microseconds: _int(c['durationMicros'])),
          remaining: Duration(microseconds: _int(c['remainingMicros'])),
          observedAtUtc: _utc(c['observedAtUtc']),
          rollbackCount: _int(c['rollbackCount']), observationToken: _int(c['observationToken']),
        );
      }
      jobs[e.key] = ProgressionJob(
        id: _string(v['id']), recipe: recipe, crewId: _optionalString(v['crewId']),
        status: _string(v['status']), clock: clock,
        finishedAtUtc: v['finishedAtUtc'] == null ? null : _utc(v['finishedAtUtc']),
        recoveryId: _optionalString(v['recoveryId']), repairDamageId: _optionalString(v['repairDamageId']),
        paid: _numbers(v['paid']), assistancePaid: _numbers(v['assistancePaid']),
        reservedStock: _ints(v['reservedStock']), blockReason: _optionalString(v['blockReason']),
      );
    }
    final receipts = <String, ProgressionReceipt>{};
    for (final e in _map(row['receipts']).entries) {
      final v = _map(e.value);
      _keys(v, {'kind','amount','targetId','levelId'});
      receipts[e.key] = ProgressionReceipt(_string(v['kind']), _number(v['amount']),
        targetId: _optionalString(v['targetId']), levelId: _optionalString(v['levelId']));
    }
    final token = row['lastObservationToken'];
    if (token is! int || token < -1) { _bad('Observation token'); }
    final state = ProgressionState(
      levelId: _string(row['levelId']), resources: _numbers(row['resources']),
      pending: _numbers(row['pending']),
      assistance: {for (final e in _map(row['assistance']).entries) e.key: _numbers(e.value)},
      packedStock: _ints(row['packedStock']), confirmedDamage: _ints(row['confirmedDamage']),
      damageObservations: observations, operatingStates: _stringMap(row['operatingStates']),
      externalCrewAssignments: _stringMap(row['externalCrewAssignments']),
      externalFacilityReservations: _strings(row['externalFacilityReservations']).toSet(),
      facilities: _ints(row['facilities']), upgradeTiers: _ints(row['upgradeTiers']),
      damagedUnits: _ints(row['damagedUnits']), crewRoles: _stringMap(row['crewRoles']),
      completedLevels: _strings(row['completedLevels']).toSet(),
      completedResearch: _strings(row['completedResearch']).toSet(),
      completedActivityIds: _strings(row['completedActivityIds']).toSet(),
      jobs: jobs, receipts: receipts, log: _strings(row['log'], unique: false),
      lastObservedUtc: row['lastObservedUtc'] == null ? null : _utc(row['lastObservedUtc']),
      lastObservationToken: token,
    );
    _validate(state);
    return state;
  }

  void _validate(ProgressionState s) {
    final service = RealTimeProgressionService(config);
    final facilities = {...config.maxUnits.keys, 'landing_craft'};
    if (!config.levels.contains(s.levelId) ||
        !config.levels.toSet().containsAll(s.completedLevels) ||
        s.completedResearch.any((id) => !config.recipes.containsKey('research:$id')) ||
        s.facilities.keys.any((id) => !facilities.contains(id)) ||
        s.packedStock.keys.any((id) => !equipmentIds.contains(id)) ||
        s.pending.keys.any((id) => id != 'materials') ||
        (s.lastObservationToken == -1) != (s.lastObservedUtc == null)) {
      _bad('Unknown identity or invalid checkpoint');
    }
    for (final e in s.resources.entries) {
      if (config.indivisible.contains(e.key) && e.value != e.value.floorToDouble()) {
        _bad('Fractional indivisible resource');
      }
    }
    if ((s.packedStock['spare_part'] ?? 0) > 0 && (s.resources['spare_part'] ?? 0) > 0) {
      _bad('Ambiguous spare ownership');
    }
    if ((s.pending['materials'] ?? 0) != (s.pending['materials'] ?? 0).floorToDouble()) {
      _bad('Fractional pending materials');
    }
    for (final e in s.facilities.entries) {
      if (e.value > (config.maxUnits[e.key] ?? 1)) { _bad('Installed unit limit'); }
    }
    if (s.crewRoles.length > 4 || s.crewRoles.values.toSet().length != s.crewRoles.length ||
        s.crewRoles.values.any((role) => !const {'Commander','Engineer','Scientist','Medic'}.contains(role))) {
      _bad('Crew role identities');
    }
    for (final e in s.upgradeTiers.entries) {
      if (e.value > 1 || (s.facilities[e.key] ?? 0) == 0 ||
          (e.value > 0 && !config.recipes.containsKey('upgrade:${e.key}'))) { _bad('Upgrade ownership'); }
    }
    for (final e in s.operatingStates.entries) {
      if (!facilities.contains(e.key) || !const {'notBuilt','underConstruction',
        'operating','damaged','off','outOfResources'}.contains(e.value) ||
          ((s.facilities[e.key] ?? 0) > 0 &&
            const {'notBuilt','underConstruction'}.contains(e.value))) { _bad('Facility lifecycle'); }
    }
    for (final id in {...s.damagedUnits.keys, ...s.damageObservations.values.map((o) => o.targetId)}) {
      if (!facilities.contains(id) || !service._damageConsistent(s, id)) { _bad('Damage accounting'); }
    }
    for (final e in s.damageObservations.entries) {
      final o = e.value, authority = config.damageOccurrences[e.key];
      if (o.units <= 0 || o.remaining > o.units) { _bad('Damage observation count'); }
      if (authority != null) {
        final receipt = s.receipts['observed:${e.key}'];
        if (o.targetId != authority.targetId || o.units != authority.units ||
            receipt?.kind != 'observed_damage' || receipt?.targetId != authority.targetId ||
            receipt?.levelId != authority.levelId || receipt?.amount != authority.units) { _bad('Damage authority'); }
      } else if (!s.jobs.values.any((j) => e.key == 'unidentified:${j.id}' &&
          j.repairDamageId == e.key && j.recipe.targetId == o.targetId && o.units == 1)) {
        _bad('Unidentified damage ownership');
      }
      if (o.remaining == 0 && s.receipts['resolved:${e.key}']?.kind != 'resolved_damage') { _bad('Damage closure'); }
      if (o.remaining > 0 && s.receipts.containsKey('resolved:${e.key}')) { _bad('Reopened damage'); }
      final completedRepairs = s.jobs.values.where((job) => job.status == 'completed' && job.repairDamageId == e.key).length;
      if (completedRepairs > o.units - o.remaining) { _bad('Repair completion accounting'); }
    }
    for (final e in s.confirmedDamage.entries) {
      final authority = config.damageOccurrences[e.key];
      final o = s.damageObservations[e.key], receipt = s.receipts['damage:${e.key}'];
      if (authority == null || o == null || e.value != o.remaining ||
          receipt?.kind != 'damage' || receipt?.amount != authority.units ||
          receipt?.targetId != authority.targetId || receipt?.levelId != authority.levelId) { _bad('Confirmation authority'); }
    }
    for (final e in s.assistance.entries) {
      final recipe = _entitlementRecipe(e.key, s);
      if (recipe == null) { _bad('Unknown entitlement'); }
      for (final credit in e.value.entries) {
        if (!recipe.cost.containsKey(credit.key) || credit.value > recipe.cost[credit.key]! ||
            (config.indivisible.contains(credit.key) && credit.value != credit.value.floorToDouble())) { _bad('Restricted credit'); }
      }
      if (e.value.values.any((v) => v > 0)) {
        final receipt = s.receipts['assistance:${e.key}'];
        if (receipt == null || receipt.kind != 'assistance' || receipt.targetId != recipe.targetId ||
            receipt.amount < e.value.values.fold(0.0, (a, b) => a + b)) { _bad('Unreceipted assistance'); }
        if (e.key.startsWith('repair:')) {
          final id = e.key.substring('repair:'.length);
          if (!service._validObservation(s, id) || (s.confirmedDamage[id] ?? 0) <= 0) { _bad('Closed repair credit'); }
        } else if ((s.facilities[recipe.targetId] ?? 0) >= config.requiredUnits[recipe.targetId]!) {
          _bad('Completed construction credit');
        }
      }
    }
    final lanes = <String>{}, targets = <String>{}, crew = <String>{};
    for (final e in s.externalCrewAssignments.entries) {
      if (!s.crewRoles.containsKey(e.key)) { _bad('External crew ownership'); }
      crew.add(e.key);
    }
    if (!facilities.containsAll(s.externalFacilityReservations)) { _bad('External target'); }
    targets.addAll(s.externalFacilityReservations);
    for (final e in s.jobs.entries) {
      final j = e.value, r = j.recipe, expected = config.recipes[j.recipe.key];
      if (j.id != e.key || expected == null ||
          r.levelId != expected.levelId || r.crewRole != expected.crewRole ||
          (r.duration != expected.duration &&
            !(config.savedRecipeDurations[r.key]?.contains(r.duration) ?? false)) ||
          !_sameMap(r.cost, expected.cost) ||
          !_sameSet(r.buildings, expected.buildings) || !_sameSet(r.research, expected.research) ||
          !const {'queued','blocked','active','completed','cancelled'}.contains(j.status)) { _bad('Job recipe/status'); }
      final unpaid = j.clock == null;
      if (unpaid) {
        if (!const {'queued','blocked','cancelled'}.contains(j.status) ||
            j.paid.isNotEmpty || j.assistancePaid.isNotEmpty || j.reservedStock.isNotEmpty ||
            j.repairDamageId != null || j.recoveryId != null) { _bad('Unpaid job owns payment'); }
      } else {
        if (const {'queued','blocked'}.contains(j.status) ||
            j.clock!.observationToken > s.lastObservationToken ||
            s.receipts['start:${j.id}']?.kind != 'start') { _bad('Job checkpoint/receipt'); }
        final base = r.duration.inMicroseconds;
        final modified = (base * config.repairDurationMultiplier).ceil();
        final expectedDuration = r.kind == 'major_repair' && j.crewId != null ? modified : base;
        if (j.clock!.duration.inMicroseconds != expectedDuration) {
          _bad('Job duration');
        }
        if (!_sameSet(j.paid.keys.toSet(), r.cost.keys.toSet()) ||
            !_sameSet(j.assistancePaid.keys.toSet(), r.cost.keys.toSet())) { _bad('Payment resource keys'); }
        for (final cost in r.cost.entries) {
          if (j.paid[cost.key]! + j.assistancePaid[cost.key]! != cost.value) { _bad('Payment split'); }
          if (config.indivisible.contains(cost.key) &&
              (j.paid[cost.key] != j.paid[cost.key]!.floorToDouble() ||
               j.assistancePaid[cost.key] != j.assistancePaid[cost.key]!.floorToDouble())) { _bad('Fractional payment'); }
        }
        if (j.assistancePaid.values.any((v) => v > 0) && j.recoveryId == null) { _bad('Assistance payment owner'); }
        if (j.assistancePaid.values.any((v) => v > 0)) {
          final receipt = s.receipts['assistance:${j.recoveryId}'];
          if (receipt == null || receipt.kind != 'assistance' || receipt.targetId != r.targetId ||
              receipt.amount < j.assistancePaid.values.fold(0.0, (a, b) => a + b)) { _bad('Unreceipted assistance payment'); }
        }
        if (j.recoveryId != null && _entitlementRecipe(j.recoveryId!, s)?.key != r.key) { _bad('Payment entitlement'); }
        if (r.kind == 'major_repair') {
          final damage = s.damageObservations[j.repairDamageId];
          if (damage == null || damage.targetId != r.targetId ||
              (j.recoveryId != null && j.recoveryId != 'repair:${j.repairDamageId}') ||
              (j.recoveryId != null && !s.confirmedDamage.containsKey(j.repairDamageId)) ||
              (j.status == 'active' && damage.remaining <= 0)) { _bad('Repair allocation'); }
        } else if (j.repairDamageId != null) { _bad('Non-repair allocation'); }
        if (j.reservedStock.isNotEmpty && (r.kind != 'construction' ||
            j.reservedStock.length != 1 ||
            j.reservedStock[config.stockEquipment[r.targetId]] != 1)) { _bad('Cargo reservation'); }
      }
      if (j.status == 'active') {
        if (!lanes.add(config.lanes[r.kind]!) || !targets.add(r.targetId) ||
            (j.crewId != null && (!s.crewRoles.containsKey(j.crewId) || !crew.add(j.crewId!))) ||
            j.finishedAtUtc != null || s.completedActivityIds.contains(j.id)) { _bad('Active concurrency/ledger'); }
      }
      if (j.status == 'completed' && (j.clock?.isDue != true || j.finishedAtUtc == null ||
          !s.completedActivityIds.contains(j.id) || s.receipts['complete:${j.id}']?.kind != 'complete')) { _bad('Completion ledger'); }
      if (j.status == 'completed') {
        if (r.kind == 'construction' && (s.facilities[r.targetId] ?? 0) <
            s.jobs.values.where((job) => job.status == 'completed' && job.recipe.kind == 'construction' && job.recipe.targetId == r.targetId).length) { _bad('Installation completion accounting'); }
        if (r.kind == 'upgrade' && s.upgradeTiers[r.targetId] != 1) { _bad('Upgrade completion accounting'); }
        if (r.kind == 'research' && !s.completedResearch.contains(r.targetId)) { _bad('Research completion accounting'); }
      }
      if (j.status == 'cancelled' && (j.finishedAtUtc == null ||
          s.receipts['cancel:${j.id}']?.kind != 'cancel')) { _bad('Cancellation ledger'); }
      if (j.status != 'completed' && s.receipts.containsKey('complete:${j.id}')) { _bad('Conflicting completion'); }
      if (j.status != 'cancelled' && s.receipts.containsKey('cancel:${j.id}')) { _bad('Conflicting cancellation'); }
    }
    for (final receipt in s.receipts.entries) {
      final id = receipt.key, r = receipt.value;
      final valid = switch (r.kind) {
        'resupply' => (id == 'resupply:start' && r.amount == config.startMaterials) ||
          (config.resupplyLevels.contains(r.levelId) && id == 'resupply:${r.levelId}' &&
            s.completedLevels.contains(r.levelId) && r.amount == config.missionMaterials),
        'catch_up' => id == 'resupply:catch_up' && r.amount <= config.resupplyLevels.length * config.missionMaterials,
        'start' => id.startsWith('start:') && s.jobs[id.substring(6)]?.clock != null && r.amount == 0,
        'complete' => id.startsWith('complete:') && s.jobs[id.substring(9)]?.status == 'completed' && r.amount == 0,
        'cancel' => id.startsWith('cancel:') && s.jobs[id.substring(7)]?.status == 'cancelled' && r.amount == 0,
        'assistance' => id.startsWith('assistance:') && _entitlementRecipe(id.substring(11), s)?.targetId == r.targetId,
        'observed_damage' => id.startsWith('observed:') && s.damageObservations.containsKey(id.substring(9)) && config.damageOccurrences.containsKey(id.substring(9)),
        'damage' => id.startsWith('damage:') && s.confirmedDamage.containsKey(id.substring(7)),
        'resolved_damage' => id.startsWith('resolved:') && s.damageObservations[id.substring(9)]?.remaining == 0 &&
          s.damageObservations[id.substring(9)]?.targetId == r.targetId &&
          s.damageObservations[id.substring(9)]?.units == r.amount,
        _ => false,
      };
      if (!valid) { _bad('Unknown or inconsistent receipt: $id'); }
    }
  }

  ProgressionRecipe? _entitlementRecipe(String id, ProgressionState s) {
    for (final target in config.requiredUnits.keys) {
      if (id == 'construction:$target:${config.requiredUnits[target]}') { return config.recipes['construction:$target']; }
    }
    if (id.startsWith('repair:')) {
      final source = config.damageOccurrences[id.substring(7)];
      if (source != null) { return config.recipes['major_repair:${source.targetId}']; }
    }
    return null;
  }

  static Map<String, dynamic> _map(Object? raw) {
    if (raw is! Map || raw.keys.any((key) => key is! String)) { _bad('Expected object'); }
    return Map<String, dynamic>.from(raw);
  }
  static void _keys(Map<String, dynamic> map, Set<String> keys) {
    if (!_sameSet(map.keys.toSet(), keys)) { _bad('Missing or unsupported fields'); }
  }
  static String _string(Object? raw) {
    if (raw is! String || raw.isEmpty) { _bad('Expected nonempty string'); }
    return raw;
  }
  static String? _optionalString(Object? raw) => raw == null ? null : _string(raw);
  static double _number(Object? raw) {
    if (raw is! num || !raw.isFinite || raw < 0) { _bad('Expected finite nonnegative number'); }
    return raw.toDouble();
  }
  static int _int(Object? raw) {
    if (raw is! int || raw < 0) { _bad('Expected nonnegative integer'); }
    return raw;
  }
  static DateTime _utc(Object? raw) {
    if (raw is! String || !raw.endsWith('Z')) { _bad('Expected UTC timestamp'); }
    final parsed = DateTime.parse(raw).toUtc();
    if (parsed.toIso8601String() != raw) { _bad('Noncanonical UTC timestamp'); }
    return parsed;
  }
  static Map<String, double> _numbers(Object? raw) => {
    for (final e in _map(raw).entries) e.key: _number(e.value),
  };
  static Map<String, int> _ints(Object? raw) => {
    for (final e in _map(raw).entries) e.key: _int(e.value),
  };
  static Map<String, String> _stringMap(Object? raw) => {
    for (final e in _map(raw).entries) e.key: _string(e.value),
  };
  static List<String> _strings(Object? raw, {bool unique = true}) {
    if (raw is! List) { _bad('Expected list'); }
    final values = raw.map(_string).toList();
    if (unique && values.toSet().length != values.length) { _bad('Duplicate identity'); }
    return values;
  }
  static bool _sameSet(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);
  static bool _sameMap(Map<String, double> a, Map<String, double> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
  static Never _bad(String message) => throw FormatException('Invalid progression save: $message');
}
