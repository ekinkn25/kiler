import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe_card.freezed.dart';
part 'recipe_card.g.dart';

/// GET /recipes/deck yanitindaki her bir kart (backend: ScoredRecipeCard).
///
/// DIKKAT: backend'de ayrica DAHA ESKI, artik hicbir ucun DONMEDIGI
/// bir 'RecipeCard' semasi da var (match_ratio alanli, basit). Gercek
/// swipe destesi ScoredRecipeCard donuyor (W2-T06 skorlamasi) - bu
/// yuzden mobil model O'NU esas alir.
@freezed
abstract class RecipeCard with _$RecipeCard {
  const factory RecipeCard({
    required String id,
    required String title,
    required String slug,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'calories_per_serving') required double caloriesPerServing,
    required int servings,
    @JsonKey(name: 'prep_time') int? prepTime,
    @JsonKey(name: 'cook_time') int? cookTime,
    String? difficulty,
    String? cuisine,
    @JsonKey(name: 'diet_tags') @Default([]) List<String> dietTags,
    @Default([]) List<String> allergens,
    @JsonKey(name: 'final_score') required double finalScore,
    @JsonKey(name: 'score_breakdown') required ScoreBreakdown scoreBreakdown,
    @JsonKey(name: 'matched_ingredients') @Default([]) List<String> matchedIngredients,
    @JsonKey(name: 'unknown_ingredients') @Default([]) List<String> unknownIngredients,
    @JsonKey(name: 'missing_ingredients') @Default([]) List<String> missingIngredients,
    @JsonKey(name: 'total_required') @Default(0) int totalRequired,
  }) = _RecipeCard;

  factory RecipeCard.fromJson(Map<String, dynamic> json) => _$RecipeCardFromJson(json);
}

@freezed
abstract class ScoreBreakdown with _$ScoreBreakdown {
  const factory ScoreBreakdown({
    required double pantry,
    required double calorie,
    required double taste,
    required double time,
    required ScoreWeights weights,
  }) = _ScoreBreakdown;

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) =>
      _$ScoreBreakdownFromJson(json);
}

@freezed
abstract class ScoreWeights with _$ScoreWeights {
  const factory ScoreWeights({
    required double pantry,
    required double calorie,
    required double taste,
    required double time,
  }) = _ScoreWeights;

  factory ScoreWeights.fromJson(Map<String, dynamic> json) =>
      _$ScoreWeightsFromJson(json);
}