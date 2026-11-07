enum DataClass { nasa, game, derived }

extension DataClassLabel on DataClass {
  String get label => switch (this) {
    DataClass.nasa => 'NASA DATA',
    DataClass.game => 'GAME VALUE',
    DataClass.derived => 'DERIVED',
  };
}

DataClass? dataClassFromString(String? value) => switch (value) {
  'NASA_DATA' || 'NASA DATA' => DataClass.nasa,
  'GAME_VALUE' || 'GAME VALUE' => DataClass.game,
  'DERIVED' => DataClass.derived,
  _ => null,
};
