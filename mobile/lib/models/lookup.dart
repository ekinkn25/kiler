import 'package:freezed_annotation/freezed_annotation.dart';

part 'lookup.freezed.dart';
part 'lookup.g.dart';

/// GET /catalog/diet-tags yanitindaki her oge (backend: DietTagRead).
@freezed
abstract class DietTag with _$DietTag {
  const factory DietTag({
    required int id,
    required String code,
    @JsonKey(name: 'display_name') required String displayName,
  }) = _DietTag;

  factory DietTag.fromJson(Map<String, dynamic> json) => _$DietTagFromJson(json);
}

/// GET /catalog/allergens yanitindaki her oge (backend: AllergenRead).
@freezed
abstract class Allergen with _$Allergen {
  const factory Allergen({
    required int id,
    required String code,
    @JsonKey(name: 'display_name') required String displayName,
  }) = _Allergen;

  factory Allergen.fromJson(Map<String, dynamic> json) => _$AllergenFromJson(json);
}