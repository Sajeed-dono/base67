import 'package:base67/progression/facility_mapping.dart';
import 'package:base67/progression/progression_service.dart';
import 'package:base67/sim/sim_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'progression_service_test.dart' show configuration, observation;

void main() {
  final now = DateTime.utc(2026, 11, 10);
  final config = configuration();
  final service = RealTimeProgressionService(config);
  ProgressionState initial() => service.resupply(
    ProgressionState(
      levelId: config.levels.last,
      packedStock: {'solar_panel': 2, 'battery': 1, 'spare_part': 3},
    ),
  );
  ProgressionState start(ProgressionState s, String id, String target) =>
      service
          .start(
            s,
            jobId: id,
            kind: 'construction',
            targetId: target,
            observation: observation(s, now),
          )
          .state;

  test(
    'packed cargo is not installed or productive and queue reserves nothing',
    () {
      final state = initial();
      expect(FacilityMapping.toSimulation(state), isEmpty);
      final q = service
          .enqueue(
            state,
            jobId: 'q',
            kind: 'construction',
            targetId: 'solar_array',
          )
          .state;
      expect(q.packedStock, state.packedStock);
      expect(q.materials, state.materials);
      expect(q.jobs['q']!.reservedStock, isEmpty);
      expect(q.facilities, isEmpty);
    },
  );
  test('activation reserves stock, cancellation returns it once, costs refund separately', () {
    final active = start(initial(), 'solar', 'solar_array');
    expect(active.packedStock['solar_panel'], 1);
    expect(active.materials, 75);
    expect(active.jobs['solar']!.reservedStock, {'solar_panel': 1});
    expect(active.facilities, isEmpty);
    var cancelled = service
        .cancel(active, jobId: 'solar', observation: observation(active, now))
        .state;
    expect(cancelled.packedStock['solar_panel'], 2);
    expect(cancelled.materials, 77);
    cancelled = service
        .cancel(
          cancelled,
          jobId: 'solar',
          observation: observation(cancelled, now),
        )
        .state;
    expect(cancelled.packedStock['solar_panel'], 2);
    expect(cancelled.materials, 77);
  });
  test('completion consumes reserved cargo and installs once across pure continuation', () {
    var state = start(initial(), 'solar', 'solar_array');
    state = RealTimeProgressionService(config).reconcile(
      state,
      observation: observation(state, state.jobs['solar']!.deadlineUtc!),
    );
    for (var i = 0; i < 5; i++) {
      state = service.reconcile(
        state,
        observation: observation(state, now.add(const Duration(days: 1))),
      );
    }
    expect(state.packedStock['solar_panel'], 1);
    expect(state.facilities['solar_array'], 1);
    expect(state.materials, 75);
    expect(state.packedStock['spare_part'], 3);
    expect(FacilityMapping.toSimulation(state)['solar_array']!.units, 1);
  });
  test(
    'no-stock construction remains available and source unit limit is enforced',
    () {
      var state = initial().copyWith(packedStock: {});
      final limit = config.maxUnits['solar_array']!;
      for (var i = 0; i < limit; i++) {
        final result = service.start(
          state,
          jobId: 'unit:$i',
          kind: 'construction',
          targetId: 'solar_array',
          observation: observation(state, now),
        );
        expect(result.code, 'active');
        state = service.reconcile(
          result.state,
          observation: observation(
            result.state,
            result.state.jobs['unit:$i']!.deadlineUtc!,
          ),
        );
      }
      expect(state.facilities['solar_array'], limit);
      expect(
        service
            .start(
              state,
              jobId: 'excess',
              kind: 'construction',
              targetId: 'solar_array',
              observation: observation(state, now),
            )
            .code,
        'unit_limit',
      );
      expect(state.materials, 80 - 5 * limit);
      expect(state.packedStock, isEmpty);
    },
  );
  test('spare parts never install a maintenance bay and starter habitat is preserved', () {
    var state = initial().copyWith(
      facilities: {'crew_habitat': 1, 'landing_craft': 1},
    );
    expect(
      FacilityMapping.toSimulation(state).containsKey('maintenance_bay'),
      isFalse,
    );
    state = start(state, 'bay', 'maintenance_bay');
    state = service.reconcile(
      state,
      observation: observation(state, state.jobs['bay']!.deadlineUtc!),
    );
    expect(state.packedStock['spare_part'], 3);
    expect(state.facilities['maintenance_bay'], 1);
    expect(state.facilities['crew_habitat'], 1);
    expect(state.facilities['landing_craft'], 1);
  });
  test('count, tier, damage and operating state map independently without touching stocks', () {
    final state = initial().copyWith(
      facilities: {'solar_array': 3, 'battery_bank': 2},
      upgradeTiers: {'solar_array': 1},
      damagedUnits: {'solar_array': 1},
      operatingStates: {'battery_bank': 'off'},
      resources: {'oxygen_kg': 7},
    );
    final result = FacilityMapping.toSimulation(state);
    expect(result['solar_array']!.units, 3);
    expect(result['solar_array']!.tier, 2);
    expect(result['solar_array']!.damagedUnits, 1);
    expect(result['solar_array']!.workingUnits, 2);
    expect(result['battery_bank']!.tier, 1);
    expect(result['battery_bank']!.status, FacilityStatus.off);
    expect(result['battery_bank']!.workingUnits, 0);
    expect(state.resources, {'oxygen_kg': 7});
    expect(() => result.clear(), throwsUnsupportedError);
  });
  test('first construction clears lifecycle states but preserves deliberate shutdown', () {
    for (final status in ['notBuilt', 'underConstruction', 'off']) {
      var state = initial().copyWith(operatingStates: {'solar_array': status});
      state = start(state, 'first:$status', 'solar_array');
      expect(
        FacilityMapping.toSimulation(state)['solar_array']!.workingUnits,
        0,
      );
      expect(state.facilities['solar_array'] ?? 0, 0);
      state = service.reconcile(
        state,
        observation: observation(
          state,
          state.jobs['first:$status']!.deadlineUtc!,
        ),
      );
      expect(
        state.operatingStates['solar_array'],
        status == 'off' ? 'off' : 'operating',
      );
      expect(
        FacilityMapping.toSimulation(state)['solar_array']!.workingUnits,
        status == 'off' ? 0 : 1,
      );
      state = service.reconcile(
        state,
        observation: observation(state, now.add(const Duration(days: 1))),
      );
      expect(state.facilities['solar_array'], 1);
      expect(state.packedStock['solar_panel'], 1);
    }
  });

  test('expansion preserves existing damaged, upgraded and disabled units', () {
    for (final status in ['operating', 'damaged', 'off', 'outOfResources']) {
      var state = initial().copyWith(
        facilities: {'solar_array': 2},
        damagedUnits: {'solar_array': 1},
        upgradeTiers: {'solar_array': 1},
        operatingStates: {'solar_array': status},
      );
      state = start(state, 'third', 'solar_array');
      expect(state.operatingStates['solar_array'], status);
      expect(state.facilities['solar_array'], 2);
      expect(
        FacilityMapping.toSimulation(state)['solar_array']!.workingUnits,
        ['off', 'outOfResources'].contains(status) ? 0 : 1,
      );
      final cancelled = service
          .cancel(state, jobId: 'third', observation: observation(state, now))
          .state;
      expect(cancelled.facilities['solar_array'], 2);
      expect(cancelled.operatingStates['solar_array'], status);
      expect(cancelled.packedStock['solar_panel'], 2);
      state = service.reconcile(
        state,
        observation: observation(state, state.jobs['third']!.deadlineUtc!),
      );
      expect(state.facilities['solar_array'], 3);
      expect(state.damagedUnits['solar_array'], 1);
      expect(state.upgradeTiers['solar_array'], 1);
      expect(state.operatingStates['solar_array'], status);
    }
  });

  test(
    'first cancellation restores unbuilt lifecycle without duplicating cargo',
    () {
      var state = start(
        initial().copyWith(operatingStates: {'solar_array': 'notBuilt'}),
        'first',
        'solar_array',
      );
      expect(state.operatingStates['solar_array'], 'underConstruction');
      state = service
          .cancel(state, jobId: 'first', observation: observation(state, now))
          .state;
      expect(state.operatingStates['solar_array'], 'notBuilt');
      expect(state.facilities['solar_array'] ?? 0, 0);
      state = service
          .cancel(state, jobId: 'first', observation: observation(state, now))
          .state;
      expect(state.packedStock['solar_panel'], 2);
    },
  );

  for (final blockedByTarget in [false, true]) {
    test(
      'cancelling ${blockedByTarget ? 'target-busy blocked' : 'queued'} '
      'construction preserves the active first build',
      () {
        final base = initial().copyWith(
          operatingStates: {'solar_array': 'notBuilt'},
          crewRoles: {'engineer': 'Engineer', 'scientist': 'Scientist'},
        );
        // The active first build uses the Engineer and owns the lifecycle state.
        final active = service.start(
          base,
          jobId: 'active-first',
          kind: 'construction',
          targetId: 'solar_array',
          crewId: 'engineer',
          observation: observation(base, now),
        );
        var state = active.state;
        final originalJob = state.jobs['active-first']!;
        expect(state.operatingStates['solar_array'], 'underConstruction');
        expect(originalJob.status, 'active');

        var queued = service.enqueue(
          state,
          jobId: 'second',
          kind: 'construction',
          targetId: 'solar_array',
        );
        state = queued.state;
        expect(queued.code, 'queued');
        if (blockedByTarget) {
          queued = service.activate(
            state,
            jobId: 'second',
            observation: observation(state, now),
          );
          state = queued.state;
          expect(queued.code, 'target_busy');
          expect(state.jobs['second']!.status, 'blocked');
          expect(state.jobs['second']!.blockReason, 'target_busy');
        }

        final beforeCancel = state;
        final cancelled = service.cancel(
          state,
          jobId: 'second',
          observation: observation(state, now),
        );

        expect(cancelled.code, 'cancelled');
        expect(cancelled.state.operatingStates['solar_array'], 'underConstruction');
        expect(cancelled.state.facilities['solar_array'] ?? 0, 0);
        expect(cancelled.state.jobs['active-first']!.status, 'active');
        expect(cancelled.state.jobs['active-first']!.crewId, 'engineer');
        expect(cancelled.state.jobs['second']!.paid, isEmpty);
        expect(cancelled.state.jobs['second']!.reservedStock, isEmpty);
        expect(
          cancelled.state.jobs['active-first']!.paid,
          originalJob.paid,
        );
        expect(
          cancelled.state.jobs['active-first']!.assistancePaid,
          originalJob.assistancePaid,
        );
        expect(
          cancelled.state.jobs['active-first']!.reservedStock,
          originalJob.reservedStock,
        );
        expect(
          cancelled.state.jobs['active-first']!.clock!.startedAtUtc,
          originalJob.clock!.startedAtUtc,
        );
        expect(
          cancelled.state.jobs['active-first']!.clock!.originalDeadlineUtc,
          originalJob.clock!.originalDeadlineUtc,
        );
        expect(
          cancelled.state.jobs['active-first']!.clock!.remaining,
          originalJob.clock!.remaining,
        );
        expect(
          cancelled.state.jobs['active-first']!.clock!.duration,
          originalJob.clock!.duration,
        );
        expect(
          cancelled.state.jobs['active-first']!.clock!.observedAtUtc,
          originalJob.clock!.observedAtUtc,
        );
        expect(
          cancelled.state.jobs['active-first']!.clock!.rollbackCount,
          originalJob.clock!.rollbackCount,
        );
        expect(
          cancelled.state.crewAssignments,
          beforeCancel.crewAssignments,
        );
        expect(cancelled.state.resources, beforeCancel.resources);
        expect(cancelled.state.pending, beforeCancel.pending);
        expect(cancelled.state.packedStock, beforeCancel.packedStock);
        expect(
          cancelled.state.jobs['active-first']!.clock!.observationToken,
          cancelled.state.lastObservationToken,
        );
      },
    );
  }

  test(
    'packed spares unpack atomically once and obey ordinary repair refunds',
    () {
      var state = initial().copyWith(
        facilities: {'solar_array': 1},
        damagedUnits: {'solar_array': 1},
      );
      expect(
        service
            .start(
              state,
              jobId: 'packed-only',
              kind: 'major_repair',
              targetId: 'solar_array',
              observation: observation(state, now),
            )
            .code,
        'spares_need_unpacking',
      );
      final result = service.unpackSpareParts(state);
      expect(result.code, 'spares_unpacked');
      state = result.state;
      expect(state.resources['spare_part'], 3);
      expect(state.packedStock.containsKey('spare_part'), isFalse);
      expect(identical(service.unpackSpareParts(state).state, state), isTrue);
      state = service
          .start(
            state,
            jobId: 'repair',
            kind: 'major_repair',
            targetId: 'solar_array',
            observation: observation(state, now),
          )
          .state;
      expect(state.resources['spare_part'], 2);
      state = service
          .cancel(state, jobId: 'repair', observation: observation(state, now))
          .state;
      expect(
        state.resources['spare_part'],
        2,
      ); // floor(1 * .5), not a full cargo return.
      expect(state.jobs['repair']!.reservedStock, isEmpty);
      state = service
          .cancel(state, jobId: 'repair', observation: observation(state, now))
          .state;
      expect(state.resources['spare_part'], 2);
      final ambiguous = initial().copyWith(
        resources: {'materials': 80, 'spare_part': 3},
      );
      expect(
        service.unpackSpareParts(ambiguous).code,
        'ambiguous_spare_ownership',
      );
      expect(
        identical(service.unpackSpareParts(ambiguous).state, ambiguous),
        isTrue,
      );
      for (final invalid in [double.nan, double.infinity, -1.0, 1.5]) {
        final bad = initial().copyWith(resources: {'spare_part': invalid});
        expect(service.unpackSpareParts(bad).code, 'invalid_resource');
      }
    },
  );

  test('completed unpacked-spare repair consumes exactly one spare', () {
    final starting = initial().copyWith(
      facilities: {'solar_array': 1},
      damagedUnits: {'solar_array': 1},
    );
    final startingPacked = starting.packedStock['spare_part']!;
    var state = service.unpackSpareParts(starting).state;
    expect(state.packedStock.containsKey('spare_part'), isFalse);
    expect(state.resources['spare_part'], startingPacked);
    final unpackedPackedStock = Map<String, int>.from(state.packedStock);
    final beforeRepair = Map<String, double>.from(state.resources);

    final started = service.start(
      state,
      jobId: 'completed-repair',
      kind: 'major_repair',
      targetId: 'solar_array',
      observation: observation(state, now),
    );
    expect(started.code, 'active');
    state = started.state;
    expect(state.resources['spare_part'], startingPacked - 1);
    expect(state.jobs['completed-repair']!.paid['spare_part'], 1);
    expect(state.jobs['completed-repair']!.reservedStock, isEmpty);
    expect(state.packedStock, unpackedPackedStock);

    state = service.reconcile(
      state,
      observation: observation(
        state,
        state.jobs['completed-repair']!.deadlineUtc!,
      ),
    );
    expect(state.jobs['completed-repair']!.status, 'completed');
    expect(state.resources['spare_part'], beforeRepair['spare_part']! - 1);
    expect(state.packedStock, unpackedPackedStock);
    expect(state.facilities, starting.facilities);
    expect(state.damagedUnits['solar_array'], 0);
    final afterCompletion = Map<String, double>.from(state.resources);
    final completionTime = state.jobs['completed-repair']!.finishedAtUtc;

    state = service.reconcile(
      state,
      observation: observation(state, now.add(const Duration(days: 1))),
    );
    expect(state.jobs['completed-repair']!.status, 'completed');
    expect(state.jobs['completed-repair']!.finishedAtUtc, completionTime);
    expect(state.resources, afterCompletion);
    expect(state.packedStock, unpackedPackedStock);
    expect(state.facilities, starting.facilities);

    for (final days in [2, 3]) {
      final cancel = service.cancel(
        state,
        jobId: 'completed-repair',
        observation: observation(state, now.add(Duration(days: days))),
      );
      expect(cancel.code, 'not_cancellable');
      expect(cancel.state.jobs['completed-repair']!.status, 'completed');
      expect(cancel.state.resources, afterCompletion);
      expect(cancel.state.packedStock, unpackedPackedStock);
      expect(cancel.state.resources['spare_part'], startingPacked - 1);
      expect(cancel.state.facilities, starting.facilities);
      state = cancel.state;
    }
  });

  test(
    'inconsistent installed lifecycle states are rejected before payment',
    () {
      for (final status in ['notBuilt', 'underConstruction', 'invented']) {
        final state = initial().copyWith(
          facilities: {'solar_array': 1},
          operatingStates: {'solar_array': status},
        );
        final result = service.start(
          state,
          jobId: 'invalid',
          kind: 'construction',
          targetId: 'solar_array',
          observation: observation(state, now),
        );
        expect(result.code, 'invalid_operating_state');
        expect(result.state.resources, state.resources);
        expect(result.state.packedStock, state.packedStock);
        expect(
          () => FacilityMapping.toSimulation(state),
          throwsFormatException,
        );
      }
    },
  );

  test('adding a unit leaves installed units operating and does not apply an upgrade', () {
    var state = initial().copyWith(facilities: {'solar_array': 1});
    state = start(state, 'extra', 'solar_array');
    expect(FacilityMapping.toSimulation(state)['solar_array']!.workingUnits, 1);
    state = service.reconcile(
      state,
      observation: observation(state, state.jobs['extra']!.deadlineUtc!),
    );
    expect(FacilityMapping.toSimulation(state)['solar_array']!.units, 2);
    expect(FacilityMapping.toSimulation(state)['solar_array']!.tier, 1);
  });
}
