class DataSource {
  const DataSource({required this.id, required this.url, required this.raw});

  final String id;
  final String url;
  final Map<String, dynamic> raw;

  factory DataSource.fromJson(Map<String, dynamic> json) => DataSource(
    id: json['id'] as String,
    url: json['url'] as String,
    raw: Map.unmodifiable(json),
  );
}
