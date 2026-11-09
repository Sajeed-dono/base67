import 'sim_config.dart';

class SimNotice {
  const SimNotice(this.code, this.detail);
  final String code, detail;
  Map<String, Object> toJson() => {'code': code, 'detail': detail};
}

/// Numerical guard used at runtime, including when callers supply bad state.
double finiteNumber(
  double value,
  double fallback,
  List<SimNotice> notices,
  String field,
) {
  if (value.isFinite) return value;
  notices.add(SimNotice('non_finite_clamped', field));
  return fallback;
}

double bounded(
  double value,
  double lower,
  double upper,
  List<SimNotice> notices,
  String field,
) {
  final finite = finiteNumber(value, lower, notices, field);
  final result = finite.clamp(lower, upper).toDouble();
  if (result != finite) notices.add(SimNotice('value_clamped', field));
  return result;
}

class ResourceChange {
  const ResourceChange(this.source, this.amount, this.dataClass);
  final String source;
  final double amount;
  final DataClass dataClass;
  Map<String, Object> toJson() => {
    'source': source,
    'amount': amount,
    'data_class': dataClass.name,
  };
}

class ResourceState {
  ResourceState({
    required this.quantity,
    required this.capacity,
    this.productionPerHour = 0,
    this.consumptionPerHour = 0,
    this.dataClass = DataClass.derived,
    Iterable<ResourceChange> changes = const [],
  }) : changes = List.unmodifiable(changes);
  final double quantity, capacity, productionPerHour, consumptionPerHour;
  final DataClass dataClass;
  final List<ResourceChange> changes;
  Map<String, Object> toJson() => {
    'quantity': quantity,
    'capacity': capacity,
    'production_per_hour': productionPerHour,
    'consumption_per_hour': consumptionPerHour,
    'data_class': dataClass.name,
    'changes': changes.map((c) => c.toJson()).toList(),
  };
}

enum FacilityStatus {
  notBuilt,
  operating,
  off,
  damaged,
  underConstruction,
  outOfResources,
}

class FacilityState {
  const FacilityState({
    this.units = 0,
    this.damagedUnits = 0,
    this.tier = 1,
    this.status = FacilityStatus.notBuilt,
    this.enabled = true,
  });
  final int units, damagedUnits, tier;
  final FacilityStatus status;
  final bool enabled;
  int get storageUnits =>
      status == FacilityStatus.notBuilt ||
          status == FacilityStatus.underConstruction
      ? 0
      : (units - damagedUnits).clamp(0, units < 0 ? 0 : units);
  int get workingUnits {
    if (!enabled ||
        (status != FacilityStatus.operating &&
            status != FacilityStatus.damaged)) {
      return 0;
    }
    return (units - damagedUnits).clamp(0, units < 0 ? 0 : units);
  }

  FacilityState copyWith({
    int? units,
    int? damagedUnits,
    int? tier,
    FacilityStatus? status,
    bool? enabled,
  }) => FacilityState(
    units: units ?? this.units,
    damagedUnits: damagedUnits ?? this.damagedUnits,
    tier: tier ?? this.tier,
    status: status ?? this.status,
    enabled: enabled ?? this.enabled,
  );
  Map<String, Object> toJson() => {
    'units': units,
    'damaged_units': damagedUnits,
    'tier': tier,
    'status': status.name,
    'enabled': enabled,
  };
}

class ActiveEvent {
  const ActiveEvent(this.id, this.startHour, this.endHour);
  final String id;
  final double startHour, endHour;
  Map<String, Object> toJson() => {
    'id': id,
    'start_hour': startHour,
    'end_hour': endHour,
  };
}

/// Pure snapshots, not campaign persistence or a real-time job ledger.
class SimState {
  SimState({
    required this.siteId,
    required this.rngState,
    required this.crewCount,
    this.elapsedHours = 0,
    this.dust = 0,
    this.temperature = 0,
    this.radiation = 0,
    this.cleaningHours = 0,
    this.spareParts = 0,
    this.lastRandomSol = -1,
    this.paused = false,
    Map<String, ResourceState> resources = const {},
    Map<String, FacilityState> facilities = const {},
    Map<String, ActiveEvent> activeEvents = const {},
    Iterable<String> firedScriptIds = const [],
    Iterable<String> researchIds = const [],
  }) : resources = Map.unmodifiable(resources),
       facilities = Map.unmodifiable(facilities),
       activeEvents = Map.unmodifiable(activeEvents),
       firedScriptIds = Set.unmodifiable(firedScriptIds),
       researchIds = Set.unmodifiable(researchIds);

  factory SimState.initial(
    SimConfig config, {
    required String siteId,
    int? seed,
    Map<String, int> equipment = const {},
  }) {
    if (!config.sites.containsKey(siteId)) {
      throw ArgumentError.value(siteId, 'siteId', 'Unknown site');
    }
    final facilities = <String, FacilityState>{};
    for (final spec in config.facilities.values) {
      final count = spec.id == 'crew_habitat'
          ? 1
          : (equipment[spec.equipmentId] ?? 0).clamp(0, 0x7FFFFFFF);
      facilities[spec.id] = FacilityState(
        units: count,
        status: count > 0 ? FacilityStatus.operating : FacilityStatus.notBuilt,
      );
    }
    final capacity =
        (equipment['battery'] ?? 0).clamp(0, 0x7FFFFFFF) *
        config.number('battery_unit_kwh');
    return SimState(
      siteId: siteId,
      rngState: seed ?? config.defaultSeed,
      crewCount: config.number('crew_size').toInt(),
      temperature: config.number('target_temp'),
      spareParts: (equipment['spare_part'] ?? 0).clamp(0, 0x7FFFFFFF),
      facilities: facilities,
      resources: {
        for (final e in config.initial.entries)
          e.key: ResourceState(
            quantity: e.value,
            capacity:
                config.capacities[e.key]! +
                config.facilities.values.fold<double>(
                  0,
                  (sum, spec) =>
                      sum +
                      (spec.expansion[e.key] ?? 0) *
                          (facilities[spec.id]?.storageUnits ?? 0),
                ),
            dataClass: DataClass.game,
          ),
        'battery_kwh': ResourceState(
          quantity: capacity * config.number('battery_start_fraction'),
          capacity: capacity,
        ),
      },
    );
  }

  final String siteId;
  final int rngState, crewCount, spareParts, lastRandomSol;
  final double elapsedHours, dust, temperature, radiation, cleaningHours;
  final bool paused;
  final Map<String, ResourceState> resources;
  final Map<String, FacilityState> facilities;
  final Map<String, ActiveEvent> activeEvents;
  final Set<String> firedScriptIds, researchIds;

  SimState copyWith({
    String? siteId,
    int? rngState,
    int? crewCount,
    int? spareParts,
    int? lastRandomSol,
    double? elapsedHours,
    double? dust,
    double? temperature,
    double? radiation,
    double? cleaningHours,
    bool? paused,
    Map<String, ResourceState>? resources,
    Map<String, FacilityState>? facilities,
    Map<String, ActiveEvent>? activeEvents,
    Iterable<String>? firedScriptIds,
    Iterable<String>? researchIds,
  }) => SimState(
    siteId: siteId ?? this.siteId,
    rngState: rngState ?? this.rngState,
    crewCount: crewCount ?? this.crewCount,
    spareParts: spareParts ?? this.spareParts,
    lastRandomSol: lastRandomSol ?? this.lastRandomSol,
    elapsedHours: elapsedHours ?? this.elapsedHours,
    dust: dust ?? this.dust,
    temperature: temperature ?? this.temperature,
    radiation: radiation ?? this.radiation,
    cleaningHours: cleaningHours ?? this.cleaningHours,
    paused: paused ?? this.paused,
    resources: resources ?? this.resources,
    facilities: facilities ?? this.facilities,
    activeEvents: activeEvents ?? this.activeEvents,
    firedScriptIds: firedScriptIds ?? this.firedScriptIds,
    researchIds: researchIds ?? this.researchIds,
  );

  /// In-memory snapshot restoration only; this layer does not read/write saves.
  factory SimState.fromJson(Map<String, dynamic> json) {
    double number(Map row, String key) => (row[key] as num).toDouble();
    final resources = <String, ResourceState>{};
    for (final e in (json['resources'] as Map).entries) {
      final row = e.value as Map;
      resources[e.key as String] = ResourceState(
        quantity: number(row, 'quantity'),
        capacity: number(row, 'capacity'),
        productionPerHour: number(row, 'production_per_hour'),
        consumptionPerHour: number(row, 'consumption_per_hour'),
        dataClass: DataClass.values.byName(row['data_class'] as String),
        changes: [
          for (final raw in row['changes'] as List)
            ResourceChange(
              (raw as Map)['source'] as String,
              number(raw, 'amount'),
              DataClass.values.byName(raw['data_class'] as String),
            ),
        ],
      );
    }
    return SimState(
      siteId: json['site'] as String,
      rngState: json['rng'] as int,
      crewCount: json['crew'] as int,
      spareParts: json['spares'] as int,
      lastRandomSol: json['last_random_sol'] as int,
      elapsedHours: number(json, 'hours'),
      dust: number(json, 'dust'),
      temperature: number(json, 'temperature'),
      radiation: number(json, 'radiation'),
      cleaningHours: number(json, 'cleaning'),
      paused: json['paused'] as bool,
      resources: resources,
      firedScriptIds: (json['scripts'] as List).cast<String>(),
      researchIds: (json['research'] as List).cast<String>(),
      facilities: {
        for (final e in (json['facilities'] as Map).entries)
          e.key as String: FacilityState(
            units: (e.value as Map)['units'] as int,
            damagedUnits: (e.value as Map)['damaged_units'] as int,
            tier: (e.value as Map)['tier'] as int,
            status: FacilityStatus.values.byName(
              (e.value as Map)['status'] as String,
            ),
            enabled: (e.value as Map)['enabled'] as bool,
          ),
      },
      activeEvents: {
        for (final e in (json['events'] as Map).entries)
          e.key as String: ActiveEvent(
            (e.value as Map)['id'] as String,
            number(e.value as Map, 'start_hour'),
            number(e.value as Map, 'end_hour'),
          ),
      },
    );
  }

  Map<String, Object> toJson() => {
    'site': siteId,
    'rng': rngState,
    'crew': crewCount,
    'spares': spareParts,
    'last_random_sol': lastRandomSol,
    'hours': elapsedHours,
    'dust': dust,
    'temperature': temperature,
    'radiation': radiation,
    'cleaning': cleaningHours,
    'paused': paused,
    'resources': {for (final e in resources.entries) e.key: e.value.toJson()},
    'facilities': {for (final e in facilities.entries) e.key: e.value.toJson()},
    'events': {for (final e in activeEvents.entries) e.key: e.value.toJson()},
    'scripts': firedScriptIds.toList()..sort(),
    'research': researchIds.toList()..sort(),
  };
}
