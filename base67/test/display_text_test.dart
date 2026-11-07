import 'dart:convert';
import 'dart:io';

import 'package:base67/data/repositories/game_data_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'legacy source display text resolves to the current game title',
    () async {
      final repository = await GameDataRepository.load();
      expect(repository.appTitle, 'BASE 67');
      expect(repository.displayText('Outpost Zero'), 'BASE 67');

      final radio = repository.dataFile('radio.json')!;
      final renderedMessages = radio
          .records('messages')
          .map(
            (message) => repository.displayText(message.string('text') ?? ''),
          );
      expect(renderedMessages, everyElement(isNot(contains('Outpost Zero'))));

      for (final document in repository.documents.entries.where(
        (entry) => entry.key != 'display_text.json',
      )) {
        for (final sourceText in _allStrings(document.value)) {
          final uiText = repository.displayText(sourceText).toLowerCase();
          expect(uiText, isNot(contains('outpost zero')), reason: document.key);
        }
      }
    },
  );

  test('no Dart UI source contains the obsolete game name', () {
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in sources) {
      final content = utf8.decode(file.readAsBytesSync());
      expect(
        content.toLowerCase(),
        isNot(contains('outpost zero')),
        reason: file.path,
      );
    }
  });
}

Iterable<String> _allStrings(Object? value) sync* {
  if (value is String) {
    yield value;
  } else if (value is Map) {
    for (final nested in value.values) {
      yield* _allStrings(nested);
    }
  } else if (value is Iterable) {
    for (final nested in value) {
      yield* _allStrings(nested);
    }
  }
}
