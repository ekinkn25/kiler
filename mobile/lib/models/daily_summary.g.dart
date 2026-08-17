// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DailySummary _$DailySummaryFromJson(Map<String, dynamic> json) =>
    _DailySummary(
      loggedDate: DateTime.parse(json['logged_date'] as String),
      calorieTarget: (json['calorie_target'] as num).toDouble(),
      caloriesConsumed: (json['calories_consumed'] as num).toDouble(),
      caloriesRemaining: (json['calories_remaining'] as num).toDouble(),
      macrosConsumed: MacroBreakdown.fromJson(
        json['macros_consumed'] as Map<String, dynamic>,
      ),
      macrosTarget: MacroBreakdown.fromJson(
        json['macros_target'] as Map<String, dynamic>,
      ),
      meals: (json['meals'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          k,
          (e as List<dynamic>)
              .map((e) => MealLog.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      ),
    );

Map<String, dynamic> _$DailySummaryToJson(_DailySummary instance) =>
    <String, dynamic>{
      'logged_date': instance.loggedDate.toIso8601String(),
      'calorie_target': instance.calorieTarget,
      'calories_consumed': instance.caloriesConsumed,
      'calories_remaining': instance.caloriesRemaining,
      'macros_consumed': instance.macrosConsumed,
      'macros_target': instance.macrosTarget,
      'meals': instance.meals,
    };

_MacroBreakdown _$MacroBreakdownFromJson(Map<String, dynamic> json) =>
    _MacroBreakdown(
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbG: (json['carb_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$MacroBreakdownToJson(_MacroBreakdown instance) =>
    <String, dynamic>{
      'protein_g': instance.proteinG,
      'carb_g': instance.carbG,
      'fat_g': instance.fatG,
      'fiber_g': instance.fiberG,
    };
