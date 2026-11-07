import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('original data pack files match supplied source checksums', () async {
    final manifest = jsonDecode(
      await rootBundle.loadString('assets/data/original_pack_sha256.json'),
    ) as Map<String, dynamic>;
    for (final entry in manifest.entries) {
      final bytes = (await rootBundle.load('assets/data/${entry.key}')).buffer
          .asUint8List();
      expect(sha256.convert(bytes).toString(), entry.value, reason: entry.key);
    }
  });
}
