class NasaFact {
  const NasaFact({required this.id, required this.value, required this.raw});

  final String id;
  final Object value;
  final Map<String, dynamic> raw;

  List<String> get sourceIds =>
      (raw['source_ids'] as List? ?? const []).whereType<String>().toList();

  factory NasaFact.fromJson(String id, Map<String, dynamic> json) => NasaFact(
    id: id,
    value: json['value'] as Object,
    raw: Map.unmodifiable(json),
  );
}
