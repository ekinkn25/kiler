// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Recipe _$RecipeFromJson(Map<String, dynamic> json) => _Recipe(
  id: json['_id'] as String,
  title: json['title'] as String,
  slug: json['slug'] as String,
  description: json['description'] as String?,
  imageUrl: json['image_url'] as String?,
  ingredients: (json['ingredients'] as List<dynamic>)
      .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
      .toList(),
  steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
  servings: (json['servings'] as num).toInt(),
  prepTime: (json['prep_time'] as num?)?.toInt() ?? 0,
  cookTime: (json['cook_time'] as num?)?.toInt() ?? 0,
  difficulty: json['difficulty'] as String? ?? 'orta',
  caloriesPerServing: (json['calories_per_serving'] as num).toDouble(),
  macros: RecipeMacros.fromJson(json['macros'] as Map<String, dynamic>),
  dietTags:
      (json['diet_tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  allergens:
      (json['allergens'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  cuisine: json['cuisine'] as String? ?? 'turk',
  source: json['source'] as String?,
  sourceUrl: json['source_url'] as String?,
  isActive: json['is_active'] as bool? ?? true,
);

Map<String, dynamic> _$RecipeToJson(_Recipe instance) => <String, dynamic>{
  '_id': instance.id,
  'title': instance.title,
  'slug': instance.slug,
  'description': instance.description,
  'image_url': instance.imageUrl,
  'ingredients': instance.ingredients,
  'steps': instance.steps,
  'servings': instance.servings,
  'prep_time': instance.prepTime,
  'cook_time': instance.cookTime,
  'difficulty': instance.difficulty,
  'calories_per_serving': instance.caloriesPerServing,
  'macros': instance.macros,
  'diet_tags': instance.dietTags,
  'allergens': instance.allergens,
  'cuisine': instance.cuisine,
  'source': instance.source,
  'source_url': instance.sourceUrl,
  'is_active': instance.isActive,
};

_RecipeIngredient _$RecipeIngredientFromJson(Map<String, dynamic> json) =>
    _RecipeIngredient(
      name: json['name'] as String,
      canonicalName: json['canonical_name'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: _unitOrNull(json['unit'] as String?),
      optional: json['optional'] as bool? ?? false,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$RecipeIngredientToJson(_RecipeIngredient instance) =>
    <String, dynamic>{
      'name': instance.name,
      'canonical_name': instance.canonicalName,
      'quantity': instance.quantity,
      'unit': _unitOrNullJson(instance.unit),
      'optional': instance.optional,
      'note': instance.note,
    };

_RecipeMacros _$RecipeMacrosFromJson(Map<String, dynamic> json) =>
    _RecipeMacros(
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbG: (json['carb_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$RecipeMacrosToJson(_RecipeMacros instance) =>
    <String, dynamic>{
      'protein_g': instance.proteinG,
      'carb_g': instance.carbG,
      'fat_g': instance.fatG,
      'fiber_g': instance.fiberG,
    };
