import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/data_source.dart';
import '../models/data_document.dart';
import '../models/nasa_fact.dart';
import '../validation/data_validator.dart';

const originalDataFiles = <String>[
  'nasa_data.json',
  'sources.json',
  'game_constants.json',
  'sites.json',
  'equipment.json',
  'loads.json',
  'levels.json',
  'events.json',
  'lessons.json',
  'crew.json',
  'radio.json',
  'badges.json',
  'credits.json',
];

const extraDataFiles = <String>[
  'campaign.json',
  'buildings.json',
  'research.json',
  'progression_rules.json',
  'timer_rules.json',
  'resource_economy.json',
  'crew_assignments.json',
  'sim_params.json',
  'site_risk.json',
  'tutorial.json',
  'campaign_operations.json',
  'scoring.json',
  'fact_cards.json',
  'display_text.json',
];

const originalTextFiles = <String>['credits.md', 'README.md', 'check_data.py'];

class GameDataRepository {
  GameDataRepository._(this.documents)
    : typedDocuments = Map.unmodifiable({
        for (final entry in documents.entries)
          if (entry.key.endsWith('.json'))
            entry.key: DataDocument.fromJson(entry.key, entry.value),
      });

  final Map<String, Map<String, dynamic>> documents;
  final Map<String, DataDocument> typedDocuments;
  Map<String, dynamic> get factsJson => documents['nasa_data.json']!;
  Map<String, dynamic> get campaign => documents['campaign.json']!;
  String get appTitle =>
      typedDocuments['display_text.json']!.objects['titles']!.string('app') ??
      'BASE 67';

  DataDocument? dataFile(String fileName) => typedDocuments[fileName];

  /// Normalize legacy source text before presentation. The original pack
  /// remains unchanged; replacement rules live in GAME VALUE configuration.
  String displayText(String sourceText) {
    final replacements = typedDocuments['display_text.json']!
        .collections['replacements']!
        .whereType<DataRecord>();
    var output = sourceText;
    for (final replacement in replacements) {
      final source = replacement.string('source');
      final display = replacement.string('display');
      if (source == null || source.isEmpty || display == null) continue;
      output = output.replaceAll(
        RegExp(RegExp.escape(source), caseSensitive: false),
        display,
      );
    }
    return output;
  }

  NasaFact? fact(String id) {
    final facts = factsJson['facts'] as Map<String, dynamic>?;
    final raw = facts?[id];
    return raw is Map<String, dynamic> ? NasaFact.fromJson(id, raw) : null;
  }

  DataSource? source(String id) {
    for (final row in typedDocuments['sources.json']!.records('sources')) {
      if (row.id == id) {
        return DataSource.fromJson(row.fields.cast<String, dynamic>());
      }
    }
    return null;
  }

  Map<String, dynamic>? document(String fileName) => documents[fileName];

  List<String> validate() => DataValidator(documents).validate();

  static Future<GameDataRepository> load({AssetBundle? bundle}) async {
    final assetBundle = bundle ?? rootBundle;
    final documents = <String, Map<String, dynamic>>{};
    for (final file in originalDataFiles) {
      documents[file] = _decode(
        await assetBundle.loadString('assets/data/$file'),
      );
    }
    for (final file in extraDataFiles) {
      documents[file] = _decode(
        await assetBundle.loadString('assets/data/extra/$file'),
      );
    }
    for (final file in originalTextFiles) {
      documents[file] = {
        'text': await assetBundle.loadString('assets/data/$file'),
      };
    }
    return GameDataRepository._(Map.unmodifiable(documents));
  }

  static Map<String, dynamic> _decode(String input) {
    final decoded = jsonDecode(input);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'A data document must contain a JSON object.',
      );
    }
    return decoded;
  }
}
