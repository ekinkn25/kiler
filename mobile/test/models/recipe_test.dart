import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/models/recipe.dart';

void main() {
  test('Recipe.fromJson _id aliasini dogru okur', () {
    final json = {
      '_id': '6a732db3dfd2dca131c56952',
      'title': 'Mercimek Çorbası',
      'slug': 'mercimek-corbasi',
      'description': 'Klasik Türk mercimek çorbası',
      'image_url': null,
      'ingredients': [
        {
          'name': 'Kırmızı Mercimek',
          'canonical_name': 'kirmizi_mercimek',
          'quantity': 200,
          'unit': 'g',
          'optional': false,
          'note': null,
        },
      ],
      'steps': ['Soğanı kavur', 'Mercimeği ekle'],
      'servings': 4,
      'prep_time': 10,
      'cook_time': 30,
      'difficulty': 'kolay',
      'calories_per_serving': 220.5,
      'macros': {'protein_g': 12, 'carb_g': 30, 'fat_g': 4, 'fiber_g': 6},
      'diet_tags': ['vejetaryen'],
      'allergens': [],
      'cuisine': 'turk',
      'source': null,
      'source_url': null,
      'is_active': true,
    };

    final recipe = Recipe.fromJson(json);

    expect(recipe.id, '6a732db3dfd2dca131c56952');
    expect(recipe.title, 'Mercimek Çorbası');
    expect(recipe.ingredients, hasLength(1));
    expect(recipe.ingredients.first.canonicalName, 'kirmizi_mercimek');
    expect(recipe.macros.proteinG, 12);
    expect(recipe.dietTags, ['vejetaryen']);
  });
}