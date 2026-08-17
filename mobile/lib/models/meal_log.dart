import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'meal_log.freezed.dart';
part 'meal_log.g.dart';

/// Ogun kaydi (backend: MealLogRead).
///
/// ANLIK GORUNTU ILKESI: item_name/calories/makrolar backend'de kayit
/// aninda KOPYALANMISTI (bkz. backend app/models/nutrition.py). Bu
/// alanlar urun/tarif sonradan degisse bile SABIT kalir.
@freezed
abstract class MealLog with _$MealLog {
  const factory MealLog({
    required int id,
    @JsonKey(name: 'logged_date') required DateTime loggedDate,
    @JsonKey(name: 'meal_type', fromJson: mealTypeFromJson, toJson: mealTypeToJson)
    required MealType mealType,
    @JsonKey(fromJson: logSourceFromJson, toJson: logSourceToJson)
    required LogSource source,
    @JsonKey(name: 'item_name') required String itemName,
    required double servings,
    @JsonKey(name: 'quantity_g') double? quantityG,
    required double calories,
    @JsonKey(name: 'protein_g') double? proteinG,
    @JsonKey(name: 'carb_g') double? carbG,
    @JsonKey(name: 'fat_g') double? fatG,
    @JsonKey(name: 'recipe_id') String? recipeId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _MealLog;

  factory MealLog.fromJson(Map<String, dynamic> json) => _$MealLogFromJson(json);
}