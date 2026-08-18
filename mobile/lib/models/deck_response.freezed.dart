// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'deck_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeckResponse {

@JsonKey(name: 'session_id') int get sessionId; List<RecipeCard> get items; int get returned; int get requested; bool get exhausted;@JsonKey(name: 'session_filters') Map<String, dynamic> get sessionFilters;
/// Create a copy of DeckResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeckResponseCopyWith<DeckResponse> get copyWith => _$DeckResponseCopyWithImpl<DeckResponse>(this as DeckResponse, _$identity);

  /// Serializes this DeckResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeckResponse&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.returned, returned) || other.returned == returned)&&(identical(other.requested, requested) || other.requested == requested)&&(identical(other.exhausted, exhausted) || other.exhausted == exhausted)&&const DeepCollectionEquality().equals(other.sessionFilters, sessionFilters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,const DeepCollectionEquality().hash(items),returned,requested,exhausted,const DeepCollectionEquality().hash(sessionFilters));

@override
String toString() {
  return 'DeckResponse(sessionId: $sessionId, items: $items, returned: $returned, requested: $requested, exhausted: $exhausted, sessionFilters: $sessionFilters)';
}


}

/// @nodoc
abstract mixin class $DeckResponseCopyWith<$Res>  {
  factory $DeckResponseCopyWith(DeckResponse value, $Res Function(DeckResponse) _then) = _$DeckResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'session_id') int sessionId, List<RecipeCard> items, int returned, int requested, bool exhausted,@JsonKey(name: 'session_filters') Map<String, dynamic> sessionFilters
});




}
/// @nodoc
class _$DeckResponseCopyWithImpl<$Res>
    implements $DeckResponseCopyWith<$Res> {
  _$DeckResponseCopyWithImpl(this._self, this._then);

  final DeckResponse _self;
  final $Res Function(DeckResponse) _then;

/// Create a copy of DeckResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? items = null,Object? returned = null,Object? requested = null,Object? exhausted = null,Object? sessionFilters = null,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<RecipeCard>,returned: null == returned ? _self.returned : returned // ignore: cast_nullable_to_non_nullable
as int,requested: null == requested ? _self.requested : requested // ignore: cast_nullable_to_non_nullable
as int,exhausted: null == exhausted ? _self.exhausted : exhausted // ignore: cast_nullable_to_non_nullable
as bool,sessionFilters: null == sessionFilters ? _self.sessionFilters : sessionFilters // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [DeckResponse].
extension DeckResponsePatterns on DeckResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeckResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeckResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeckResponse value)  $default,){
final _that = this;
switch (_that) {
case _DeckResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeckResponse value)?  $default,){
final _that = this;
switch (_that) {
case _DeckResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'session_id')  int sessionId,  List<RecipeCard> items,  int returned,  int requested,  bool exhausted, @JsonKey(name: 'session_filters')  Map<String, dynamic> sessionFilters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeckResponse() when $default != null:
return $default(_that.sessionId,_that.items,_that.returned,_that.requested,_that.exhausted,_that.sessionFilters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'session_id')  int sessionId,  List<RecipeCard> items,  int returned,  int requested,  bool exhausted, @JsonKey(name: 'session_filters')  Map<String, dynamic> sessionFilters)  $default,) {final _that = this;
switch (_that) {
case _DeckResponse():
return $default(_that.sessionId,_that.items,_that.returned,_that.requested,_that.exhausted,_that.sessionFilters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'session_id')  int sessionId,  List<RecipeCard> items,  int returned,  int requested,  bool exhausted, @JsonKey(name: 'session_filters')  Map<String, dynamic> sessionFilters)?  $default,) {final _that = this;
switch (_that) {
case _DeckResponse() when $default != null:
return $default(_that.sessionId,_that.items,_that.returned,_that.requested,_that.exhausted,_that.sessionFilters);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeckResponse implements DeckResponse {
  const _DeckResponse({@JsonKey(name: 'session_id') required this.sessionId, final  List<RecipeCard> items = const [], this.returned = 0, this.requested = 0, this.exhausted = false, @JsonKey(name: 'session_filters') final  Map<String, dynamic> sessionFilters = const {}}): _items = items,_sessionFilters = sessionFilters;
  factory _DeckResponse.fromJson(Map<String, dynamic> json) => _$DeckResponseFromJson(json);

@override@JsonKey(name: 'session_id') final  int sessionId;
 final  List<RecipeCard> _items;
@override@JsonKey() List<RecipeCard> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int returned;
@override@JsonKey() final  int requested;
@override@JsonKey() final  bool exhausted;
 final  Map<String, dynamic> _sessionFilters;
@override@JsonKey(name: 'session_filters') Map<String, dynamic> get sessionFilters {
  if (_sessionFilters is EqualUnmodifiableMapView) return _sessionFilters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_sessionFilters);
}


/// Create a copy of DeckResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeckResponseCopyWith<_DeckResponse> get copyWith => __$DeckResponseCopyWithImpl<_DeckResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeckResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeckResponse&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.returned, returned) || other.returned == returned)&&(identical(other.requested, requested) || other.requested == requested)&&(identical(other.exhausted, exhausted) || other.exhausted == exhausted)&&const DeepCollectionEquality().equals(other._sessionFilters, _sessionFilters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,const DeepCollectionEquality().hash(_items),returned,requested,exhausted,const DeepCollectionEquality().hash(_sessionFilters));

@override
String toString() {
  return 'DeckResponse(sessionId: $sessionId, items: $items, returned: $returned, requested: $requested, exhausted: $exhausted, sessionFilters: $sessionFilters)';
}


}

/// @nodoc
abstract mixin class _$DeckResponseCopyWith<$Res> implements $DeckResponseCopyWith<$Res> {
  factory _$DeckResponseCopyWith(_DeckResponse value, $Res Function(_DeckResponse) _then) = __$DeckResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'session_id') int sessionId, List<RecipeCard> items, int returned, int requested, bool exhausted,@JsonKey(name: 'session_filters') Map<String, dynamic> sessionFilters
});




}
/// @nodoc
class __$DeckResponseCopyWithImpl<$Res>
    implements _$DeckResponseCopyWith<$Res> {
  __$DeckResponseCopyWithImpl(this._self, this._then);

  final _DeckResponse _self;
  final $Res Function(_DeckResponse) _then;

/// Create a copy of DeckResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? items = null,Object? returned = null,Object? requested = null,Object? exhausted = null,Object? sessionFilters = null,}) {
  return _then(_DeckResponse(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<RecipeCard>,returned: null == returned ? _self.returned : returned // ignore: cast_nullable_to_non_nullable
as int,requested: null == requested ? _self.requested : requested // ignore: cast_nullable_to_non_nullable
as int,exhausted: null == exhausted ? _self.exhausted : exhausted // ignore: cast_nullable_to_non_nullable
as bool,sessionFilters: null == sessionFilters ? _self._sessionFilters : sessionFilters // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
