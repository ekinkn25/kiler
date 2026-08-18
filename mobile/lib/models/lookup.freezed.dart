// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lookup.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DietTag {

 int get id; String get code;@JsonKey(name: 'display_name') String get displayName;
/// Create a copy of DietTag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DietTagCopyWith<DietTag> get copyWith => _$DietTagCopyWithImpl<DietTag>(this as DietTag, _$identity);

  /// Serializes this DietTag to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DietTag&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,displayName);

@override
String toString() {
  return 'DietTag(id: $id, code: $code, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class $DietTagCopyWith<$Res>  {
  factory $DietTagCopyWith(DietTag value, $Res Function(DietTag) _then) = _$DietTagCopyWithImpl;
@useResult
$Res call({
 int id, String code,@JsonKey(name: 'display_name') String displayName
});




}
/// @nodoc
class _$DietTagCopyWithImpl<$Res>
    implements $DietTagCopyWith<$Res> {
  _$DietTagCopyWithImpl(this._self, this._then);

  final DietTag _self;
  final $Res Function(DietTag) _then;

/// Create a copy of DietTag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? displayName = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DietTag].
extension DietTagPatterns on DietTag {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DietTag value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DietTag() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DietTag value)  $default,){
final _that = this;
switch (_that) {
case _DietTag():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DietTag value)?  $default,){
final _that = this;
switch (_that) {
case _DietTag() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code, @JsonKey(name: 'display_name')  String displayName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DietTag() when $default != null:
return $default(_that.id,_that.code,_that.displayName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code, @JsonKey(name: 'display_name')  String displayName)  $default,) {final _that = this;
switch (_that) {
case _DietTag():
return $default(_that.id,_that.code,_that.displayName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code, @JsonKey(name: 'display_name')  String displayName)?  $default,) {final _that = this;
switch (_that) {
case _DietTag() when $default != null:
return $default(_that.id,_that.code,_that.displayName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DietTag implements DietTag {
  const _DietTag({required this.id, required this.code, @JsonKey(name: 'display_name') required this.displayName});
  factory _DietTag.fromJson(Map<String, dynamic> json) => _$DietTagFromJson(json);

@override final  int id;
@override final  String code;
@override@JsonKey(name: 'display_name') final  String displayName;

/// Create a copy of DietTag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DietTagCopyWith<_DietTag> get copyWith => __$DietTagCopyWithImpl<_DietTag>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DietTagToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DietTag&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,displayName);

@override
String toString() {
  return 'DietTag(id: $id, code: $code, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class _$DietTagCopyWith<$Res> implements $DietTagCopyWith<$Res> {
  factory _$DietTagCopyWith(_DietTag value, $Res Function(_DietTag) _then) = __$DietTagCopyWithImpl;
@override @useResult
$Res call({
 int id, String code,@JsonKey(name: 'display_name') String displayName
});




}
/// @nodoc
class __$DietTagCopyWithImpl<$Res>
    implements _$DietTagCopyWith<$Res> {
  __$DietTagCopyWithImpl(this._self, this._then);

  final _DietTag _self;
  final $Res Function(_DietTag) _then;

/// Create a copy of DietTag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? displayName = null,}) {
  return _then(_DietTag(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Allergen {

 int get id; String get code;@JsonKey(name: 'display_name') String get displayName;
/// Create a copy of Allergen
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AllergenCopyWith<Allergen> get copyWith => _$AllergenCopyWithImpl<Allergen>(this as Allergen, _$identity);

  /// Serializes this Allergen to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Allergen&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,displayName);

@override
String toString() {
  return 'Allergen(id: $id, code: $code, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class $AllergenCopyWith<$Res>  {
  factory $AllergenCopyWith(Allergen value, $Res Function(Allergen) _then) = _$AllergenCopyWithImpl;
@useResult
$Res call({
 int id, String code,@JsonKey(name: 'display_name') String displayName
});




}
/// @nodoc
class _$AllergenCopyWithImpl<$Res>
    implements $AllergenCopyWith<$Res> {
  _$AllergenCopyWithImpl(this._self, this._then);

  final Allergen _self;
  final $Res Function(Allergen) _then;

/// Create a copy of Allergen
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? displayName = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Allergen].
extension AllergenPatterns on Allergen {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Allergen value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Allergen() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Allergen value)  $default,){
final _that = this;
switch (_that) {
case _Allergen():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Allergen value)?  $default,){
final _that = this;
switch (_that) {
case _Allergen() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code, @JsonKey(name: 'display_name')  String displayName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Allergen() when $default != null:
return $default(_that.id,_that.code,_that.displayName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code, @JsonKey(name: 'display_name')  String displayName)  $default,) {final _that = this;
switch (_that) {
case _Allergen():
return $default(_that.id,_that.code,_that.displayName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code, @JsonKey(name: 'display_name')  String displayName)?  $default,) {final _that = this;
switch (_that) {
case _Allergen() when $default != null:
return $default(_that.id,_that.code,_that.displayName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Allergen implements Allergen {
  const _Allergen({required this.id, required this.code, @JsonKey(name: 'display_name') required this.displayName});
  factory _Allergen.fromJson(Map<String, dynamic> json) => _$AllergenFromJson(json);

@override final  int id;
@override final  String code;
@override@JsonKey(name: 'display_name') final  String displayName;

/// Create a copy of Allergen
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AllergenCopyWith<_Allergen> get copyWith => __$AllergenCopyWithImpl<_Allergen>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AllergenToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Allergen&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,displayName);

@override
String toString() {
  return 'Allergen(id: $id, code: $code, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class _$AllergenCopyWith<$Res> implements $AllergenCopyWith<$Res> {
  factory _$AllergenCopyWith(_Allergen value, $Res Function(_Allergen) _then) = __$AllergenCopyWithImpl;
@override @useResult
$Res call({
 int id, String code,@JsonKey(name: 'display_name') String displayName
});




}
/// @nodoc
class __$AllergenCopyWithImpl<$Res>
    implements _$AllergenCopyWith<$Res> {
  __$AllergenCopyWithImpl(this._self, this._then);

  final _Allergen _self;
  final $Res Function(_Allergen) _then;

/// Create a copy of Allergen
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? displayName = null,}) {
  return _then(_Allergen(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
