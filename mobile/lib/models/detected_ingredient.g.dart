// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detected_ingredient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DetectedIngredient _$DetectedIngredientFromJson(Map<String, dynamic> json) =>
    _DetectedIngredient(
      rawName: json['raw_name'] as String,
      canonicalName: json['canonical_name'] as String?,
      displayName: json['display_name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );

Map<String, dynamic> _$DetectedIngredientToJson(_DetectedIngredient instance) =>
    <String, dynamic>{
      'raw_name': instance.rawName,
      'canonical_name': instance.canonicalName,
      'display_name': instance.displayName,
      'confidence': instance.confidence,
    };
