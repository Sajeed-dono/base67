import 'dart:convert';

class UnsupportedSaveVersion extends FormatException {
  UnsupportedSaveVersion(int version)
    : super('Unsupported campaign version: $version');
}

class TimerJobSave {
  const TimerJobSave({
    required this.id,
    required this.category,
    required this.startedAtUtc,
    required this.expectedCompletionAtUtc,
    this.status = 'active',
    this.rewardApplied = false,
    this.targetId,
    this.assignedCrewRole,
  });

  final String id;
  final String category;
  final DateTime startedAtUtc;
  final DateTime expectedCompletionAtUtc;
  final String status;
  final bool rewardApplied;
  final String? targetId;
  final String? assignedCrewRole;

  Map<String, Object?> toJson() => {
    'id': id,
    'category': category,
    'started_at_utc': startedAtUtc.toUtc().toIso8601String(),
    'expected_completion_at_utc': expectedCompletionAtUtc
        .toUtc()
        .toIso8601String(),
    'status': status,
    'reward_applied': rewardApplied,
    'target_id': targetId,
    'assigned_crew_role': assignedCrewRole,
  };

  factory TimerJobSave.fromJson(Map<String, dynamic> json) => TimerJobSave(
    id: json['id'] as String,
    category: json['category'] as String,
    startedAtUtc: DateTime.parse(json['started_at_utc'] as String).toUtc(),
    expectedCompletionAtUtc: DateTime.parse(
      json['expected_completion_at_utc'] as String,
    ).toUtc(),
    status: json['status'] as String? ?? 'active',
    rewardApplied: json['reward_applied'] as bool? ?? false,
    targetId: json['target_id'] as String?,
    assignedCrewRole: json['assigned_crew_role'] as String?,
  );
}

class CampaignSave {
  const CampaignSave({
    this.version = 2,
    this._completedLevelIds = const {},
    this.unlockedLevelIds = const {'L01_first_light'},
    this._completedActivityIds = const {},
    this.crewNames = const {},
    this.crewAges = const {},
    this.crewAppearance = const {},
    this.selectedSiteId,
    this.startingCargo = const {},
    this._inventory = const {},
    this._buildingLevels = const {},
    this._resources = const {},
    this.resourceCapacities = const {},
    this._completedResearchIds = const {},
    this._timerJobs = const [],
    this.levelResults = const {},
    this.badgeIds = const {},
    this.notebookFactIds = const {},
    this.missionPatchId,
    this.playerDisplayName,
    this.deterministicSeed,
    this.eventHistory = const [],
    this.settings = const {},
    this.prologueComplete = false,
    this.progressionJson,
    this.missionJson,
    this.legacyTimerJobs = const [],
  });

  final int version;
  final Set<String> _completedLevelIds;
  final Set<String> unlockedLevelIds;
  final Set<String> _completedActivityIds;
  final Map<String, String> crewNames;
  final Map<String, int> crewAges;
  final Map<String, Map<String, int>> crewAppearance;
  final String? selectedSiteId;
  final Map<String, int> startingCargo;
  final Map<String, int> _inventory;
  final Map<String, int> _buildingLevels;
  final Map<String, double> _resources;
  final Map<String, double> resourceCapacities;
  final Set<String> _completedResearchIds;
  final List<TimerJobSave> _timerJobs;
  final Map<String, Object?> levelResults;
  final Set<String> badgeIds;
  final Set<String> notebookFactIds;
  final String? missionPatchId;
  final String? playerDisplayName;
  final int? deterministicSeed;
  final List<String> eventHistory;
  final Map<String, Object?> settings;
  final bool prologueComplete;

  /// Immutable canonical aggregate encoding. Schema 2 constructors remain
  /// available for historical codecs/fixtures and the unchanged prologue.
  final String? progressionJson;
  /// Optional schema-3 teaching/environment checkpoint. Ownership stays in
  /// progressionJson; older saves have no mission until one is opened.
  final String? missionJson;
  final List<TimerJobSave> legacyTimerJobs;
  Map<String, dynamic>? get _progression => progressionJson == null
      ? null
      : jsonDecode(progressionJson!) as Map<String, dynamic>;
  Set<String> get completedLevelIds => _progression == null
      ? _completedLevelIds
      : Set.unmodifiable(_set(_progression!['completedLevels']));
  Set<String> get completedActivityIds => _progression == null
      ? _completedActivityIds
      : Set.unmodifiable(_set(_progression!['completedActivityIds']));
  Set<String> get completedResearchIds => _progression == null
      ? _completedResearchIds
      : Set.unmodifiable(_set(_progression!['completedResearch']));
  Map<String, int> get inventory => _progression == null
      ? _inventory
      : Map.unmodifiable(_intMap(_progression!['packedStock']));
  Map<String, double> get resources => _progression == null
      ? _resources
      : Map.unmodifiable(_doubleMap(_progression!['resources']));
  Map<String, int> get buildingLevels {
    final p = _progression;
    if (p == null) {
      return _buildingLevels;
    }
    final tiers = _intMap(p['upgradeTiers']);
    return Map.unmodifiable({
      for (final e in _intMap(p['facilities']).entries)
        if (e.value > 0) e.key: 1 + (tiers[e.key] ?? 0),
    });
  }

  List<TimerJobSave> get timerJobs {
    final p = _progression;
    if (p == null) {
      return _timerJobs;
    }
    return List.unmodifiable([
      ...legacyTimerJobs,
      for (final raw in (p['jobs'] as Map).values)
        if ((raw as Map)['clock'] != null)
          TimerJobSave(
            id: raw['id'] as String,
            category: (raw['recipe'] as Map)['kind'] as String,
            targetId: (raw['recipe'] as Map)['targetId'] as String,
            startedAtUtc: DateTime.parse(
              raw['clock']['startedAtUtc'] as String,
            ),
            // Display projection only; original deadlines remain in the aggregate.
            expectedCompletionAtUtc:
                DateTime.parse(raw['clock']['observedAtUtc'] as String).add(
                  Duration(
                    microseconds: raw['clock']['remainingMicros'] as int,
                  ),
                ),
            status: raw['status'] as String,
            rewardApplied: raw['status'] == 'completed',
            assignedCrewRole: raw['crewId'] as String?,
          ),
    ]);
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    if (version < 3) 'completedLevelIds': _sorted(completedLevelIds),
    'unlockedLevelIds': _sorted(unlockedLevelIds),
    if (version < 3) 'completedActivityIds': _sorted(completedActivityIds),
    'crewNames': crewNames,
    'crewAges': crewAges,
    'crewAppearance': crewAppearance,
    'selectedSiteId': selectedSiteId,
    'startingCargo': startingCargo,
    if (version < 3) 'inventory': inventory,
    if (version < 3) 'buildingLevels': buildingLevels,
    if (version < 3) 'resources': resources,
    'resourceCapacities': resourceCapacities,
    if (version < 3) 'completedResearchIds': _sorted(completedResearchIds),
    if (version < 3) 'timerJobs': timerJobs.map((job) => job.toJson()).toList(),
    'levelResults': levelResults,
    'badgeIds': _sorted(badgeIds),
    'notebookFactIds': _sorted(notebookFactIds),
    'missionPatchId': missionPatchId,
    'playerDisplayName': playerDisplayName,
    'deterministicSeed': deterministicSeed,
    'eventHistory': eventHistory,
    'settings': settings,
    'prologueComplete': prologueComplete,
    if (version == 3) 'progression': _progression,
    if (version == 3 && missionJson != null) 'mission': jsonDecode(missionJson!),
    if (version == 3 && legacyTimerJobs.isNotEmpty)
      'legacyTimerJobs': legacyTimerJobs.map((job) => job.toJson()).toList(),
  };

  factory CampaignSave.fromJson(Map<String, dynamic> json) {
    final version = json['version'] ?? 1;
    if (version is! int) {
      throw const FormatException('Invalid campaign version');
    }
    if (version < 1 || version > 3) {
      throw UnsupportedSaveVersion(version);
    }
    if (json.keys.any((key) => !_knownKeys.contains(key))) {
      throw const FormatException(
        'Unsupported campaign fields; save preserved',
      );
    }
    if (version == 3 &&
        (json['progression'] is! Map<String, dynamic> ||
            const [
              'inventory',
              'buildingLevels',
              'resources',
              'completedResearchIds',
              'completedActivityIds',
              'completedLevelIds',
              'timerJobs',
            ].any(json.containsKey))) {
      throw const FormatException(
        'Schema 3 requires one authoritative aggregate',
      );
    }
    if (version < 3 &&
        (json.containsKey('progression') ||
            json.containsKey('legacyTimerJobs') || json.containsKey('mission'))) {
      throw const FormatException('Unexpected progression in legacy save');
    }
    return CampaignSave(
      version: (json['version'] as int? ?? 1) < 2 ? 2 : json['version'] as int,
      completedLevelIds: _set(json['completedLevelIds']),
      unlockedLevelIds: _set(
        json['unlockedLevelIds'],
        fallback: const ['L01_first_light'],
      ),
      completedActivityIds: _set(json['completedActivityIds']),
      crewNames: _stringMap(json['crewNames']),
      crewAges: _intMap(json['crewAges']),
      crewAppearance: _nestedIntMap(json['crewAppearance']),
      selectedSiteId: json['selectedSiteId'] as String?,
      startingCargo: _intMap(json['startingCargo']),
      inventory: _intMap(json['inventory']),
      buildingLevels: _intMap(json['buildingLevels']),
      resources: _doubleMap(json['resources']),
      resourceCapacities: _doubleMap(json['resourceCapacities']),
      completedResearchIds: _set(json['completedResearchIds']),
      timerJobs: (json['timerJobs'] as List? ?? const [])
          .map((row) => TimerJobSave.fromJson(row as Map<String, dynamic>))
          .toList(),
      levelResults: _objectMap(json['levelResults']),
      badgeIds: _set(json['badgeIds']),
      notebookFactIds: _set(json['notebookFactIds']),
      missionPatchId: json['missionPatchId'] as String?,
      playerDisplayName: json['playerDisplayName'] as String?,
      deterministicSeed: json['deterministicSeed'] as int?,
      eventHistory: _listOfStrings(json['eventHistory']),
      settings: _objectMap(json['settings']),
      prologueComplete: json['prologueComplete'] as bool? ?? false,
      progressionJson: version == 3 ? jsonEncode(json['progression']) : null,
      missionJson: json['mission'] == null ? null : jsonEncode(json['mission']),
      legacyTimerJobs: (json['legacyTimerJobs'] as List? ?? const [])
          .map((row) => TimerJobSave.fromJson(row as Map<String, dynamic>))
          .toList(),
    );
  }

  String encode() => jsonEncode(toJson());

  static CampaignSave decode(String value) =>
      CampaignSave.fromJson(jsonDecode(value) as Map<String, dynamic>);

  CampaignSave copyWith({
    int? version,
    String? progressionJson,
    String? missionJson,
    List<TimerJobSave>? legacyTimerJobs,
    Set<String>? completedLevelIds,
    Set<String>? unlockedLevelIds,
    Set<String>? completedActivityIds,
    List<TimerJobSave>? timerJobs,
    Map<String, Object?>? settings,
    Map<String, String>? crewNames,
    Map<String, int>? crewAges,
    Map<String, Map<String, int>>? crewAppearance,
    String? selectedSiteId,
    Map<String, int>? startingCargo,
    Map<String, int>? inventory,
    Map<String, int>? buildingLevels,
    Map<String, double>? resources,
    Map<String, double>? resourceCapacities,
    Set<String>? completedResearchIds,
    Map<String, Object?>? levelResults,
    Set<String>? badgeIds,
    Set<String>? notebookFactIds,
    String? missionPatchId,
    String? playerDisplayName,
    int? deterministicSeed,
    List<String>? eventHistory,
    bool? prologueComplete,
  }) {
    if (this.progressionJson != null &&
        (completedLevelIds != null ||
            completedActivityIds != null ||
            completedResearchIds != null ||
            inventory != null ||
            buildingLevels != null ||
            resources != null ||
            timerJobs != null)) {
      throw StateError(
        'Mutate schema-3 progression through CampaignController',
      );
    }
    return CampaignSave(
      version: version ?? this.version,
      progressionJson: progressionJson ?? this.progressionJson,
      missionJson: missionJson ?? this.missionJson,
      legacyTimerJobs: legacyTimerJobs ?? this.legacyTimerJobs,
      completedLevelIds: completedLevelIds ?? this.completedLevelIds,
      unlockedLevelIds: unlockedLevelIds ?? this.unlockedLevelIds,
      completedActivityIds: completedActivityIds ?? this.completedActivityIds,
      crewNames: crewNames ?? this.crewNames,
      crewAges: crewAges ?? this.crewAges,
      crewAppearance: crewAppearance ?? this.crewAppearance,
      selectedSiteId: selectedSiteId ?? this.selectedSiteId,
      startingCargo: startingCargo ?? this.startingCargo,
      inventory: inventory ?? this.inventory,
      buildingLevels: buildingLevels ?? this.buildingLevels,
      resources: resources ?? this.resources,
      resourceCapacities: resourceCapacities ?? this.resourceCapacities,
      completedResearchIds: completedResearchIds ?? this.completedResearchIds,
      timerJobs: timerJobs ?? this.timerJobs,
      levelResults: levelResults ?? this.levelResults,
      badgeIds: badgeIds ?? this.badgeIds,
      notebookFactIds: notebookFactIds ?? this.notebookFactIds,
      missionPatchId: missionPatchId ?? this.missionPatchId,
      playerDisplayName: playerDisplayName ?? this.playerDisplayName,
      deterministicSeed: deterministicSeed ?? this.deterministicSeed,
      eventHistory: eventHistory ?? this.eventHistory,
      settings: settings ?? this.settings,
      prologueComplete: prologueComplete ?? this.prologueComplete,
    );
  }

  static List<String> _sorted(Set<String> values) => values.toList()..sort();
  static Set<String> _set(Object? value, {List<String> fallback = const []}) =>
      Set<String>.from(value as List? ?? fallback);
  static List<String> _listOfStrings(Object? value) =>
      List<String>.from(value as List? ?? const []);
  static Map<String, String> _stringMap(Object? value) =>
      Map<String, String>.from(value as Map? ?? const {});
  static Map<String, Map<String, int>> _nestedIntMap(Object? value) => {
    for (final entry in (value as Map? ?? const {}).entries)
      entry.key as String: Map<String, int>.from(
        entry.value as Map? ?? const {},
      ),
  };
  static Map<String, int> _intMap(Object? value) =>
      Map<String, int>.from(value as Map? ?? const {});
  static Map<String, double> _doubleMap(Object? value) => {
    for (final entry in (value as Map? ?? const {}).entries)
      entry.key as String: (entry.value as num).toDouble(),
  };
  static Map<String, Object?> _objectMap(Object? value) =>
      Map<String, Object?>.from(value as Map? ?? const {});

  /// In-memory adapter for the unchanged prologue. Never persist this projection.
  CampaignSave legacySnapshot() {
    final json = toJson()
      ..remove('progression')
      ..remove('mission')
      ..remove('legacyTimerJobs');
    json.addAll({
      'version': 2,
      'completedLevelIds': _sorted(completedLevelIds),
      'completedActivityIds': _sorted(completedActivityIds),
      'inventory': inventory,
      'buildingLevels': buildingLevels,
      'resources': resources,
      'completedResearchIds': _sorted(completedResearchIds),
      'timerJobs': timerJobs.map((job) => job.toJson()).toList(),
    });
    return CampaignSave.fromJson(json);
  }

  static const _knownKeys = {
    'version',
    'completedLevelIds',
    'unlockedLevelIds',
    'completedActivityIds',
    'crewNames',
    'crewAges',
    'crewAppearance',
    'selectedSiteId',
    'startingCargo',
    'inventory',
    'buildingLevels',
    'resources',
    'resourceCapacities',
    'completedResearchIds',
    'timerJobs',
    'levelResults',
    'badgeIds',
    'notebookFactIds',
    'missionPatchId',
    'playerDisplayName',
    'deterministicSeed',
    'eventHistory',
    'settings',
    'prologueComplete',
    'progression',
    'mission',
    'legacyTimerJobs',
  };
}
