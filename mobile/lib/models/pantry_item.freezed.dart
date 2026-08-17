// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pantry_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PantryItem {

 int get id; IngredientSummary get ingredient; ProductSummary? get product;@JsonKey(fromJson: availabilityFromJson, toJson: availabilityToJson) Availability get availability;@JsonKey(fromJson: pantrySourceFromJson, toJson: pantrySourceToJson) PantrySource get source;@JsonKey(name: 'confirmed_at') DateTime? get confirmedAt;@JsonKey(name: 'confidence_expires_at') DateTime? get confidenceExpiresAt;@JsonKey(name: 'days_remaining') int? get daysRemaining;@JsonKey(name: 'detected_confidence') double? get detectedConfidence;@JsonKey(name: 'quantity_base') double? get quantityBase;@JsonKey(name: 'display_unit', fromJson: _unitOrNull, toJson: _unitOrNullJson) UnitCode? get displayUnit;@JsonKey(name: 'expiry_date') DateTime? get expiryDate;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'is_low') bool get isLow;@JsonKey(name: 'display_quantity') double get displayQuantity;
/// Create a copy of PantryItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PantryItemCopyWith<PantryItem> get copyWith => _$PantryItemCopyWithImpl<PantryItem>(this as PantryItem, _$identity);

  /// Serializes this PantryItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PantryItem&&(identical(other.id, id) || other.id == id)&&(identical(other.ingredient, ingredient) || other.ingredient == ingredient)&&(identical(other.product, product) || other.product == product)&&(identical(other.availability, availability) || other.availability == availability)&&(identical(other.source, source) || other.source == source)&&(identical(other.confirmedAt, confirmedAt) || other.confirmedAt == confirmedAt)&&(identical(other.confidenceExpiresAt, confidenceExpiresAt) || other.confidenceExpiresAt == confidenceExpiresAt)&&(identical(other.daysRemaining, daysRemaining) || other.daysRemaining == daysRemaining)&&(identical(other.detectedConfidence, detectedConfidence) || other.detectedConfidence == detectedConfidence)&&(identical(other.quantityBase, quantityBase) || other.quantityBase == quantityBase)&&(identical(other.displayUnit, displayUnit) || other.displayUnit == displayUnit)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isLow, isLow) || other.isLow == isLow)&&(identical(other.displayQuantity, displayQuantity) || other.displayQuantity == displayQuantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ingredient,product,availability,source,confirmedAt,confidenceExpiresAt,daysRemaining,detectedConfidence,quantityBase,displayUnit,expiryDate,isActive,createdAt,updatedAt,isLow,displayQuantity);

@override
String toString() {
  return 'PantryItem(id: $id, ingredient: $ingredient, product: $product, availability: $availability, source: $source, confirmedAt: $confirmedAt, confidenceExpiresAt: $confidenceExpiresAt, daysRemaining: $daysRemaining, detectedConfidence: $detectedConfidence, quantityBase: $quantityBase, displayUnit: $displayUnit, expiryDate: $expiryDate, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt, isLow: $isLow, displayQuantity: $displayQuantity)';
}


}

/// @nodoc
abstract mixin class $PantryItemCopyWith<$Res>  {
  factory $PantryItemCopyWith(PantryItem value, $Res Function(PantryItem) _then) = _$PantryItemCopyWithImpl;
@useResult
$Res call({
 int id, IngredientSummary ingredient, ProductSummary? product,@JsonKey(fromJson: availabilityFromJson, toJson: availabilityToJson) Availability availability,@JsonKey(fromJson: pantrySourceFromJson, toJson: pantrySourceToJson) PantrySource source,@JsonKey(name: 'confirmed_at') DateTime? confirmedAt,@JsonKey(name: 'confidence_expires_at') DateTime? confidenceExpiresAt,@JsonKey(name: 'days_remaining') int? daysRemaining,@JsonKey(name: 'detected_confidence') double? detectedConfidence,@JsonKey(name: 'quantity_base') double? quantityBase,@JsonKey(name: 'display_unit', fromJson: _unitOrNull, toJson: _unitOrNullJson) UnitCode? displayUnit,@JsonKey(name: 'expiry_date') DateTime? expiryDate,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'is_low') bool isLow,@JsonKey(name: 'display_quantity') double displayQuantity
});


$IngredientSummaryCopyWith<$Res> get ingredient;$ProductSummaryCopyWith<$Res>? get product;

}
/// @nodoc
class _$PantryItemCopyWithImpl<$Res>
    implements $PantryItemCopyWith<$Res> {
  _$PantryItemCopyWithImpl(this._self, this._then);

  final PantryItem _self;
  final $Res Function(PantryItem) _then;

/// Create a copy of PantryItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ingredient = null,Object? product = freezed,Object? availability = null,Object? source = null,Object? confirmedAt = freezed,Object? confidenceExpiresAt = freezed,Object? daysRemaining = freezed,Object? detectedConfidence = freezed,Object? quantityBase = freezed,Object? displayUnit = freezed,Object? expiryDate = freezed,Object? isActive = null,Object? createdAt = null,Object? updatedAt = null,Object? isLow = null,Object? displayQuantity = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,ingredient: null == ingredient ? _self.ingredient : ingredient // ignore: cast_nullable_to_non_nullable
as IngredientSummary,product: freezed == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as ProductSummary?,availability: null == availability ? _self.availability : availability // ignore: cast_nullable_to_non_nullable
as Availability,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as PantrySource,confirmedAt: freezed == confirmedAt ? _self.confirmedAt : confirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,confidenceExpiresAt: freezed == confidenceExpiresAt ? _self.confidenceExpiresAt : confidenceExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,daysRemaining: freezed == daysRemaining ? _self.daysRemaining : daysRemaining // ignore: cast_nullable_to_non_nullable
as int?,detectedConfidence: freezed == detectedConfidence ? _self.detectedConfidence : detectedConfidence // ignore: cast_nullable_to_non_nullable
as double?,quantityBase: freezed == quantityBase ? _self.quantityBase : quantityBase // ignore: cast_nullable_to_non_nullable
as double?,displayUnit: freezed == displayUnit ? _self.displayUnit : displayUnit // ignore: cast_nullable_to_non_nullable
as UnitCode?,expiryDate: freezed == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isLow: null == isLow ? _self.isLow : isLow // ignore: cast_nullable_to_non_nullable
as bool,displayQuantity: null == displayQuantity ? _self.displayQuantity : displayQuantity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}
/// Create a copy of PantryItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IngredientSummaryCopyWith<$Res> get ingredient {
  
  return $IngredientSummaryCopyWith<$Res>(_self.ingredient, (value) {
    return _then(_self.copyWith(ingredient: value));
  });
}/// Create a copy of PantryItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductSummaryCopyWith<$Res>? get product {
    if (_self.product == null) {
    return null;
  }

  return $ProductSummaryCopyWith<$Res>(_self.product!, (value) {
    return _then(_self.copyWith(product: value));
  });
}
}


/// Adds pattern-matching-related methods to [PantryItem].
extension PantryItemPatterns on PantryItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PantryItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PantryItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PantryItem value)  $default,){
final _that = this;
switch (_that) {
case _PantryItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PantryItem value)?  $default,){
final _that = this;
switch (_that) {
case _PantryItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  IngredientSummary ingredient,  ProductSummary? product, @JsonKey(fromJson: availabilityFromJson, toJson: availabilityToJson)  Availability availability, @JsonKey(fromJson: pantrySourceFromJson, toJson: pantrySourceToJson)  PantrySource source, @JsonKey(name: 'confirmed_at')  DateTime? confirmedAt, @JsonKey(name: 'confidence_expires_at')  DateTime? confidenceExpiresAt, @JsonKey(name: 'days_remaining')  int? daysRemaining, @JsonKey(name: 'detected_confidence')  double? detectedConfidence, @JsonKey(name: 'quantity_base')  double? quantityBase, @JsonKey(name: 'display_unit', fromJson: _unitOrNull, toJson: _unitOrNullJson)  UnitCode? displayUnit, @JsonKey(name: 'expiry_date')  DateTime? expiryDate, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'is_low')  bool isLow, @JsonKey(name: 'display_quantity')  double displayQuantity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PantryItem() when $default != null:
return $default(_that.id,_that.ingredient,_that.product,_that.availability,_that.source,_that.confirmedAt,_that.confidenceExpiresAt,_that.daysRemaining,_that.detectedConfidence,_that.quantityBase,_that.displayUnit,_that.expiryDate,_that.isActive,_that.createdAt,_that.updatedAt,_that.isLow,_that.displayQuantity);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  IngredientSummary ingredient,  ProductSummary? product, @JsonKey(fromJson: availabilityFromJson, toJson: availabilityToJson)  Availability availability, @JsonKey(fromJson: pantrySourceFromJson, toJson: pantrySourceToJson)  PantrySource source, @JsonKey(name: 'confirmed_at')  DateTime? confirmedAt, @JsonKey(name: 'confidence_expires_at')  DateTime? confidenceExpiresAt, @JsonKey(name: 'days_remaining')  int? daysRemaining, @JsonKey(name: 'detected_confidence')  double? detectedConfidence, @JsonKey(name: 'quantity_base')  double? quantityBase, @JsonKey(name: 'display_unit', fromJson: _unitOrNull, toJson: _unitOrNullJson)  UnitCode? displayUnit, @JsonKey(name: 'expiry_date')  DateTime? expiryDate, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'is_low')  bool isLow, @JsonKey(name: 'display_quantity')  double displayQuantity)  $default,) {final _that = this;
switch (_that) {
case _PantryItem():
return $default(_that.id,_that.ingredient,_that.product,_that.availability,_that.source,_that.confirmedAt,_that.confidenceExpiresAt,_that.daysRemaining,_that.detectedConfidence,_that.quantityBase,_that.displayUnit,_that.expiryDate,_that.isActive,_that.createdAt,_that.updatedAt,_that.isLow,_that.displayQuantity);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  IngredientSummary ingredient,  ProductSummary? product, @JsonKey(fromJson: availabilityFromJson, toJson: availabilityToJson)  Availability availability, @JsonKey(fromJson: pantrySourceFromJson, toJson: pantrySourceToJson)  PantrySource source, @JsonKey(name: 'confirmed_at')  DateTime? confirmedAt, @JsonKey(name: 'confidence_expires_at')  DateTime? confidenceExpiresAt, @JsonKey(name: 'days_remaining')  int? daysRemaining, @JsonKey(name: 'detected_confidence')  double? detectedConfidence, @JsonKey(name: 'quantity_base')  double? quantityBase, @JsonKey(name: 'display_unit', fromJson: _unitOrNull, toJson: _unitOrNullJson)  UnitCode? displayUnit, @JsonKey(name: 'expiry_date')  DateTime? expiryDate, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'is_low')  bool isLow, @JsonKey(name: 'display_quantity')  double displayQuantity)?  $default,) {final _that = this;
switch (_that) {
case _PantryItem() when $default != null:
return $default(_that.id,_that.ingredient,_that.product,_that.availability,_that.source,_that.confirmedAt,_that.confidenceExpiresAt,_that.daysRemaining,_that.detectedConfidence,_that.quantityBase,_that.displayUnit,_that.expiryDate,_that.isActive,_that.createdAt,_that.updatedAt,_that.isLow,_that.displayQuantity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PantryItem implements PantryItem {
  const _PantryItem({required this.id, required this.ingredient, this.product, @JsonKey(fromJson: availabilityFromJson, toJson: availabilityToJson) required this.availability, @JsonKey(fromJson: pantrySourceFromJson, toJson: pantrySourceToJson) required this.source, @JsonKey(name: 'confirmed_at') this.confirmedAt, @JsonKey(name: 'confidence_expires_at') this.confidenceExpiresAt, @JsonKey(name: 'days_remaining') this.daysRemaining, @JsonKey(name: 'detected_confidence') this.detectedConfidence, @JsonKey(name: 'quantity_base') this.quantityBase, @JsonKey(name: 'display_unit', fromJson: _unitOrNull, toJson: _unitOrNullJson) this.displayUnit, @JsonKey(name: 'expiry_date') this.expiryDate, @JsonKey(name: 'is_active') required this.isActive, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'is_low') required this.isLow, @JsonKey(name: 'display_quantity') required this.displayQuantity});
  factory _PantryItem.fromJson(Map<String, dynamic> json) => _$PantryItemFromJson(json);

@override final  int id;
@override final  IngredientSummary ingredient;
@override final  ProductSummary? product;
@override@JsonKey(fromJson: availabilityFromJson, toJson: availabilityToJson) final  Availability availability;
@override@JsonKey(fromJson: pantrySourceFromJson, toJson: pantrySourceToJson) final  PantrySource source;
@override@JsonKey(name: 'confirmed_at') final  DateTime? confirmedAt;
@override@JsonKey(name: 'confidence_expires_at') final  DateTime? confidenceExpiresAt;
@override@JsonKey(name: 'days_remaining') final  int? daysRemaining;
@override@JsonKey(name: 'detected_confidence') final  double? detectedConfidence;
@override@JsonKey(name: 'quantity_base') final  double? quantityBase;
@override@JsonKey(name: 'display_unit', fromJson: _unitOrNull, toJson: _unitOrNullJson) final  UnitCode? displayUnit;
@override@JsonKey(name: 'expiry_date') final  DateTime? expiryDate;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey(name: 'is_low') final  bool isLow;
@override@JsonKey(name: 'display_quantity') final  double displayQuantity;

/// Create a copy of PantryItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PantryItemCopyWith<_PantryItem> get copyWith => __$PantryItemCopyWithImpl<_PantryItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PantryItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PantryItem&&(identical(other.id, id) || other.id == id)&&(identical(other.ingredient, ingredient) || other.ingredient == ingredient)&&(identical(other.product, product) || other.product == product)&&(identical(other.availability, availability) || other.availability == availability)&&(identical(other.source, source) || other.source == source)&&(identical(other.confirmedAt, confirmedAt) || other.confirmedAt == confirmedAt)&&(identical(other.confidenceExpiresAt, confidenceExpiresAt) || other.confidenceExpiresAt == confidenceExpiresAt)&&(identical(other.daysRemaining, daysRemaining) || other.daysRemaining == daysRemaining)&&(identical(other.detectedConfidence, detectedConfidence) || other.detectedConfidence == detectedConfidence)&&(identical(other.quantityBase, quantityBase) || other.quantityBase == quantityBase)&&(identical(other.displayUnit, displayUnit) || other.displayUnit == displayUnit)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isLow, isLow) || other.isLow == isLow)&&(identical(other.displayQuantity, displayQuantity) || other.displayQuantity == displayQuantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ingredient,product,availability,source,confirmedAt,confidenceExpiresAt,daysRemaining,detectedConfidence,quantityBase,displayUnit,expiryDate,isActive,createdAt,updatedAt,isLow,displayQuantity);

@override
String toString() {
  return 'PantryItem(id: $id, ingredient: $ingredient, product: $product, availability: $availability, source: $source, confirmedAt: $confirmedAt, confidenceExpiresAt: $confidenceExpiresAt, daysRemaining: $daysRemaining, detectedConfidence: $detectedConfidence, quantityBase: $quantityBase, displayUnit: $displayUnit, expiryDate: $expiryDate, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt, isLow: $isLow, displayQuantity: $displayQuantity)';
}


}

/// @nodoc
abstract mixin class _$PantryItemCopyWith<$Res> implements $PantryItemCopyWith<$Res> {
  factory _$PantryItemCopyWith(_PantryItem value, $Res Function(_PantryItem) _then) = __$PantryItemCopyWithImpl;
@override @useResult
$Res call({
 int id, IngredientSummary ingredient, ProductSummary? product,@JsonKey(fromJson: availabilityFromJson, toJson: availabilityToJson) Availability availability,@JsonKey(fromJson: pantrySourceFromJson, toJson: pantrySourceToJson) PantrySource source,@JsonKey(name: 'confirmed_at') DateTime? confirmedAt,@JsonKey(name: 'confidence_expires_at') DateTime? confidenceExpiresAt,@JsonKey(name: 'days_remaining') int? daysRemaining,@JsonKey(name: 'detected_confidence') double? detectedConfidence,@JsonKey(name: 'quantity_base') double? quantityBase,@JsonKey(name: 'display_unit', fromJson: _unitOrNull, toJson: _unitOrNullJson) UnitCode? displayUnit,@JsonKey(name: 'expiry_date') DateTime? expiryDate,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'is_low') bool isLow,@JsonKey(name: 'display_quantity') double displayQuantity
});


@override $IngredientSummaryCopyWith<$Res> get ingredient;@override $ProductSummaryCopyWith<$Res>? get product;

}
/// @nodoc
class __$PantryItemCopyWithImpl<$Res>
    implements _$PantryItemCopyWith<$Res> {
  __$PantryItemCopyWithImpl(this._self, this._then);

  final _PantryItem _self;
  final $Res Function(_PantryItem) _then;

/// Create a copy of PantryItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ingredient = null,Object? product = freezed,Object? availability = null,Object? source = null,Object? confirmedAt = freezed,Object? confidenceExpiresAt = freezed,Object? daysRemaining = freezed,Object? detectedConfidence = freezed,Object? quantityBase = freezed,Object? displayUnit = freezed,Object? expiryDate = freezed,Object? isActive = null,Object? createdAt = null,Object? updatedAt = null,Object? isLow = null,Object? displayQuantity = null,}) {
  return _then(_PantryItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,ingredient: null == ingredient ? _self.ingredient : ingredient // ignore: cast_nullable_to_non_nullable
as IngredientSummary,product: freezed == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as ProductSummary?,availability: null == availability ? _self.availability : availability // ignore: cast_nullable_to_non_nullable
as Availability,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as PantrySource,confirmedAt: freezed == confirmedAt ? _self.confirmedAt : confirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,confidenceExpiresAt: freezed == confidenceExpiresAt ? _self.confidenceExpiresAt : confidenceExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,daysRemaining: freezed == daysRemaining ? _self.daysRemaining : daysRemaining // ignore: cast_nullable_to_non_nullable
as int?,detectedConfidence: freezed == detectedConfidence ? _self.detectedConfidence : detectedConfidence // ignore: cast_nullable_to_non_nullable
as double?,quantityBase: freezed == quantityBase ? _self.quantityBase : quantityBase // ignore: cast_nullable_to_non_nullable
as double?,displayUnit: freezed == displayUnit ? _self.displayUnit : displayUnit // ignore: cast_nullable_to_non_nullable
as UnitCode?,expiryDate: freezed == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isLow: null == isLow ? _self.isLow : isLow // ignore: cast_nullable_to_non_nullable
as bool,displayQuantity: null == displayQuantity ? _self.displayQuantity : displayQuantity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of PantryItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IngredientSummaryCopyWith<$Res> get ingredient {
  
  return $IngredientSummaryCopyWith<$Res>(_self.ingredient, (value) {
    return _then(_self.copyWith(ingredient: value));
  });
}/// Create a copy of PantryItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductSummaryCopyWith<$Res>? get product {
    if (_self.product == null) {
    return null;
  }

  return $ProductSummaryCopyWith<$Res>(_self.product!, (value) {
    return _then(_self.copyWith(product: value));
  });
}
}


/// @nodoc
mixin _$IngredientSummary {

 int get id;@JsonKey(name: 'canonical_name') String get canonicalName;@JsonKey(name: 'display_name') String get displayName;@JsonKey(name: 'calories_per_100g') double? get caloriesPer100g;@JsonKey(name: 'is_staple') bool get isStaple;
/// Create a copy of IngredientSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IngredientSummaryCopyWith<IngredientSummary> get copyWith => _$IngredientSummaryCopyWithImpl<IngredientSummary>(this as IngredientSummary, _$identity);

  /// Serializes this IngredientSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IngredientSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.canonicalName, canonicalName) || other.canonicalName == canonicalName)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.caloriesPer100g, caloriesPer100g) || other.caloriesPer100g == caloriesPer100g)&&(identical(other.isStaple, isStaple) || other.isStaple == isStaple));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,canonicalName,displayName,caloriesPer100g,isStaple);

@override
String toString() {
  return 'IngredientSummary(id: $id, canonicalName: $canonicalName, displayName: $displayName, caloriesPer100g: $caloriesPer100g, isStaple: $isStaple)';
}


}

/// @nodoc
abstract mixin class $IngredientSummaryCopyWith<$Res>  {
  factory $IngredientSummaryCopyWith(IngredientSummary value, $Res Function(IngredientSummary) _then) = _$IngredientSummaryCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'canonical_name') String canonicalName,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'calories_per_100g') double? caloriesPer100g,@JsonKey(name: 'is_staple') bool isStaple
});




}
/// @nodoc
class _$IngredientSummaryCopyWithImpl<$Res>
    implements $IngredientSummaryCopyWith<$Res> {
  _$IngredientSummaryCopyWithImpl(this._self, this._then);

  final IngredientSummary _self;
  final $Res Function(IngredientSummary) _then;

/// Create a copy of IngredientSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? canonicalName = null,Object? displayName = null,Object? caloriesPer100g = freezed,Object? isStaple = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,canonicalName: null == canonicalName ? _self.canonicalName : canonicalName // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,caloriesPer100g: freezed == caloriesPer100g ? _self.caloriesPer100g : caloriesPer100g // ignore: cast_nullable_to_non_nullable
as double?,isStaple: null == isStaple ? _self.isStaple : isStaple // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [IngredientSummary].
extension IngredientSummaryPatterns on IngredientSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IngredientSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IngredientSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IngredientSummary value)  $default,){
final _that = this;
switch (_that) {
case _IngredientSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IngredientSummary value)?  $default,){
final _that = this;
switch (_that) {
case _IngredientSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'canonical_name')  String canonicalName, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'calories_per_100g')  double? caloriesPer100g, @JsonKey(name: 'is_staple')  bool isStaple)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IngredientSummary() when $default != null:
return $default(_that.id,_that.canonicalName,_that.displayName,_that.caloriesPer100g,_that.isStaple);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'canonical_name')  String canonicalName, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'calories_per_100g')  double? caloriesPer100g, @JsonKey(name: 'is_staple')  bool isStaple)  $default,) {final _that = this;
switch (_that) {
case _IngredientSummary():
return $default(_that.id,_that.canonicalName,_that.displayName,_that.caloriesPer100g,_that.isStaple);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'canonical_name')  String canonicalName, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'calories_per_100g')  double? caloriesPer100g, @JsonKey(name: 'is_staple')  bool isStaple)?  $default,) {final _that = this;
switch (_that) {
case _IngredientSummary() when $default != null:
return $default(_that.id,_that.canonicalName,_that.displayName,_that.caloriesPer100g,_that.isStaple);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IngredientSummary implements IngredientSummary {
  const _IngredientSummary({required this.id, @JsonKey(name: 'canonical_name') required this.canonicalName, @JsonKey(name: 'display_name') required this.displayName, @JsonKey(name: 'calories_per_100g') this.caloriesPer100g, @JsonKey(name: 'is_staple') this.isStaple = false});
  factory _IngredientSummary.fromJson(Map<String, dynamic> json) => _$IngredientSummaryFromJson(json);

@override final  int id;
@override@JsonKey(name: 'canonical_name') final  String canonicalName;
@override@JsonKey(name: 'display_name') final  String displayName;
@override@JsonKey(name: 'calories_per_100g') final  double? caloriesPer100g;
@override@JsonKey(name: 'is_staple') final  bool isStaple;

/// Create a copy of IngredientSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IngredientSummaryCopyWith<_IngredientSummary> get copyWith => __$IngredientSummaryCopyWithImpl<_IngredientSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IngredientSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IngredientSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.canonicalName, canonicalName) || other.canonicalName == canonicalName)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.caloriesPer100g, caloriesPer100g) || other.caloriesPer100g == caloriesPer100g)&&(identical(other.isStaple, isStaple) || other.isStaple == isStaple));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,canonicalName,displayName,caloriesPer100g,isStaple);

@override
String toString() {
  return 'IngredientSummary(id: $id, canonicalName: $canonicalName, displayName: $displayName, caloriesPer100g: $caloriesPer100g, isStaple: $isStaple)';
}


}

/// @nodoc
abstract mixin class _$IngredientSummaryCopyWith<$Res> implements $IngredientSummaryCopyWith<$Res> {
  factory _$IngredientSummaryCopyWith(_IngredientSummary value, $Res Function(_IngredientSummary) _then) = __$IngredientSummaryCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'canonical_name') String canonicalName,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'calories_per_100g') double? caloriesPer100g,@JsonKey(name: 'is_staple') bool isStaple
});




}
/// @nodoc
class __$IngredientSummaryCopyWithImpl<$Res>
    implements _$IngredientSummaryCopyWith<$Res> {
  __$IngredientSummaryCopyWithImpl(this._self, this._then);

  final _IngredientSummary _self;
  final $Res Function(_IngredientSummary) _then;

/// Create a copy of IngredientSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? canonicalName = null,Object? displayName = null,Object? caloriesPer100g = freezed,Object? isStaple = null,}) {
  return _then(_IngredientSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,canonicalName: null == canonicalName ? _self.canonicalName : canonicalName // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,caloriesPer100g: freezed == caloriesPer100g ? _self.caloriesPer100g : caloriesPer100g // ignore: cast_nullable_to_non_nullable
as double?,isStaple: null == isStaple ? _self.isStaple : isStaple // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ProductSummary {

 int get id; String? get barcode; String get name; String? get brand;@JsonKey(name: 'calories_per_100g') double? get caloriesPer100g;@JsonKey(name: 'image_url') String? get imageUrl;
/// Create a copy of ProductSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductSummaryCopyWith<ProductSummary> get copyWith => _$ProductSummaryCopyWithImpl<ProductSummary>(this as ProductSummary, _$identity);

  /// Serializes this ProductSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.name, name) || other.name == name)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.caloriesPer100g, caloriesPer100g) || other.caloriesPer100g == caloriesPer100g)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,barcode,name,brand,caloriesPer100g,imageUrl);

@override
String toString() {
  return 'ProductSummary(id: $id, barcode: $barcode, name: $name, brand: $brand, caloriesPer100g: $caloriesPer100g, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class $ProductSummaryCopyWith<$Res>  {
  factory $ProductSummaryCopyWith(ProductSummary value, $Res Function(ProductSummary) _then) = _$ProductSummaryCopyWithImpl;
@useResult
$Res call({
 int id, String? barcode, String name, String? brand,@JsonKey(name: 'calories_per_100g') double? caloriesPer100g,@JsonKey(name: 'image_url') String? imageUrl
});




}
/// @nodoc
class _$ProductSummaryCopyWithImpl<$Res>
    implements $ProductSummaryCopyWith<$Res> {
  _$ProductSummaryCopyWithImpl(this._self, this._then);

  final ProductSummary _self;
  final $Res Function(ProductSummary) _then;

/// Create a copy of ProductSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? barcode = freezed,Object? name = null,Object? brand = freezed,Object? caloriesPer100g = freezed,Object? imageUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,caloriesPer100g: freezed == caloriesPer100g ? _self.caloriesPer100g : caloriesPer100g // ignore: cast_nullable_to_non_nullable
as double?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductSummary].
extension ProductSummaryPatterns on ProductSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductSummary value)  $default,){
final _that = this;
switch (_that) {
case _ProductSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ProductSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? barcode,  String name,  String? brand, @JsonKey(name: 'calories_per_100g')  double? caloriesPer100g, @JsonKey(name: 'image_url')  String? imageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductSummary() when $default != null:
return $default(_that.id,_that.barcode,_that.name,_that.brand,_that.caloriesPer100g,_that.imageUrl);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? barcode,  String name,  String? brand, @JsonKey(name: 'calories_per_100g')  double? caloriesPer100g, @JsonKey(name: 'image_url')  String? imageUrl)  $default,) {final _that = this;
switch (_that) {
case _ProductSummary():
return $default(_that.id,_that.barcode,_that.name,_that.brand,_that.caloriesPer100g,_that.imageUrl);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? barcode,  String name,  String? brand, @JsonKey(name: 'calories_per_100g')  double? caloriesPer100g, @JsonKey(name: 'image_url')  String? imageUrl)?  $default,) {final _that = this;
switch (_that) {
case _ProductSummary() when $default != null:
return $default(_that.id,_that.barcode,_that.name,_that.brand,_that.caloriesPer100g,_that.imageUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductSummary implements ProductSummary {
  const _ProductSummary({required this.id, this.barcode, required this.name, this.brand, @JsonKey(name: 'calories_per_100g') this.caloriesPer100g, @JsonKey(name: 'image_url') this.imageUrl});
  factory _ProductSummary.fromJson(Map<String, dynamic> json) => _$ProductSummaryFromJson(json);

@override final  int id;
@override final  String? barcode;
@override final  String name;
@override final  String? brand;
@override@JsonKey(name: 'calories_per_100g') final  double? caloriesPer100g;
@override@JsonKey(name: 'image_url') final  String? imageUrl;

/// Create a copy of ProductSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductSummaryCopyWith<_ProductSummary> get copyWith => __$ProductSummaryCopyWithImpl<_ProductSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.name, name) || other.name == name)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.caloriesPer100g, caloriesPer100g) || other.caloriesPer100g == caloriesPer100g)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,barcode,name,brand,caloriesPer100g,imageUrl);

@override
String toString() {
  return 'ProductSummary(id: $id, barcode: $barcode, name: $name, brand: $brand, caloriesPer100g: $caloriesPer100g, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class _$ProductSummaryCopyWith<$Res> implements $ProductSummaryCopyWith<$Res> {
  factory _$ProductSummaryCopyWith(_ProductSummary value, $Res Function(_ProductSummary) _then) = __$ProductSummaryCopyWithImpl;
@override @useResult
$Res call({
 int id, String? barcode, String name, String? brand,@JsonKey(name: 'calories_per_100g') double? caloriesPer100g,@JsonKey(name: 'image_url') String? imageUrl
});




}
/// @nodoc
class __$ProductSummaryCopyWithImpl<$Res>
    implements _$ProductSummaryCopyWith<$Res> {
  __$ProductSummaryCopyWithImpl(this._self, this._then);

  final _ProductSummary _self;
  final $Res Function(_ProductSummary) _then;

/// Create a copy of ProductSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? barcode = freezed,Object? name = null,Object? brand = freezed,Object? caloriesPer100g = freezed,Object? imageUrl = freezed,}) {
  return _then(_ProductSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,caloriesPer100g: freezed == caloriesPer100g ? _self.caloriesPer100g : caloriesPer100g // ignore: cast_nullable_to_non_nullable
as double?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
