import 'dart:convert';

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
    this.completedLevelIds = const {},
    this.unlockedLevelIds = const {'L01_first_light'},
    this.completedActivityIds = const {},
    this.crewNames = const {},
    this.crewAges = const {},
    this.crewAppearance = const {},
    this.selectedSiteId,
    this.startingCargo = const {},
    this.inventory = const {},
    this.buildingLevels = const {},
    this.resources = const {},
    this.resourceCapacities = const {},
    this.completedResearchIds = const {},
    this.timerJobs = const [],
    this.levelResults = const {},
    this.badgeIds = const {},
    this.notebookFactIds = const {},
    this.missionPatchId,
    this.playerDisplayName,
    this.deterministicSeed,
    this.eventHistory = const [],
    this.settings = const {},
    this.prologueComplete = false,
  });

  final int version;
  final Set<String> completedLevelIds;
  final Set<String> unlockedLevelIds;
  final Set<String> completedActivityIds;
  final Map<String, String> crewNames;
  final Map<String, int> crewAges;
  final Map<String, Map<String, int>> crewAppearance;
  final String? selectedSiteId;
  final Map<String, int> startingCargo;
  final Map<String, int> inventory;
  final Map<String, int> buildingLevels;
  final Map<String, double> resources;
  final Map<String, double> resourceCapacities;
  final Set<String> completedResearchIds;
  final List<TimerJobSave> timerJobs;
  final Map<String, Object?> levelResults;
  final Set<String> badgeIds;
  final Set<String> notebookFactIds;
  final String? missionPatchId;
  final String? playerDisplayName;
  final int? deterministicSeed;
  final List<String> eventHistory;
  final Map<String, Object?> settings;
  final bool prologueComplete;

  Map<String, dynamic> toJson() => {
    'version': version,
    'completedLevelIds': _sorted(completedLevelIds),
    'unlockedLevelIds': _sorted(unlockedLevelIds),
    'completedActivityIds': _sorted(completedActivityIds),
    'crewNames': crewNames,
    'crewAges': crewAges,
    'crewAppearance': crewAppearance,
    'selectedSiteId': selectedSiteId,
    'startingCargo': startingCargo,
    'inventory': inventory,
    'buildingLevels': buildingLevels,
    'resources': resources,
    'resourceCapacities': resourceCapacities,
    'completedResearchIds': _sorted(completedResearchIds),
    'timerJobs': timerJobs.map((job) => job.toJson()).toList(),
    'levelResults': levelResults,
    'badgeIds': _sorted(badgeIds),
    'notebookFactIds': _sorted(notebookFactIds),
    'missionPatchId': missionPatchId,
    'playerDisplayName': playerDisplayName,
    'deterministicSeed': deterministicSeed,
    'eventHistory': eventHistory,
    'settings': settings,
    'prologueComplete': prologueComplete,
  };

  factory CampaignSave.fromJson(Map<String, dynamic> json) => CampaignSave(
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
        .whereType<Map<String, dynamic>>()
        .map(TimerJobSave.fromJson)
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
  );

  String encode() => jsonEncode(toJson());

  static CampaignSave decode(String value) =>
      CampaignSave.fromJson(jsonDecode(value) as Map<String, dynamic>);

  CampaignSave copyWith({
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
  }) => CampaignSave(
    version: version,
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

  static List<String> _sorted(Set<String> values) => values.toList()..sort();
  static Set<String> _set(Object? value, {List<String> fallback = const []}) =>
      Set<String>.from(value as List? ?? fallback);
  static List<String> _listOfStrings(Object? value) =>
      (value as List? ?? const []).whereType<String>().toList();
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
}
