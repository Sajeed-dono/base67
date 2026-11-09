/// Elapsed simulation hours are supplied by the caller, never by a wall clock.
abstract final class SimulationClock {
  // Arithmetic tolerance only, not gameplay pacing or a physical constant.
  static const roundingTolerance = 1e-10;
  static int solIndex(double hours, double solHours) {
    final quotient = hours / solHours;
    final nearest = quotient.round();
    return (hours - nearest * solHours).abs() < roundingTolerance
        ? nearest
        : quotient.floor();
  }

  static double hourOfSol(double hours, double solHours) {
    final remainder = hours % solHours;
    return remainder < roundingTolerance ||
            solHours - remainder < roundingTolerance
        ? 0
        : remainder;
  }

  static double untilNextSol(double hours, double solHours) =>
      solHours - hourOfSol(hours, solHours);
}
