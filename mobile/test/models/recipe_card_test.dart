import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/models/recipe_card.dart';

void main() {
  test('RecipeCard.fromJson skor kirilimini dogru okur', () {
    final json = {
      'id': '6a732db3dfd2dca131c56952',
      'title': 'Domates Soslu Makarna',
      'slug': 'domates-soslu-makarna',
      'image_url': null,
      'calories_per_serving': 410.0,
      'servings': 2,
      'prep_time': 10,
      'cook_time': 20,
      'difficulty': 'kolay',
      'cuisine': 'italyan',
      'diet_tags': ['vejetaryen'],
      'allergens': ['gluten'],
      'final_score': 0.4649,
      'score_breakdown': {
        'pantry': 0.1667,
        'calorie': 0.908,
        'taste': 0.5,
        'time': 1.0,
        'weights': {'pantry': 0.5, 'calorie': 0.2, 'taste': 0.2, 'time': 0.1},
      },
      'matched_ingredients': ['domates'],
      'unknown_ingredients': [],
      'missing_ingredients': ['makarna', 'sarimsak'],
      'total_required': 6,
    };

    final card = RecipeCard.fromJson(json);

    expect(card.id, '6a732db3dfd2dca131c56952');
    expect(card.finalScore, 0.4649);
    expect(card.scoreBreakdown.weights.pantry, 0.5);
    expect(card.matchedIngredients, ['domates']);
    expect(card.allergens, ['gluten']);
  });
}