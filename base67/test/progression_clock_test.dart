import 'package:base67/progression/progression_clock.dart';
import 'package:base67/progression/progression_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'progression_service_test.dart' show configuration, observation;

void main() {
  final now = DateTime.utc(2026, 11, 10, 12);
  const duration = Duration(minutes: 5);

  test('delayed and duplicate observations cannot count an interval twice', () {
    final capturedStart = ClockObservation(token: 0, utc: now);
    final capturedOld = ClockObservation(token: 1, utc: now);
    final capturedLater = ClockObservation(
      token: 2,
      utc: now.add(const Duration(minutes: 2)),
    );
    var clock = ProgressionClock.start(
      capturedStart,
      duration,
    ).observe(capturedLater);
    expect(clock.remaining, const Duration(minutes: 3));
    for (var i = 0; i < 10; i++) {
      expect(identical(clock.observe(capturedOld), clock), isTrue);
      expect(identical(clock.observe(capturedLater), clock), isTrue);
    }
    clock = clock.observe(ClockObservation(token: 3, utc: capturedLater.utc));
    expect(clock.remaining, const Duration(minutes: 3));
    clock = clock.observe(
      ClockObservation(token: 4, utc: now.add(const Duration(minutes: 5))),
    );
    expect(clock.isDue, isTrue);
    expect(clock.originalDeadlineUtc, now.add(duration));
    expect(() => ClockObservation(token: -1, utc: now), throwsFormatException);
  });

  test(
    'fresh observations are consumed even when the requested start is invalid',
    () {
      final service = RealTimeProgressionService(configuration());
      var state = service.resupply(
        ProgressionState(levelId: configuration().levels.last),
      );
      state = service
          .start(
            state,
            jobId: 'active',
            kind: 'construction',
            targetId: 'solar_array',
            observation: ClockObservation(token: 0, utc: now),
          )
          .state;
      final invalid = service.start(
        state,
        jobId: 'invalid',
        kind: 'construction',
        targetId: 'invented',
        observation: ClockObservation(
          token: 2,
          utc: now.subtract(const Duration(days: 1)),
        ),
      );
      expect(invalid.code, 'unknown_recipe');
      state = invalid.state;
      expect(state.lastObservationToken, 2);
      expect(state.jobs['active']!.clock!.remaining, duration);
      final delayed = ClockObservation(
        token: 1,
        utc: now.add(const Duration(days: 1)),
      );
      expect(
        identical(service.reconcile(state, observation: delayed), state),
        isTrue,
      );
      expect(
        service
            .start(
              state,
              jobId: 'invalid',
              kind: 'construction',
              targetId: 'invented',
              observation: ClockObservation(token: 2, utc: now),
            )
            .code,
        'stale_observation',
      );
      expect(state.jobs.containsKey('invalid'), isFalse);
      expect(state.facilities, isEmpty);
      expect(state.materials, 75);
    },
  );

  test('stale start, activate, cancel and reconcile preserve the entire snapshot', () {
    final config = configuration();
    final service = RealTimeProgressionService(config);
    var state = service.resupply(ProgressionState(levelId: config.levels.last));
    state = service
        .start(
          state,
          jobId: 'active',
          kind: 'construction',
          targetId: 'solar_array',
          observation: ClockObservation(token: 10, utc: now),
        )
        .state;
    state = service
        .enqueue(
          state,
          jobId: 'queued',
          kind: 'construction',
          targetId: 'battery_bank',
        )
        .state;
    state = state.copyWith(pending: {'materials': 20});
    final staleFuture = ClockObservation(token: 9, utc: DateTime.utc(2099));
    final duplicateFuture = ClockObservation(
      token: 10,
      utc: DateTime.utc(2099),
    );
    for (final input in [staleFuture, duplicateFuture]) {
      final start = service.start(
        state,
        jobId: 'never-enqueued',
        kind: 'construction',
        targetId: 'battery_bank',
        observation: input,
      );
      expect(start.code, 'stale_observation');
      expect(identical(start.state, state), isTrue);
      final activate = service.activate(
        state,
        jobId: 'queued',
        observation: input,
      );
      expect(activate.code, 'stale_observation');
      expect(identical(activate.state, state), isTrue);
      final cancel = service.cancel(state, jobId: 'active', observation: input);
      expect(cancel.code, 'stale_observation');
      expect(identical(cancel.state, state), isTrue);
      expect(
        identical(service.reconcile(state, observation: input), state),
        isTrue,
      );
    }
    // A newly captured rollback is accepted, not mistaken for delayed delivery.
    state = service.reconcile(
      state,
      observation: ClockObservation(token: 11, utc: DateTime.utc(2020)),
    );
    expect(state.lastObservationToken, 11);
    expect(state.jobs['active']!.clock!.remaining, duration);
    state = service
        .cancel(
          state,
          jobId: 'active',
          observation: ClockObservation(
            token: 12,
            utc: DateTime.utc(2020).add(duration),
          ),
        )
        .state;
    expect(state.jobs['active']!.status, 'completed');
    expect(state.facilities['solar_array'], 1);
    expect(state.jobs['queued']!.status, 'queued');
    expect(state.jobs.containsKey('never-enqueued'), isFalse);
  });

  test(
    'rollback preserves remaining work and moves the observation checkpoint',
    () {
      var clock = ProgressionClock.start(
        ClockObservation(token: 0, utc: now),
        duration,
      );
      final deadline = clock.originalDeadlineUtc;
      clock = clock.observe(
        ClockObservation(
          token: clock.observationToken + 1,
          utc: now.add(const Duration(minutes: 2)),
        ),
      );
      expect(clock.remaining, const Duration(minutes: 3));
      clock = clock.observe(
        ClockObservation(
          token: clock.observationToken + 1,
          utc: now.subtract(const Duration(days: 100)),
        ),
      );
      expect(clock.remaining, const Duration(minutes: 3));
      expect(clock.rollbackCount, 1);
      clock = clock.observe(
        ClockObservation(
          token: clock.observationToken + 1,
          utc: clock.observedAtUtc.add(const Duration(minutes: 3)),
        ),
      );
      expect(clock.isDue, isTrue);
      expect(clock.originalDeadlineUtc, deadline);
      expect(
        identical(
          clock.observe(
            ClockObservation(
              token: clock.observationToken + 1,
              utc: now.subtract(const Duration(days: 500)),
            ),
          ),
          clock,
        ),
        isTrue,
      );
    },
  );

  test('repeated corrections never increase remaining or alter original timestamps', () {
    var clock = ProgressionClock.start(
      ClockObservation(token: 0, utc: now),
      duration,
    );
    for (final offset in [30, -100000, -99970, 60, -999999, -999900, 999999]) {
      final before = clock;
      clock = clock.observe(
        ClockObservation(
          token: clock.observationToken + 1,
          utc: now.add(Duration(seconds: offset)),
        ),
      );
      expect(clock.remaining <= before.remaining, isTrue);
      expect(clock.startedAtUtc, now);
      expect(clock.originalDeadlineUtc, now.add(duration));
    }
    expect(clock.isDue, isTrue);
    expect(
      () => ProgressionClock.start(
        ClockObservation(token: 0, utc: now),
        Duration.zero,
      ),
      throwsFormatException,
    );
  });

  test(
    'future clock, correction and new work cannot contaminate new timestamps',
    () {
      final service = RealTimeProgressionService(configuration());
      var state = service.resupply(
        ProgressionState(levelId: configuration().levels.last),
      );
      state = service.reconcile(
        state,
        observation: observation(state, DateTime.utc(2099)),
      );
      state = service
          .start(
            state,
            jobId: 'new',
            kind: 'construction',
            targetId: 'solar_array',
            observation: observation(state, now),
          )
          .state;
      expect(state.jobs['new']!.startedAtUtc, now);
      expect(state.jobs['new']!.deadlineUtc, now.add(duration));
      state = service.reconcile(
        state,
        observation: observation(state, now.add(duration)),
      );
      expect(state.jobs['new']!.status, 'completed');
    },
  );

  test(
    'forward completion then rollback never reverses effects or receipts',
    () {
      final service = RealTimeProgressionService(configuration());
      var state = service.resupply(
        ProgressionState(levelId: configuration().levels.last),
      );
      state = service
          .start(
            state,
            jobId: 'solar',
            kind: 'construction',
            targetId: 'solar_array',
            observation: observation(state, now),
          )
          .state;
      state = service.reconcile(
        state,
        observation: observation(state, DateTime.utc(2099)),
      );
      final finished = state.jobs['solar']!.finishedAtUtc;
      final balance = state.resources;
      for (final time in [DateTime.utc(2000), now, DateTime.utc(2100)]) {
        state = RealTimeProgressionService(configuration())
            .reconcile(state, observation: observation(state, time));
        expect(state.jobs['solar']!.status, 'completed');
        expect(state.jobs['solar']!.finishedAtUtc, finished);
        expect(state.facilities['solar_array'], 1);
        expect(state.resources, balance);
        expect(state.completedActivityIds, {'solar'});
        expect(service.remaining(state, 'solar'), Duration.zero);
      }
      expect(
        service
            .cancel(state, jobId: 'solar', observation: observation(state, now))
            .code,
        'not_cancellable',
      );
    },
  );

  test('work started at wrong future time can finish after correction and pure continuation', () {
    final config = configuration();
    var service = RealTimeProgressionService(config);
    var state = service.resupply(ProgressionState(levelId: config.levels.last));
    state = service
        .start(
          state,
          jobId: 'future',
          kind: 'construction',
          targetId: 'solar_array',
          observation: observation(state, DateTime.utc(2099)),
        )
        .state;
    final deadline = state.jobs['future']!.deadlineUtc;
    state = service.reconcile(state, observation: observation(state, now));
    expect(service.remaining(state, 'future'), duration);
    service = RealTimeProgressionService(config);
    state = service.reconcile(
      state,
      observation: observation(state, now.add(duration)),
    );
    expect(state.jobs['future']!.status, 'completed');
    expect(state.jobs['future']!.deadlineUtc, deadline);
  });
}
