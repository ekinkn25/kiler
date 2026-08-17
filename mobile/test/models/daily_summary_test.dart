import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/models/daily_summary.dart';

void main() {
  test('DailySummary.fromJson meal_type anahtarli haritayi dogru ayristirir', () {
    final json = {
      'logged_date': '2026-08-13',
      'calorie_target': 2200.0,
      'calories_consumed': 755.0,
      'calories_remaining': 1445.0,
      'macros_consumed': {'protein_g': 60.0, 'carb_g': 41.1, 'fat_g': 33.0, 'fiber_g': 0.0},
      'macros_target': {'protein_g': 120.0, 'carb_g': 250.0, 'fat_g': 70.0, 'fiber_g': 0.0},
      'meals': {
        'kahvalti': [
          {
            'id': 1,
            'logged_date': '2026-08-13',
            'meal_type': 'kahvalti',
            'source': 'manuel',
            'item_name': 'Yumurta',
            'servings': 1.0,
            'quantity_g': null,
            'calories': 155.0,
            'protein_g': 13.0,
            'carb_g': 1.1,
            'fat_g': 11.0,
            'recipe_id': null,
            'created_at': '2026-08-13T08:00:00Z',
          },
        ],
        'ogle': <Map<String, dynamic>>[],
        'aksam': <Map<String, dynamic>>[],
        'atistirma': <Map<String, dynamic>>[],
      },
    };

    final ozet = DailySummary.fromJson(json);

    expect(ozet.caloriesConsumed, 755.0);
    expect(ozet.macrosConsumed.proteinG, 60.0);
    expect(ozet.meals['kahvalti'], hasLength(1));
    expect(ozet.meals['kahvalti']!.first.itemName, 'Yumurta');
    expect(ozet.meals['ogle'], isEmpty);
  });
}