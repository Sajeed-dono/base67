import 'package:flutter_test/flutter_test.dart';
import 'package:base67/data/repositories/game_data_repository.dart';
import 'package:base67/data/models/data_class.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all bundled source and campaign data loads and validates', () async {
    final repository = await GameDataRepository.load();
    expect(repository.validate(), isEmpty);
    expect(repository.fact('rad_gale_surface'), isNotNull);
    expect(repository.source('S02'), isNotNull);
    expect((repository.campaign['levels'] as List).length, 15);
    expect(repository.dataFile('nasa_data.json'), isNotNull);
    expect(repository.dataFile('campaign.json'), isNotNull);
    expect(repository.dataFile('radio.json')!.records('messages'), isNotEmpty);
    expect(repository.document('credits.md')?['text'], isNotEmpty);
    expect(repository.document('README.md')?['text'], isNotEmpty);
    expect(repository.document('check_data.py')?['text'], isNotEmpty);
    expect(
      repository.typedDocuments.keys,
      containsAll([...originalDataFiles, ...extraDataFiles]),
    );
    expect(
      repository.dataFile('nasa_data.json')!.metadata.dataClass,
      DataClass.nasa,
    );
    expect(
      repository.dataFile('campaign.json')!.metadata.dataClass,
      DataClass.game,
    );
  });

}
