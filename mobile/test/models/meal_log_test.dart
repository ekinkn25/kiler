import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/models/enums.dart';
import 'package:kalori/models/meal_log.dart';

void main() {
  test('MealLog.fromJson tur/kaynak enumlarini dogru cevirir', () {
    final json = {
      'id': 5,
      'logged_date': '2026-08-13',
      'meal_type': 'ogle',
      'source': 'manuel',
      'item_name': 'Mercimek Çorbası',
      'servings': 1.0,
      'quantity_g': null,
      'calories': 220.0,
      'protein_g': 12.0,
      'carb_g': 30.0,
      'fat_g': 4.0,
      'recipe_id': null,
      'created_at': '2026-08-13T12:00:00Z',
    };

    final meal = MealLog.fromJson(json);

    expect(meal.mealType, MealType.ogle);
    expect(meal.source, LogSource.manuel);
    expect(meal.itemName, 'Mercimek Çorbası');
    expect(meal.calories, 220.0);
  });
}