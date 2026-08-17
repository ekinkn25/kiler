// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'detected_ingredient.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DetectedIngredient {

@JsonKey(name: 'raw_name') String get rawName;@JsonKey(name: 'canonical_name') String? get canonicalName;@JsonKey(name: 'display_name') String get displayName; double get confidence;
/// Create a copy of DetectedIngredient
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DetectedIngredientCopyWith<DetectedIngredient> get copyWith => _$DetectedIngredientCopyWithImpl<DetectedIngredient>(this as DetectedIngredient, _$identity);

  /// Serializes this DetectedIngredient to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetectedIngredient&&(identical(other.rawName, rawName) || other.rawName == rawName)&&(identical(other.canonicalName, canonicalName) || other.canonicalName == canonicalName)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rawName,canonicalName,displayName,confidence);

@override
String toString() {
  return 'DetectedIngredient(rawName: $rawName, canonicalName: $canonicalName, displayName: $displayName, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class $DetectedIngredientCopyWith<$Res>  {
  factory $DetectedIngredientCopyWith(DetectedIngredient value, $Res Function(DetectedIngredient) _then) = _$DetectedIngredientCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'raw_name') String rawName,@JsonKey(name: 'canonical_name') String? canonicalName,@JsonKey(name: 'display_name') String displayName, double confidence
});




}
/// @nodoc
class _$DetectedIngredientCopyWithImpl<$Res>
    implements $DetectedIngredientCopyWith<$Res> {
  _$DetectedIngredientCopyWithImpl(this._self, this._then);

  final DetectedIngredient _self;
  final $Res Function(DetectedIngredient) _then;

/// Create a copy of DetectedIngredient
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rawName = null,Object? canonicalName = freezed,Object? displayName = null,Object? confidence = null,}) {
  return _then(_self.copyWith(
rawName: null == rawName ? _self.rawName : rawName // ignore: cast_nullable_to_non_nullable
as String,canonicalName: freezed == canonicalName ? _self.canonicalName : canonicalName // ignore: cast_nullable_to_non_nullable
as String?,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [DetectedIngredient].
extension DetectedIngredientPatterns on DetectedIngredient {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DetectedIngredient value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DetectedIngredient() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DetectedIngredient value)  $default,){
final _that = this;
switch (_that) {
case _DetectedIngredient():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DetectedIngredient value)?  $default,){
final _that = this;
switch (_that) {
case _DetectedIngredient() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'raw_name')  String rawName, @JsonKey(name: 'canonical_name')  String? canonicalName, @JsonKey(name: 'display_name')  String displayName,  double confidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DetectedIngredient() when $default != null:
return $default(_that.rawName,_that.canonicalName,_that.displayName,_that.confidence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'raw_name')  String rawName, @JsonKey(name: 'canonical_name')  String? canonicalName, @JsonKey(name: 'display_name')  String displayName,  double confidence)  $default,) {final _that = this;
switch (_that) {
case _DetectedIngredient():
return $default(_that.rawName,_that.canonicalName,_that.displayName,_that.confidence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'raw_name')  String rawName, @JsonKey(name: 'canonical_name')  String? canonicalName, @JsonKey(name: 'display_name')  String displayName,  double confidence)?  $default,) {final _that = this;
switch (_that) {
case _DetectedIngredient() when $default != null:
return $default(_that.rawName,_that.canonicalName,_that.displayName,_that.confidence);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DetectedIngredient implements DetectedIngredient {
  const _DetectedIngredient({@JsonKey(name: 'raw_name') required this.rawName, @JsonKey(name: 'canonical_name') this.canonicalName, @JsonKey(name: 'display_name') required this.displayName, required this.confidence});
  factory _DetectedIngredient.fromJson(Map<String, dynamic> json) => _$DetectedIngredientFromJson(json);

@override@JsonKey(name: 'raw_name') final  String rawName;
@override@JsonKey(name: 'canonical_name') final  String? canonicalName;
@override@JsonKey(name: 'display_name') final  String displayName;
@override final  double confidence;

/// Create a copy of DetectedIngredient
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DetectedIngredientCopyWith<_DetectedIngredient> get copyWith => __$DetectedIngredientCopyWithImpl<_DetectedIngredient>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DetectedIngredientToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DetectedIngredient&&(identical(other.rawName, rawName) || other.rawName == rawName)&&(identical(other.canonicalName, canonicalName) || other.canonicalName == canonicalName)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rawName,canonicalName,displayName,confidence);

@override
String toString() {
  return 'DetectedIngredient(rawName: $rawName, canonicalName: $canonicalName, displayName: $displayName, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class _$DetectedIngredientCopyWith<$Res> implements $DetectedIngredientCopyWith<$Res> {
  factory _$DetectedIngredientCopyWith(_DetectedIngredient value, $Res Function(_DetectedIngredient) _then) = __$DetectedIngredientCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'raw_name') String rawName,@JsonKey(name: 'canonical_name') String? canonicalName,@JsonKey(name: 'display_name') String displayName, double confidence
});




}
/// @nodoc
class __$DetectedIngredientCopyWithImpl<$Res>
    implements _$DetectedIngredientCopyWith<$Res> {
  __$DetectedIngredientCopyWithImpl(this._self, this._then);

  final _DetectedIngredient _self;
  final $Res Function(_DetectedIngredient) _then;

/// Create a copy of DetectedIngredient
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rawName = null,Object? canonicalName = freezed,Object? displayName = null,Object? confidence = null,}) {
  return _then(_DetectedIngredient(
rawName: null == rawName ? _self.rawName : rawName // ignore: cast_nullable_to_non_nullable
as String,canonicalName: freezed == canonicalName ? _self.canonicalName : canonicalName // ignore: cast_nullable_to_non_nullable
as String?,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
