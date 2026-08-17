import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';
part 'recipe.freezed.dart';
part 'recipe.g.dart';

//tarif detayı

@freezed
abstract class Recipe with _$Recipe {
  const factory Recipe({
    @JsonKey(name:'_id') required String id,
    required String title, 
    required String slug,
    String? description,
    @JsonKey(name: 'image_url') String? imageUrl,
    required List<RecipeIngredient> ingredients,
    required List<String> steps,
    required int servings,
    @JsonKey(name: 'prep_time') @Default(0) int prepTime,
    @JsonKey(name: 'cook_time') @Default(0) int cookTime,
    @Default('orta') String difficulty,
    @JsonKey(name: 'calories_per_serving') required double caloriesPerServing,
    required RecipeMacros macros,
    @JsonKey(name: 'diet_tags') @Default([]) List<String> dietTags,
    @Default([]) List<String> allergens,
    @Default('turk') String cuisine,
    String? source,
    @JsonKey(name: 'source_url') String? sourceUrl,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _Recipe;

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);

}

@freezed
abstract class RecipeIngredient with _$RecipeIngredient {
  const factory RecipeIngredient({
    required String name,
    @JsonKey(name: 'canonical_name') String? canonicalName,
    double? quantity,
    @JsonKey(fromJson: _unitOrNull, toJson: _unitOrNullJson) UnitCode? unit,
    @Default(false) bool optional,
    String? note,
  }) = _RecipeIngredient;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      _$RecipeIngredientFromJson(json);
}

UnitCode? _unitOrNull(String? value) => value == null ? null : unitCodeFromJson(value);
String? _unitOrNullJson(UnitCode? value) => value == null ? null : unitCodeToJson(value);

@freezed
abstract class RecipeMacros with _$RecipeMacros {
  const factory RecipeMacros({
    @JsonKey(name: 'protein_g') @Default(0) double proteinG,
    @JsonKey(name: 'carb_g') @Default(0) double carbG,
    @JsonKey(name: 'fat_g') @Default(0) double fatG,
    @JsonKey(name: 'fiber_g') @Default(0) double fiberG,
  }) = _RecipeMacros;

  factory RecipeMacros.fromJson(Map<String, dynamic> json) =>
      _$RecipeMacrosFromJson(json);
}