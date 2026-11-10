/// Producer captures token and UTC together, before asynchronous delivery.
/// Tokens increase in capture order across the aggregate, including rollbacks.
/// Never attach a fresh token to an old timestamp at delivery time.
class ClockObservation {
  ClockObservation({required this.token, required DateTime utc})
    : utc = utc.toUtc() {
    if (token < 0) throw const FormatException('Negative observation token');
  }
  final int token;
  final DateTime utc;
}

/// Caller-supplied UTC only. No device clock or simulation time is read here.
class ProgressionClock {
  ProgressionClock._(
    this.startedAtUtc,
    this.originalDeadlineUtc,
    this.duration,
    this.remaining,
    this.observedAtUtc,
    this.rollbackCount,
    this.observationToken,
  );

  factory ProgressionClock.start(
    ClockObservation observation,
    Duration duration,
  ) {
    if (duration <= Duration.zero) {
      throw const FormatException('Job duration must be positive');
    }
    final now = observation.utc;
    return ProgressionClock._(
      now,
      now.add(duration),
      duration,
      duration,
      now,
      0,
      observation.token,
    );
  }

  final DateTime startedAtUtc, originalDeadlineUtc, observedAtUtc;
  final Duration duration, remaining;
  final int rollbackCount, observationToken;
  bool get isDue => remaining == Duration.zero;

  /// Restores a validated checkpoint without observing time or granting work.
  factory ProgressionClock.restore({
    required DateTime startedAtUtc,
    required DateTime originalDeadlineUtc,
    required Duration duration,
    required Duration remaining,
    required DateTime observedAtUtc,
    required int rollbackCount,
    required int observationToken,
  }) {
    if (!startedAtUtc.isUtc || !originalDeadlineUtc.isUtc ||
        !observedAtUtc.isUtc || duration <= Duration.zero ||
        remaining < Duration.zero || remaining > duration ||
        originalDeadlineUtc.difference(startedAtUtc) != duration ||
        rollbackCount < 0 || observationToken < 0) {
      throw const FormatException('Invalid progression clock checkpoint');
    }
    return ProgressionClock._(
      startedAtUtc, originalDeadlineUtc, duration, remaining, observedAtUtc,
      rollbackCount, observationToken,
    );
  }

  ProgressionClock observe(ClockObservation observation) {
    // Terminal checkpoints never reverse or acquire another completion time.
    if (isDue || observation.token <= observationToken) return this;
    final now = observation.utc;
    final delta = now.difference(observedAtUtc);
    final elapsed = delta.isNegative ? Duration.zero : delta;
    final left = elapsed >= remaining ? Duration.zero : remaining - elapsed;
    return ProgressionClock._(
      startedAtUtc,
      originalDeadlineUtc,
      duration,
      left,
      now,
      rollbackCount + (delta.isNegative ? 1 : 0),
      observation.token,
    );
  }
}
