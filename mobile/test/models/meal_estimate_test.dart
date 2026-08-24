import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/models/meal_estimate.dart';

void main() {
  test('MealEstimate.fromJson tum alanlari okur', () {
    final json = {
      'dish_name': 'Mercimek Çorbası',
      'portion': 'orta',
      'estimated_grams': 300.0,
      'confidence': 0.8,
      'scale_reference_found': true,
      'calories': 250.0,
      'macros': {'protein_g': 12.0, 'carb_g': 40.0, 'fat_g': 6.0, 'fiber_g': 5.0},
      'match_source': 'recipe',
      'portion_options': [
        {'portion': 'kucuk', 'grams': 210.0, 'calories': 175.0},
        {'portion': 'orta', 'grams': 300.0, 'calories': 250.0},
        {'portion': 'buyuk', 'grams': 420.0, 'calories': 350.0},
      ],
      'image_hash': 'abc123',
    };

    final tahmin = MealEstimate.fromJson(json);

    expect(tahmin.dishName, 'Mercimek Çorbası');
    expect(tahmin.portion, 'orta');
    expect(tahmin.calories, 250.0);
    expect(tahmin.proteinG, 12.0);
    expect(tahmin.portionOptions.length, 3);
    expect(tahmin.portionOptions[2].calories, 350.0);
    expect(tahmin.scaleReferenceFound, isTrue);
  });

  test('kalori ve makro null gelebilir', () {
    final json = {
      'dish_name': 'Bilinmeyen',
      'portion': 'orta',
      'estimated_grams': 200.0,
      'confidence': 0.3,
      'scale_reference_found': false,
      'calories': null,
      'macros': null,
      'match_source': 'none',
      'portion_options': [],
      'image_hash': 'x',
    };

    final tahmin = MealEstimate.fromJson(json);

    expect(tahmin.calories, isNull);
    expect(tahmin.proteinG, isNull);
    expect(tahmin.portionOptions, isEmpty);
  });
}