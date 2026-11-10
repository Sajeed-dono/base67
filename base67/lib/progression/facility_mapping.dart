import '../sim/sim_state.dart';
import 'progression_service.dart';

/// Projects installed facilities only. Never calls SimState.initial, grants
/// resources, transfers stock, advances the engine or changes simulation rules.
abstract final class FacilityMapping {
  static Map<String, FacilityState> toSimulation(ProgressionState state) =>
      Map.unmodifiable({
        for (final id in {
          ...state.facilities.keys,
          ...state.operatingStates.keys,
        })
          id: FacilityState(
            units: state.facilities[id] ?? 0,
            damagedUnits: state.damagedUnits[id] ?? 0,
            tier: 1 + (state.upgradeTiers[id] ?? 0),
            status: (state.facilities[id] ?? 0) == 0
                ? FacilityStatus.notBuilt
                : (state.operatingStates[id] != null
                      ? _operatingStatus(state.operatingStates[id]!)
                      : ((state.damagedUnits[id] ?? 0) > 0
                            ? FacilityStatus.damaged
                            : FacilityStatus.operating)),
          ),
      });

  static FacilityStatus _operatingStatus(String name) {
    final values = FacilityStatus.values.where((value) => value.name == name);
    if (values.isEmpty || name == 'notBuilt' || name == 'underConstruction') {
      throw FormatException(
        'Installed units require an operating state: $name',
      );
    }
    return values.single;
  }
}
