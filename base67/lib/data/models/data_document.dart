import 'data_class.dart';

typedef JsonObject = Map<String, dynamic>;

class DataFileMetadata {
  const DataFileMetadata({
    this.file,
    this.version,
    this.dataClass,
    this.status,
    required this.values,
  });

  final String? file;
  final String? version;
  final DataClass? dataClass;
  final String? status;
  final Map<String, Object?> values;

  factory DataFileMetadata.fromJson(Object? value) {
    final raw = value is Map<String, dynamic> ? value : <String, dynamic>{};
    return DataFileMetadata(
      file: raw['file'] as String?,
      version: raw['version'] as String?,
      dataClass: dataClassFromString(raw['data_class'] as String?),
      status: raw['status'] as String?,
      values: Map.unmodifiable({
        for (final entry in raw.entries) entry.key: typedValue(entry.value),
      }),
    );
  }
}

/// A typed wrapper for a record in any bundled JSON collection.
/// Nested objects and arrays are recursively converted to DataRecord/list values.
class DataRecord {
  const DataRecord(this.fields);

  final Map<String, Object?> fields;

  String? string(String key) => fields[key] as String?;
  num? number(String key) => fields[key] as num?;
  bool? boolean(String key) => fields[key] as bool?;
  List<Object?>? list(String key) => fields[key] as List<Object?>?;
  DataRecord? object(String key) => fields[key] as DataRecord?;
  String? get id => string('id');

  factory DataRecord.fromJson(Map<String, dynamic> json) => DataRecord(
    Map.unmodifiable({
      for (final entry in json.entries) entry.key: typedValue(entry.value),
    }),
  );
}

class DataDocument {
  const DataDocument({
    required this.name,
    required this.metadata,
    required this.collections,
    required this.objects,
    required this.values,
  });

  final String name;
  final DataFileMetadata metadata;
  final Map<String, List<Object?>> collections;
  final Map<String, DataRecord> objects;
  final Map<String, Object?> values;

  List<DataRecord> records(String collection) =>
      (collections[collection] ?? const <Object?>[])
          .whereType<DataRecord>()
          .toList();

  factory DataDocument.fromJson(String name, Map<String, dynamic> json) {
    final collections = <String, List<Object?>>{};
    final objects = <String, DataRecord>{};
    final values = <String, Object?>{};
    for (final entry in json.entries) {
      if (entry.key == '_meta') continue;
      final value = entry.value;
      if (value is List) {
        collections[entry.key] = List.unmodifiable(value.map(typedValue));
      } else if (value is Map<String, dynamic>) {
        objects[entry.key] = DataRecord.fromJson(value);
      } else {
        values[entry.key] = typedValue(value);
      }
    }
    return DataDocument(
      name: name,
      metadata: DataFileMetadata.fromJson(json['_meta']),
      collections: Map.unmodifiable(collections),
      objects: Map.unmodifiable(objects),
      values: Map.unmodifiable(values),
    );
  }
}

Object? typedValue(Object? value) {
  if (value is Map<String, dynamic>) return DataRecord.fromJson(value);
  if (value is List) return List<Object?>.unmodifiable(value.map(typedValue));
  return value;
}
