// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecipeCard _$RecipeCardFromJson(Map<String, dynamic> json) => _RecipeCard(
  id: json['id'] as String,
  title: json['title'] as String,
  slug: json['slug'] as String,
  imageUrl: json['image_url'] as String?,
  caloriesPerServing: (json['calories_per_serving'] as num).toDouble(),
  servings: (json['servings'] as num).toInt(),
  prepTime: (json['prep_time'] as num?)?.toInt(),
  cookTime: (json['cook_time'] as num?)?.toInt(),
  difficulty: json['difficulty'] as String?,
  cuisine: json['cuisine'] as String?,
  dietTags:
      (json['diet_tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  allergens:
      (json['allergens'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  finalScore: (json['final_score'] as num).toDouble(),
  scoreBreakdown: ScoreBreakdown.fromJson(
    json['score_breakdown'] as Map<String, dynamic>,
  ),
  matchedIngredients:
      (json['matched_ingredients'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  unknownIngredients:
      (json['unknown_ingredients'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  missingIngredients:
      (json['missing_ingredients'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  totalRequired: (json['total_required'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$RecipeCardToJson(_RecipeCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'slug': instance.slug,
      'image_url': instance.imageUrl,
      'calories_per_serving': instance.caloriesPerServing,
      'servings': instance.servings,
      'prep_time': instance.prepTime,
      'cook_time': instance.cookTime,
      'difficulty': instance.difficulty,
      'cuisine': instance.cuisine,
      'diet_tags': instance.dietTags,
      'allergens': instance.allergens,
      'final_score': instance.finalScore,
      'score_breakdown': instance.scoreBreakdown,
      'matched_ingredients': instance.matchedIngredients,
      'unknown_ingredients': instance.unknownIngredients,
      'missing_ingredients': instance.missingIngredients,
      'total_required': instance.totalRequired,
    };

_ScoreBreakdown _$ScoreBreakdownFromJson(Map<String, dynamic> json) =>
    _ScoreBreakdown(
      pantry: (json['pantry'] as num).toDouble(),
      calorie: (json['calorie'] as num).toDouble(),
      taste: (json['taste'] as num).toDouble(),
      time: (json['time'] as num).toDouble(),
      weights: ScoreWeights.fromJson(json['weights'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ScoreBreakdownToJson(_ScoreBreakdown instance) =>
    <String, dynamic>{
      'pantry': instance.pantry,
      'calorie': instance.calorie,
      'taste': instance.taste,
      'time': instance.time,
      'weights': instance.weights,
    };

_ScoreWeights _$ScoreWeightsFromJson(Map<String, dynamic> json) =>
    _ScoreWeights(
      pantry: (json['pantry'] as num).toDouble(),
      calorie: (json['calorie'] as num).toDouble(),
      taste: (json['taste'] as num).toDouble(),
      time: (json['time'] as num).toDouble(),
    );

Map<String, dynamic> _$ScoreWeightsToJson(_ScoreWeights instance) =>
    <String, dynamic>{
      'pantry': instance.pantry,
      'calorie': instance.calorie,
      'taste': instance.taste,
      'time': instance.time,
    };
