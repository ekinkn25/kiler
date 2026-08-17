import 'package:freezed_annotation/freezed_annotation.dart';

import 'meal_log.dart';

part 'daily_summary.freezed.dart';
part 'daily_summary.g.dart';

/// Gunluk kalori ozeti (backend: DailySummary).
@freezed
abstract class DailySummary with _$DailySummary {
  const factory DailySummary({
    @JsonKey(name: 'logged_date') required DateTime loggedDate,
    @JsonKey(name: 'calorie_target') required double calorieTarget,
    @JsonKey(name: 'calories_consumed') required double caloriesConsumed,
    @JsonKey(name: 'calories_remaining') required double caloriesRemaining,
    @JsonKey(name: 'macros_consumed') required MacroBreakdown macrosConsumed,
    @JsonKey(name: 'macros_target') required MacroBreakdown macrosTarget,
    // NEDEN Map<String,...>: backend'de meal_type ENUM anahtarli bir
    // sozluk, ama JSON'da anahtarlar HER ZAMAN metindir ('kahvalti' gibi).
    // Gerekirse cagiran taraf mealTypeFromJson(anahtar) ile enum'a cevirir.
    required Map<String, List<MealLog>> meals,
  }) = _DailySummary;

  factory DailySummary.fromJson(Map<String, dynamic> json) =>
      _$DailySummaryFromJson(json);
}

@freezed
abstract class MacroBreakdown with _$MacroBreakdown {
  const factory MacroBreakdown({
    @JsonKey(name: 'protein_g') @Default(0) double proteinG,
    @JsonKey(name: 'carb_g') @Default(0) double carbG,
    @JsonKey(name: 'fat_g') @Default(0) double fatG,
    @JsonKey(name: 'fiber_g') @Default(0) double fiberG,
  }) = _MacroBreakdown;

  factory MacroBreakdown.fromJson(Map<String, dynamic> json) =>
      _$MacroBreakdownFromJson(json);
}