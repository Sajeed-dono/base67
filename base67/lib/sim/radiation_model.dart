import 'sim_config.dart';
import 'sim_state.dart';

abstract final class RadiationModel {
  static double dose(
    SimConfig config,
    SimState state,
    double hours,
    double spike, {
    required bool sheltered,
  }) {
    final shields = state.facilities['radiation_shelter']?.workingUnits ?? 0;
    // Legacy shielding is additive per working shield, bounded to no dose.
    final shieldFactor = (1 - shields * config.number('shielding_reduction'))
        .clamp(0, 1);
    final shelterFactor = sheltered
        ? 1 - config.number('shelter_reduction')
        : 1.0;
    return (config.number('radiation_per_hour') * hours +
            spike * shelterFactor) *
        shieldFactor *
        config.multiplier('radiation_dose', state.researchIds);
  }
}
