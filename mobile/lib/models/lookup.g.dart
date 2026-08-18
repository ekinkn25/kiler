// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lookup.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DietTag _$DietTagFromJson(Map<String, dynamic> json) => _DietTag(
  id: (json['id'] as num).toInt(),
  code: json['code'] as String,
  displayName: json['display_name'] as String,
);

Map<String, dynamic> _$DietTagToJson(_DietTag instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'display_name': instance.displayName,
};

_Allergen _$AllergenFromJson(Map<String, dynamic> json) => _Allergen(
  id: (json['id'] as num).toInt(),
  code: json['code'] as String,
  displayName: json['display_name'] as String,
);

Map<String, dynamic> _$AllergenToJson(_Allergen instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'display_name': instance.displayName,
};
