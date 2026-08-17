// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pantry_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PantryItem _$PantryItemFromJson(Map<String, dynamic> json) => _PantryItem(
  id: (json['id'] as num).toInt(),
  ingredient: IngredientSummary.fromJson(
    json['ingredient'] as Map<String, dynamic>,
  ),
  product: json['product'] == null
      ? null
      : ProductSummary.fromJson(json['product'] as Map<String, dynamic>),
  availability: availabilityFromJson(json['availability'] as String),
  source: pantrySourceFromJson(json['source'] as String),
  confirmedAt: json['confirmed_at'] == null
      ? null
      : DateTime.parse(json['confirmed_at'] as String),
  confidenceExpiresAt: json['confidence_expires_at'] == null
      ? null
      : DateTime.parse(json['confidence_expires_at'] as String),
  daysRemaining: (json['days_remaining'] as num?)?.toInt(),
  detectedConfidence: (json['detected_confidence'] as num?)?.toDouble(),
  quantityBase: (json['quantity_base'] as num?)?.toDouble(),
  displayUnit: _unitOrNull(json['display_unit'] as String?),
  expiryDate: json['expiry_date'] == null
      ? null
      : DateTime.parse(json['expiry_date'] as String),
  isActive: json['is_active'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  isLow: json['is_low'] as bool,
  displayQuantity: (json['display_quantity'] as num).toDouble(),
);

Map<String, dynamic> _$PantryItemToJson(_PantryItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ingredient': instance.ingredient,
      'product': instance.product,
      'availability': availabilityToJson(instance.availability),
      'source': pantrySourceToJson(instance.source),
      'confirmed_at': instance.confirmedAt?.toIso8601String(),
      'confidence_expires_at': instance.confidenceExpiresAt?.toIso8601String(),
      'days_remaining': instance.daysRemaining,
      'detected_confidence': instance.detectedConfidence,
      'quantity_base': instance.quantityBase,
      'display_unit': _unitOrNullJson(instance.displayUnit),
      'expiry_date': instance.expiryDate?.toIso8601String(),
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'is_low': instance.isLow,
      'display_quantity': instance.displayQuantity,
    };

_IngredientSummary _$IngredientSummaryFromJson(Map<String, dynamic> json) =>
    _IngredientSummary(
      id: (json['id'] as num).toInt(),
      canonicalName: json['canonical_name'] as String,
      displayName: json['display_name'] as String,
      caloriesPer100g: (json['calories_per_100g'] as num?)?.toDouble(),
      isStaple: json['is_staple'] as bool? ?? false,
    );

Map<String, dynamic> _$IngredientSummaryToJson(_IngredientSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'canonical_name': instance.canonicalName,
      'display_name': instance.displayName,
      'calories_per_100g': instance.caloriesPer100g,
      'is_staple': instance.isStaple,
    };

_ProductSummary _$ProductSummaryFromJson(Map<String, dynamic> json) =>
    _ProductSummary(
      id: (json['id'] as num).toInt(),
      barcode: json['barcode'] as String?,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      caloriesPer100g: (json['calories_per_100g'] as num?)?.toDouble(),
      imageUrl: json['image_url'] as String?,
    );

Map<String, dynamic> _$ProductSummaryToJson(_ProductSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'barcode': instance.barcode,
      'name': instance.name,
      'brand': instance.brand,
      'calories_per_100g': instance.caloriesPer100g,
      'image_url': instance.imageUrl,
    };
