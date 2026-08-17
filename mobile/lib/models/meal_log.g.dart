// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MealLog _$MealLogFromJson(Map<String, dynamic> json) => _MealLog(
  id: (json['id'] as num).toInt(),
  loggedDate: DateTime.parse(json['logged_date'] as String),
  mealType: mealTypeFromJson(json['meal_type'] as String),
  source: logSourceFromJson(json['source'] as String),
  itemName: json['item_name'] as String,
  servings: (json['servings'] as num).toDouble(),
  quantityG: (json['quantity_g'] as num?)?.toDouble(),
  calories: (json['calories'] as num).toDouble(),
  proteinG: (json['protein_g'] as num?)?.toDouble(),
  carbG: (json['carb_g'] as num?)?.toDouble(),
  fatG: (json['fat_g'] as num?)?.toDouble(),
  recipeId: json['recipe_id'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$MealLogToJson(_MealLog instance) => <String, dynamic>{
  'id': instance.id,
  'logged_date': instance.loggedDate.toIso8601String(),
  'meal_type': mealTypeToJson(instance.mealType),
  'source': logSourceToJson(instance.source),
  'item_name': instance.itemName,
  'servings': instance.servings,
  'quantity_g': instance.quantityG,
  'calories': instance.calories,
  'protein_g': instance.proteinG,
  'carb_g': instance.carbG,
  'fat_g': instance.fatG,
  'recipe_id': instance.recipeId,
  'created_at': instance.createdAt.toIso8601String(),
};
