import 'package:freezed_annotation/freezed_annotation.dart';

part 'detected_ingredient.freezed.dart';
part 'detected_ingredient.g.dart';

/// Gorme modelinin tespit ettigi tek malzeme (backend: DetectedIngredient).
/// POST /vision/ingredients, /vision/meal ve /chat (foto ekliyse)
/// yanitlarinda gecer.
@freezed
abstract class DetectedIngredient with _$DetectedIngredient {
  const factory DetectedIngredient({
    @JsonKey(name: 'raw_name') required String rawName,
    @JsonKey(name: 'canonical_name') String? canonicalName,
    @JsonKey(name: 'display_name') required String displayName,
    required double confidence,
  }) = _DetectedIngredient;

  factory DetectedIngredient.fromJson(Map<String, dynamic> json) =>
      _$DetectedIngredientFromJson(json);
}