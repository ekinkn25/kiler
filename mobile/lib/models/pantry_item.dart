import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'pantry_item.freezed.dart';
part 'pantry_item.g.dart';

/// Kiler satiri (backend: PantryItemRead).
@freezed
abstract class PantryItem with _$PantryItem {
  const factory PantryItem({
    required int id,
    required IngredientSummary ingredient,
    ProductSummary? product,
    @JsonKey(fromJson: availabilityFromJson, toJson: availabilityToJson)
    required Availability availability,
    @JsonKey(fromJson: pantrySourceFromJson, toJson: pantrySourceToJson)
    required PantrySource source,
    @JsonKey(name: 'confirmed_at') DateTime? confirmedAt,
    @JsonKey(name: 'confidence_expires_at') DateTime? confidenceExpiresAt,
    @JsonKey(name: 'days_remaining') int? daysRemaining,
    @JsonKey(name: 'detected_confidence') double? detectedConfidence,
    @JsonKey(name: 'quantity_base') double? quantityBase,
    @JsonKey(name: 'display_unit', fromJson: _unitOrNull, toJson: _unitOrNullJson)
    UnitCode? displayUnit,
    // @JsonKey(name: 'expiry_date') DateTime? expiryDate,
    // @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    // @JsonKey(name: 'is_low') required bool isLow,
    // @JsonKey(name: 'display_quantity') required double displayQuantity,
  }) = _PantryItem;

  factory PantryItem.fromJson(Map<String, dynamic> json) => _$PantryItemFromJson(json);
}

UnitCode? _unitOrNull(String? value) => value == null ? null : unitCodeFromJson(value);
String? _unitOrNullJson(UnitCode? value) => value == null ? null : unitCodeToJson(value);

/// PantryItem'in ic ice gelen malzeme bilgisi (backend: IngredientRead).
/// NEDEN SADE: kategori nesnesi burada modellenmedi - kiler listesi
/// ekrani buna ihtiyac duymuyor, gerekirse genisletilir.
@freezed
abstract class IngredientSummary with _$IngredientSummary {
  const factory IngredientSummary({
    required int id,
    @JsonKey(name: 'canonical_name') required String canonicalName,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'calories_per_100g') double? caloriesPer100g,
    @JsonKey(name: 'is_staple') @Default(false) bool isStaple,
  }) = _IngredientSummary;

  factory IngredientSummary.fromJson(Map<String, dynamic> json) =>
      _$IngredientSummaryFromJson(json);
}

/// PantryItem'in ic ice gelen urun bilgisi (backend: ProductRead).
@freezed
abstract class ProductSummary with _$ProductSummary {
  const factory ProductSummary({
    required int id,
    String? barcode,
    required String name,
    String? brand,
    @JsonKey(name: 'calories_per_100g') double? caloriesPer100g,
    @JsonKey(name: 'image_url') String? imageUrl,
  }) = _ProductSummary;

  factory ProductSummary.fromJson(Map<String, dynamic> json) =>
      _$ProductSummaryFromJson(json);
}