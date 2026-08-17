import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/models/detected_ingredient.dart';

void main() {
  test('DetectedIngredient.fromJson eslesen ve eslesmeyen durumlari okur', () {
    final eslesen = DetectedIngredient.fromJson({
      'raw_name': 'domates',
      'canonical_name': 'domates',
      'display_name': 'Domates',
      'confidence': 0.95,
    });
    final eslesmeyen = DetectedIngredient.fromJson({
      'raw_name': 'zencefil kökü',
      'canonical_name': null,
      'display_name': 'Zencefil kökü',
      'confidence': 0.28,
    });

    expect(eslesen.canonicalName, 'domates');
    expect(eslesmeyen.canonicalName, isNull);
    expect(eslesmeyen.confidence, 0.28);
  });
}