import 'dart:io';

import 'package:base67/progression/progression_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'progression_service_test.dart'
    show configuration, document, observation;

void main() {
  final now = DateTime.utc(2026, 11, 10);
  final base = configuration();
  Map<String, dynamic> damageRules() {
    final rules = document('progression_rules');
    rules['recovery']['damage_occurrences'] = [
      {
        'level_id': base.levels.first,
        'event_id': 'meteor_shower',
        'sequence': 1,
        'facility_id': 'solar_array',
        'units': 1,
        'essential': true,
      },
    ];
    return rules;
  }

  final occurrence = '${base.levels.first}:meteor_shower:1';
  ProgressionState damaged() => ProgressionState(
    levelId: base.levels.first,
    facilities: {'solar_array': 1},
    damagedUnits: {'solar_array': 1},
    resources: {'materials': 0, 'spare_part': 0},
    crewRoles: {'e': 'Engineer', 's': 'Scientist'},
  );

  ProgressionState observed(
    RealTimeProgressionService service,
    ProgressionState after,
    String id,
  ) {
    final source = service.config.damageOccurrences[id]!;
    final before = after.copyWith(
      damagedUnits: {
        ...after.damagedUnits,
        source.targetId:
            (after.damagedUnits[source.targetId] ?? 0) - source.units,
      },
    );
    final result = service.observeDamage(
      before,
      occurrenceId: id,
      damagedCount: after.damagedUnits[source.targetId]!,
    );
    expect(result.code, 'damage_observed');
    return result.state;
  }

  test('catalogue rejects invalid source, target, count, level and duplicate identities', () {
    for (final patch in [
      {'event_id': 'invented'},
      {'facility_id': 'battery_bank'},
      {'units': 2},
      {'sequence': 0},
      {'level_id': 'invented'},
      {'essential': false},
    ]) {
      final rules = damageRules();
      (rules['recovery']['damage_occurrences'][0] as Map).addAll(patch);
      expect(
        () => configuration(rules: rules),
        throwsFormatException,
        reason: '$patch',
      );
    }
    final duplicate = damageRules();
    duplicate['recovery']['damage_occurrences'].add(
      duplicate['recovery']['damage_occurrences'][0],
    );
    expect(() => configuration(rules: duplicate), throwsFormatException);
    expect(base.damageOccurrences, isEmpty);
  });
  test('arbitrary IDs, mismatched observations and forged unconfirmed claims cannot mint assistance', () {
    final service = RealTimeProgressionService(
      configuration(rules: damageRules()),
    );
    final state = damaged();
    expect(service.confirmDamage(state, 'arbitrary').code, 'unknown_damage');
    expect(
      service.confirmDamage(state.copyWith(damagedUnits: {}), occurrence).code,
      'damage_not_verified',
    );
    expect(
      service
          .confirmDamage(state.copyWith(levelId: base.levels[1]), occurrence)
          .code,
      'damage_not_verified',
    );
    expect(
      service.confirmDamage(state.copyWith(facilities: {}), occurrence).code,
      'damage_not_verified',
    );
    for (final id in [
      'arbitrary',
      'repair:arbitrary',
      'construction:solar_array:999',
    ]) {
      final result = service.recover(state, identity: id);
      expect(result.code, 'invalid_recovery_identity');
      expect(result.state.resources, state.resources);
      expect(result.state.assistance, isEmpty);
    }
    final forged = state.copyWith(confirmedDamage: {occurrence: 1});
    expect(
      service.recover(forged, identity: 'repair:$occurrence').code,
      'invalid_recovery_identity',
    );
    final mismatched = forged.copyWith(
      receipts: {
        'damage:$occurrence': const ProgressionReceipt(
          'resupply',
          999,
          targetId: 'battery_bank',
          levelId: 'invented',
        ),
      },
    );
    expect(
      service.recover(mismatched, identity: 'repair:$occurrence').code,
      'invalid_recovery_identity',
    );
  });
  test('confirmed essential repair restores all assistance on every cancellation without farming', () {
    final service = RealTimeProgressionService(
      configuration(rules: damageRules()),
    );
    var state = service
        .confirmDamage(observed(service, damaged(), occurrence), occurrence)
        .state;
    expect(service.confirmDamage(state, occurrence).code, 'duplicate_damage');
    state = service
        .start(
          state,
          jobId: 'research',
          kind: 'research',
          targetId: 'solar_energy_fundamentals',
          observation: observation(state, now),
          crewId: 's',
        )
        .state;
    state = service.recover(state, identity: 'repair:$occurrence').state;
    expect(state.assistance['repair:$occurrence'], {
      'materials': 2,
      'spare_part': 1,
    });
    for (var i = 0; i < 15; i++) {
      final id = 'repair:$i';
      final result = service.start(
        state,
        jobId: id,
        kind: 'major_repair',
        targetId: 'solar_array',
        crewId: 'e',
        observation: observation(state, now),
      );
      expect(result.code, 'active');
      state = service
          .cancel(
            result.state,
            jobId: id,
            observation: observation(result.state, now),
          )
          .state;
      expect(state.resources, {'materials': 0.0, 'spare_part': 0.0});
      expect(state.assistance['repair:$occurrence'], {
        'materials': 2,
        'spare_part': 1,
      });
      expect(
        service.recover(state, identity: 'repair:$occurrence').code,
        'not_needed',
      );
    }
    final active = service
        .start(
          state,
          jobId: 'final',
          kind: 'major_repair',
          targetId: 'solar_array',
          crewId: 'e',
          observation: observation(state, now),
        )
        .state;
    final complete = service
        .cancel(
          active,
          jobId: 'final',
          observation: observation(active, active.jobs['final']!.deadlineUtc!),
        )
        .state;
    expect(complete.jobs['final']!.status, 'completed');
    expect(complete.damagedUnits['solar_array'], 0);
    expect(
      service.recover(complete, identity: 'repair:$occurrence').code,
      'invalid_recovery_identity',
    );
    expect(
      service
          .confirmDamage(
            complete.copyWith(damagedUnits: {'solar_array': 1}),
            occurrence,
          )
          .code,
      'duplicate_damage',
    );
  });
  test('mixed repair payments restore assistance and recover a lost ordinary spare', () {
    final service = RealTimeProgressionService(
      configuration(rules: damageRules()),
    );
    var state = service
        .confirmDamage(
          observed(
            service,
            damaged().copyWith(resources: {'materials': 0, 'spare_part': 1}),
            occurrence,
          ),
          occurrence,
        )
        .state;
    state = service.recover(state, identity: 'repair:$occurrence').state;
    state = service
        .start(
          state,
          jobId: 'mixed-repair',
          kind: 'major_repair',
          targetId: 'solar_array',
          observation: observation(state, now),
        )
        .state;
    state = service
        .cancel(
          state,
          jobId: 'mixed-repair',
          observation: observation(state, now),
        )
        .state;
    expect(state.resources['spare_part'], 0);
    expect(state.assistance['repair:$occurrence']!['materials'], 2);
    state = service.recover(state, identity: 'repair:$occurrence').state;
    expect(state.assistance['repair:$occurrence'], {
      'materials': 2,
      'spare_part': 1,
    });
    expect(state.materials, 0);
    expect(state.receipts['assistance:repair:$occurrence']!.amount, 3);
  });

  test('two verified damage occurrences recover independently without reusing repaired claims', () {
    final rules = damageRules();
    rules['recovery']['damage_occurrences'].add(<String, Object>{
      ...Map<String, Object>.from(
        rules['recovery']['damage_occurrences'][0] as Map,
      ),
      'sequence': 2,
    });
    final service = RealTimeProgressionService(configuration(rules: rules));
    var state = damaged().copyWith(
      facilities: {'solar_array': 2},
      damagedUnits: {'solar_array': 2},
    );
    final second = '${base.levels.first}:meteor_shower:2';
    state = state.copyWith(damagedUnits: {});
    state = service
        .observeDamage(state, occurrenceId: occurrence, damagedCount: 1)
        .state;
    state = service
        .observeDamage(state, occurrenceId: second, damagedCount: 2)
        .state;
    state = service.confirmDamage(state, occurrence).state;
    state = service.confirmDamage(state, second).state;
    for (final id in [occurrence, second]) {
      state = service.recover(state, identity: 'repair:$id').state;
      final active = service.start(
        state,
        jobId: 'fix:$id',
        kind: 'major_repair',
        targetId: 'solar_array',
        observation: observation(state, now),
      );
      expect(active.code, 'active');
      state = service.reconcile(
        active.state,
        observation: observation(
          active.state,
          active.state.jobs['fix:$id']!.deadlineUtc!,
        ),
      );
      expect(state.confirmedDamage[id], 0);
      expect(
        service.recover(state, identity: 'repair:$id').code,
        'invalid_recovery_identity',
      );
    }
    expect(state.damagedUnits['solar_array'], 0);
    expect(state.materials, 0);
    expect(state.resources['spare_part'], 0);
  });

  test('two shared lanes include unassigned work and activation rechecks occupancy', () {
    final service = RealTimeProgressionService(base);
    var state = service.resupply(ProgressionState(levelId: base.levels.last));
    state = service
        .enqueue(
          state,
          jobId: 'queued',
          kind: 'construction',
          targetId: 'battery_bank',
        )
        .state;
    state = service
        .start(
          state,
          jobId: 'build',
          kind: 'construction',
          targetId: 'solar_array',
          observation: observation(state, now),
        )
        .state;
    expect(
      service
          .activate(
            state,
            jobId: 'queued',
            observation: observation(state, now),
          )
          .code,
      'lane_busy',
    );
    state = service
        .start(
          state,
          jobId: 'research',
          kind: 'research',
          targetId: 'solar_energy_fundamentals',
          observation: observation(state, now),
        )
        .state;
    expect(state.jobs['research']!.status, 'active');
    expect(
      service
          .start(
            state,
            jobId: 'research2',
            kind: 'research',
            targetId: 'solar_energy_fundamentals',
            observation: observation(state, now),
          )
          .code,
      'target_busy',
    );
    state = service
        .cancel(state, jobId: 'build', observation: observation(state, now))
        .state;
    expect(
      service
          .activate(
            state,
            jobId: 'queued',
            observation: observation(state, now),
          )
          .code,
      'active',
    );
    state = state.copyWith(
      externalCrewAssignments: {'e': 'clean'},
      crewRoles: {'e': 'Engineer'},
    );
    expect(
      service
          .start(
            state,
            jobId: 'repair',
            kind: 'construction',
            targetId: 'battery_bank',
            crewId: 'e',
            observation: observation(state, now),
          )
          .code,
      'crew_busy',
    );
    state = state.copyWith(externalFacilityReservations: {'battery_bank'});
    expect(
      service
          .start(
            state,
            jobId: 'reserved',
            kind: 'construction',
            targetId: 'battery_bank',
            observation: observation(state, now),
          )
          .code,
      'target_busy',
    );
  });
  test('Engineer halves eligible timed repairs only; costs and snapshots are unchanged', () {
    final service = RealTimeProgressionService(base);
    final state = damaged().copyWith(
      levelId: base.levels.last,
      resources: {'materials': 10, 'spare_part': 2},
    );
    final ordinary = service
        .start(
          state,
          jobId: 'normal',
          kind: 'major_repair',
          targetId: 'solar_array',
          observation: observation(state, now),
        )
        .state;
    var engineer = service
        .start(
          state,
          jobId: 'engineer',
          kind: 'major_repair',
          targetId: 'solar_array',
          observation: observation(state, now),
          crewId: 'e',
        )
        .state;
    expect(
      engineer.jobs['engineer']!.clock!.duration.inMicroseconds * 2,
      ordinary.jobs['normal']!.clock!.duration.inMicroseconds,
    );
    expect(engineer.resources, ordinary.resources);
    final original = engineer.jobs['engineer']!.clock!.duration;
    engineer = engineer.copyWith(crewRoles: {});
    engineer = service.reconcile(
      engineer,
      observation: observation(engineer, now.add(const Duration(seconds: 1))),
    );
    expect(engineer.jobs['engineer']!.clock!.duration, original);
    expect(engineer.resources['spare_part'], 1);
  });
  test('late confirmation cannot relabel an unidentified active or finished repair', () {
    final service = RealTimeProgressionService(
      configuration(rules: damageRules()),
    );
    var state = damaged().copyWith(
      resources: {'materials': 2, 'spare_part': 1},
    );
    state = service
        .start(
          state,
          jobId: 'ordinary',
          kind: 'major_repair',
          targetId: 'solar_array',
          observation: observation(state, now),
        )
        .state;
    final allocation = state.jobs['ordinary']!.repairDamageId;
    expect(allocation, isNotNull);
    expect(allocation, isNot(occurrence));
    expect(
      service.confirmDamage(state, occurrence).code,
      'damage_not_verified',
    );
    expect(
      service.recover(state, identity: 'repair:$occurrence').state.assistance,
      isEmpty,
    );
    state = service.reconcile(
      state,
      observation: observation(state, state.jobs['ordinary']!.deadlineUtc!),
    );
    expect(state.damageObservations[allocation]!.remaining, 0);
    expect(
      service.confirmDamage(state, occurrence).code,
      'damage_not_verified',
    );
    // Unidentified later damage cannot revive the old claim either.
    state = state.copyWith(damagedUnits: {'solar_array': 1});
    expect(
      service.confirmDamage(state, occurrence).code,
      'damage_not_verified',
    );
    expect(
      service.recover(state, identity: 'repair:$occurrence').state.assistance,
      isEmpty,
    );
  });

  test('ordinary payment resolves an observed occurrence even if confirmation is late', () {
    final service = RealTimeProgressionService(
      configuration(rules: damageRules()),
    );
    var state = damaged().copyWith(
      damagedUnits: {},
      resources: {'materials': 2, 'spare_part': 1},
    );
    state = service
        .observeDamage(state, occurrenceId: occurrence, damagedCount: 1)
        .state;
    state = service
        .start(
          state,
          jobId: 'ordinary',
          kind: 'major_repair',
          targetId: 'solar_array',
          observation: observation(state, now),
        )
        .state;
    expect(state.jobs['ordinary']!.repairDamageId, occurrence);
    expect(state.jobs['ordinary']!.recoveryId, isNull);
    state = service.confirmDamage(state, occurrence).state;
    expect(
      service.recover(state, identity: 'repair:$occurrence').code,
      'not_needed',
    );
    state = service.reconcile(
      state,
      observation: observation(state, state.jobs['ordinary']!.deadlineUtc!),
    );
    expect(state.confirmedDamage[occurrence], 0);
    expect(state.damageObservations[occurrence]!.remaining, 0);
    expect(state.receipts.containsKey('resolved:$occurrence'), isTrue);
    expect(state.assistance.containsKey('repair:$occurrence'), isFalse);
    expect(
      service
          .observeDamage(state, occurrenceId: occurrence, damagedCount: 1)
          .code,
      'duplicate_damage',
    );
    expect(
      service
          .confirmDamage(
            state.copyWith(damagedUnits: {'solar_array': 1}),
            occurrence,
          )
          .code,
      'duplicate_damage',
    );
  });

  test(
    'late confirmation keeps ordinary repair refunds and assistance on its occurrence',
    () {
      final rules = damageRules();
      rules['recovery']['damage_occurrences'].add(<String, Object>{
        ...Map<String, Object>.from(
          rules['recovery']['damage_occurrences'][0] as Map,
        ),
        'sequence': 2,
      });
      final service = RealTimeProgressionService(configuration(rules: rules));
      final second = '${base.levels.first}:meteor_shower:2';
      var state = damaged().copyWith(
        facilities: {'solar_array': 2},
        damagedUnits: {},
        resources: {'materials': 2, 'spare_part': 1},
      );
      state = service
          .observeDamage(state, occurrenceId: occurrence, damagedCount: 1)
          .state;
      final ordinary = service.start(
        state,
        jobId: 'ordinary-late-confirmation',
        kind: 'major_repair',
        targetId: 'solar_array',
        observation: observation(state, now),
      );
      expect(ordinary.code, 'active');
      state = ordinary.state;
      expect(state.jobs['ordinary-late-confirmation']!.repairDamageId, occurrence);
      expect(state.jobs['ordinary-late-confirmation']!.recoveryId, isNull);
      expect(state.jobs['ordinary-late-confirmation']!.paid, {
        'materials': 2,
        'spare_part': 1,
      });

      state = service.confirmDamage(state, occurrence).state;
      state = service
          .observeDamage(state, occurrenceId: second, damagedCount: 2)
          .state;
      state = service.confirmDamage(state, second).state;
      final cancelledOrdinary = service.cancel(
        state,
        jobId: 'ordinary-late-confirmation',
        observation: observation(state, now),
      );
      expect(cancelledOrdinary.code, 'cancelled');
      state = cancelledOrdinary.state;
      expect(state.jobs['ordinary-late-confirmation']!.status, 'cancelled');
      expect(state.resources, {'materials': 1.0, 'spare_part': 0.0});
      expect(state.damageObservations[occurrence]!.remaining, 1);
      expect(state.damageObservations[second]!.remaining, 1);
      expect(state.assistance, isEmpty);

      state = service.recover(state, identity: 'repair:$occurrence').state;
      expect(state.assistance['repair:$occurrence'], {
        'materials': 1,
        'spare_part': 1,
      });
      final firstCredit = Map<String, double>.from(
        state.assistance['repair:$occurrence']!,
      );
      final repeatedRecovery = service.recover(
        state,
        identity: 'repair:$occurrence',
      );
      expect(repeatedRecovery.code, 'not_needed');
      expect(repeatedRecovery.state.assistance, state.assistance);
      expect(
        repeatedRecovery.state.assistance['repair:$occurrence'],
        firstCredit,
      );
      expect(repeatedRecovery.state.receipts, state.receipts);
      expect(repeatedRecovery.state.resources, state.resources);
      expect(
        repeatedRecovery.state.assistance.containsKey('repair:$second'),
        state.assistance.containsKey('repair:$second'),
      );
      final unrelatedClaim = service.recover(
        state,
        identity: 'repair:$second',
      );
      expect(unrelatedClaim.code, 'invalid_recovery_identity');
      expect(unrelatedClaim.state.assistance, state.assistance);
      expect(state.assistance.containsKey('repair:$second'), isFalse);

      final assistedRetry = service.start(
        state,
        jobId: 'assisted-retry-cancel',
        kind: 'major_repair',
        targetId: 'solar_array',
        observation: observation(state, now),
      );
      expect(assistedRetry.code, 'active');
      state = assistedRetry.state;
      expect(state.jobs['assisted-retry-cancel']!.repairDamageId, occurrence);
      expect(state.jobs['assisted-retry-cancel']!.recoveryId, 'repair:$occurrence');
      expect(state.jobs['assisted-retry-cancel']!.paid, {
        'materials': 1,
        'spare_part': 0,
      });
      expect(state.jobs['assisted-retry-cancel']!.assistancePaid, {
        'materials': 1,
        'spare_part': 1,
      });
      state = service
          .cancel(
            state,
            jobId: 'assisted-retry-cancel',
            observation: observation(state, now),
          )
          .state;
      expect(state.jobs['assisted-retry-cancel']!.status, 'cancelled');
      expect(state.resources, {'materials': 0.0, 'spare_part': 0.0});
      expect(state.assistance['repair:$occurrence'], firstCredit);

      state = service.recover(state, identity: 'repair:$occurrence').state;
      expect(state.assistance['repair:$occurrence'], {
        'materials': 2,
        'spare_part': 1,
      });
      expect(
        service.recover(state, identity: 'repair:$occurrence').code,
        'not_needed',
      );
      final retry = service.start(
        state,
        jobId: 'final-retry',
        kind: 'major_repair',
        targetId: 'solar_array',
        observation: observation(state, now),
      );
      expect(retry.code, 'active');
      state = service.reconcile(
        retry.state,
        observation: observation(
          retry.state,
          retry.state.jobs['final-retry']!.deadlineUtc!,
        ),
      );
      expect(state.jobs['final-retry']!.status, 'completed');
      expect(state.damageObservations[occurrence]!.remaining, 0);
      expect(state.damageObservations[second]!.remaining, 1);
      expect(state.receipts.containsKey('resolved:$occurrence'), isTrue);
      expect(state.assistance.containsKey('repair:$occurrence'), isFalse);
      expect(
        service.recover(state, identity: 'repair:$occurrence').code,
        'invalid_recovery_identity',
      );

      state = service.recover(state, identity: 'repair:$second').state;
      expect(state.assistance['repair:$second'], {
        'materials': 2,
        'spare_part': 1,
      });
      expect(state.receipts['assistance:repair:$second']!.amount, 3);
      expect(state.assistance.containsKey('repair:$occurrence'), isFalse);
    },
  );

  test('invalid damage observations preserve the snapshot and existing credits', () {
    final service = RealTimeProgressionService(
      configuration(rules: damageRules()),
    );
    final clean = damaged().copyWith(
      damagedUnits: {},
      assistance: {
        'unrelated-existing-entitlement': {'materials': 1, 'spare_part': 1},
      },
      receipts: {
        'assistance:unrelated-existing-entitlement':
            const ProgressionReceipt('assistance', 2),
      },
    );
    final invalidCases = [
      (
        'wrong level',
        clean.copyWith(levelId: base.levels[1]),
        1,
      ),
      (
        'incorrect increment with sufficient capacity',
        clean.copyWith(facilities: {'solar_array': 2}),
        2,
      ),
      (
        'over capacity',
        clean.copyWith(damagedUnits: {'solar_array': 1}),
        2,
      ),
    ];

    for (final (name, snapshot, damagedCount) in invalidCases) {
      final result = service.observeDamage(
        snapshot,
        occurrenceId: occurrence,
        damagedCount: damagedCount,
      );
      expect(result.code, 'damage_not_verified', reason: name);
      expect(identical(result.state, snapshot), isTrue, reason: name);
      expect(result.state.damageObservations, snapshot.damageObservations, reason: name);
      expect(result.state.assistance, snapshot.assistance, reason: name);
      expect(result.state.receipts, snapshot.receipts, reason: name);
    }
  });

  test('field outcomes close only their occurrence and cannot consume a reserved repair', () {
    final rules = damageRules();
    rules['recovery']['damage_occurrences'].add(<String, Object>{
      ...Map<String, Object>.from(
        rules['recovery']['damage_occurrences'][0] as Map,
      ),
      'sequence': 2,
    });
    final service = RealTimeProgressionService(configuration(rules: rules));
    final second = '${base.levels.first}:meteor_shower:2';
    var state = damaged().copyWith(
      facilities: {'solar_array': 2},
      damagedUnits: {},
    );
    state = service
        .observeDamage(state, occurrenceId: occurrence, damagedCount: 1)
        .state;
    state = service
        .observeDamage(state, occurrenceId: second, damagedCount: 2)
        .state;
    state = service.confirmDamage(state, occurrence).state;
    state = service.confirmDamage(state, second).state;
    state = service.recover(state, identity: 'repair:$occurrence').state;
    final before = state.resources;
    state = service
        .recordFieldRepair(state, damageId: occurrence, damagedCount: 1)
        .state;
    expect(
      state.resources,
      before,
    ); // Outcome reporting; the external action owns its payment.
    expect(state.assistance.containsKey('repair:$occurrence'), isFalse);
    expect(state.confirmedDamage[occurrence], 0);
    expect(state.confirmedDamage[second], 1);
    expect(
      service
          .recordFieldRepair(state, damageId: occurrence, damagedCount: 0)
          .code,
      'damage_not_open',
    );
    expect(
      service.recover(state, identity: 'repair:$occurrence').code,
      'invalid_recovery_identity',
    );
    state = service.recover(state, identity: 'repair:$second').state;
    state = service
        .start(
          state,
          jobId: 'second',
          kind: 'major_repair',
          targetId: 'solar_array',
          observation: observation(state, now),
        )
        .state;
    expect(
      service.recordFieldRepair(state, damageId: second, damagedCount: 0).code,
      'damage_reserved',
    );
    state = service
        .cancel(state, jobId: 'second', observation: observation(state, now))
        .state;
    expect(state.damageObservations[second]!.remaining, 1);
    expect(state.assistance['repair:$second'], {
      'materials': 2,
      'spare_part': 1,
    });
    state = service
        .recordFieldRepair(state, damageId: second, damagedCount: 0)
        .state;
    expect(state.assistance.containsKey('repair:$second'), isFalse);
  });

  test('new occurrence during unidentified work stays independent and respects the lane', () {
    final service = RealTimeProgressionService(
      configuration(rules: damageRules()),
    );
    var state = damaged().copyWith(
      facilities: {'solar_array': 2},
      resources: {'materials': 2, 'spare_part': 1},
    );
    state = service
        .start(
          state,
          jobId: 'old',
          kind: 'major_repair',
          targetId: 'solar_array',
          observation: observation(state, now),
        )
        .state;
    final old = state.jobs['old']!.repairDamageId!;
    state = service
        .observeDamage(state, occurrenceId: occurrence, damagedCount: 2)
        .state;
    state = service.confirmDamage(state, occurrence).state;
    state = service.recover(state, identity: 'repair:$occurrence').state;
    expect(state.assistance['repair:$occurrence'], {
      'materials': 2,
      'spare_part': 1,
    });
    expect(
      service
          .start(
            state,
            jobId: 'new-blocked',
            kind: 'major_repair',
            targetId: 'solar_array',
            observation: observation(state, now),
          )
          .code,
      'target_busy',
    );
    state = service.reconcile(
      state,
      observation: observation(state, state.jobs['old']!.deadlineUtc!),
    );
    expect(state.damageObservations[old]!.remaining, 0);
    expect(state.damageObservations[occurrence]!.remaining, 1);
    expect(state.confirmedDamage[occurrence], 1);
    expect(state.damagedUnits['solar_array'], 1);
    state = service
        .start(
          state,
          jobId: 'new',
          kind: 'major_repair',
          targetId: 'solar_array',
          observation: observation(state, now),
        )
        .state;
    expect(state.jobs['new']!.repairDamageId, occurrence);
    state = service.reconcile(
      state,
      observation: observation(state, state.jobs['new']!.deadlineUtc!),
    );
    expect(state.damagedUnits['solar_array'], 0);
    expect(state.assistance.containsKey('repair:$occurrence'), isFalse);
  });

  test(
    'external count replacement cannot silently complete an allocated repair',
    () {
      final service = RealTimeProgressionService(
        configuration(rules: damageRules()),
      );
      var state = damaged().copyWith(
        damagedUnits: {},
        resources: {'materials': 2, 'spare_part': 1},
      );
      state = service
          .observeDamage(state, occurrenceId: occurrence, damagedCount: 1)
          .state;
      state = service.confirmDamage(state, occurrence).state;
      state = service
          .start(
            state,
            jobId: 'repair',
            kind: 'major_repair',
            targetId: 'solar_array',
            observation: observation(state, now),
          )
          .state;
      final inconsistent = state.copyWith(damagedUnits: {});
      final after = service.reconcile(
        inconsistent,
        observation: observation(
          inconsistent,
          state.jobs['repair']!.deadlineUtc!,
        ),
      );
      expect(after.jobs['repair']!.status, 'active');
      expect(after.jobs['repair']!.blockReason, 'damage_not_verified');
      expect(after.completedActivityIds, isEmpty);
      expect(after.confirmedDamage[occurrence], 1);
      expect(after.resources, state.resources);
      expect(after.log.last, 'repair_damage_mismatch:repair');
    },
  );

  test(
    'different research targets share one lane and role bonuses do not leak',
    () {
      final service = RealTimeProgressionService(base);
      var state = service.resupply(
        ProgressionState(
          levelId: base.levels.last,
          completedResearch: {'solar_energy_fundamentals'},
          crewRoles: {'e': 'Engineer', 's': 'Scientist'},
        ),
      );
      state = service
          .start(
            state,
            jobId: 'research',
            kind: 'research',
            targetId: 'advanced_battery_systems',
            crewId: 's',
            observation: observation(state, now),
          )
          .state;
      expect(
        state.jobs['research']!.clock!.duration,
        base.recipes['research:advanced_battery_systems']!.duration,
      );
      expect(
        service
            .start(
              state,
              jobId: 'other',
              kind: 'research',
              targetId: 'dust_protection_technology',
              observation: observation(state, now),
            )
            .code,
        'lane_busy',
      );
      state = service
          .start(
            state,
            jobId: 'build',
            kind: 'construction',
            targetId: 'solar_array',
            crewId: 'e',
            observation: observation(state, now),
          )
          .state;
      expect(
        state.jobs['build']!.clock!.duration,
        base.recipes['construction:solar_array']!.duration,
      );
    },
  );

  test('policy code never reads clocks, runs simulation, imports Flutter or uses IO', () {
    for (final file in ['progression_service.dart', 'progression_clock.dart']) {
      final source = File('lib/progression/$file').readAsStringSync();
      for (final forbidden in [
        'DateTime.now',
        'package:flutter',
        'dart:io',
        'dart:ui',
        'Random(',
        'Engine(',
        '../sim/',
      ]) {
        expect(
          source.contains(forbidden),
          isFalse,
          reason: '$file: $forbidden',
        );
      }
    }
  });
}
