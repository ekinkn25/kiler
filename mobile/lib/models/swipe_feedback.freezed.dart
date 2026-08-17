// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'swipe_feedback.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SwipeFeedback {

@JsonKey(fromJson: feedbackActionFromJson, toJson: feedbackActionToJson) FeedbackAction get action;@JsonKey(fromJson: _reasonOrNull, toJson: _reasonOrNullJson) FeedbackReason? get reason;@JsonKey(name: 'session_id') int? get sessionId;@JsonKey(name: 'missing_ingredient_id') int? get missingIngredientId; int? get rating;@JsonKey(name: 'servings_cooked') double? get servingsCooked; String? get comment;
/// Create a copy of SwipeFeedback
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SwipeFeedbackCopyWith<SwipeFeedback> get copyWith => _$SwipeFeedbackCopyWithImpl<SwipeFeedback>(this as SwipeFeedback, _$identity);

  /// Serializes this SwipeFeedback to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SwipeFeedback&&(identical(other.action, action) || other.action == action)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.missingIngredientId, missingIngredientId) || other.missingIngredientId == missingIngredientId)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.servingsCooked, servingsCooked) || other.servingsCooked == servingsCooked)&&(identical(other.comment, comment) || other.comment == comment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,action,reason,sessionId,missingIngredientId,rating,servingsCooked,comment);

@override
String toString() {
  return 'SwipeFeedback(action: $action, reason: $reason, sessionId: $sessionId, missingIngredientId: $missingIngredientId, rating: $rating, servingsCooked: $servingsCooked, comment: $comment)';
}


}

/// @nodoc
abstract mixin class $SwipeFeedbackCopyWith<$Res>  {
  factory $SwipeFeedbackCopyWith(SwipeFeedback value, $Res Function(SwipeFeedback) _then) = _$SwipeFeedbackCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: feedbackActionFromJson, toJson: feedbackActionToJson) FeedbackAction action,@JsonKey(fromJson: _reasonOrNull, toJson: _reasonOrNullJson) FeedbackReason? reason,@JsonKey(name: 'session_id') int? sessionId,@JsonKey(name: 'missing_ingredient_id') int? missingIngredientId, int? rating,@JsonKey(name: 'servings_cooked') double? servingsCooked, String? comment
});




}
/// @nodoc
class _$SwipeFeedbackCopyWithImpl<$Res>
    implements $SwipeFeedbackCopyWith<$Res> {
  _$SwipeFeedbackCopyWithImpl(this._self, this._then);

  final SwipeFeedback _self;
  final $Res Function(SwipeFeedback) _then;

/// Create a copy of SwipeFeedback
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? action = null,Object? reason = freezed,Object? sessionId = freezed,Object? missingIngredientId = freezed,Object? rating = freezed,Object? servingsCooked = freezed,Object? comment = freezed,}) {
  return _then(_self.copyWith(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as FeedbackAction,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as FeedbackReason?,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as int?,missingIngredientId: freezed == missingIngredientId ? _self.missingIngredientId : missingIngredientId // ignore: cast_nullable_to_non_nullable
as int?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int?,servingsCooked: freezed == servingsCooked ? _self.servingsCooked : servingsCooked // ignore: cast_nullable_to_non_nullable
as double?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SwipeFeedback].
extension SwipeFeedbackPatterns on SwipeFeedback {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SwipeFeedback value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SwipeFeedback() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SwipeFeedback value)  $default,){
final _that = this;
switch (_that) {
case _SwipeFeedback():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SwipeFeedback value)?  $default,){
final _that = this;
switch (_that) {
case _SwipeFeedback() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: feedbackActionFromJson, toJson: feedbackActionToJson)  FeedbackAction action, @JsonKey(fromJson: _reasonOrNull, toJson: _reasonOrNullJson)  FeedbackReason? reason, @JsonKey(name: 'session_id')  int? sessionId, @JsonKey(name: 'missing_ingredient_id')  int? missingIngredientId,  int? rating, @JsonKey(name: 'servings_cooked')  double? servingsCooked,  String? comment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SwipeFeedback() when $default != null:
return $default(_that.action,_that.reason,_that.sessionId,_that.missingIngredientId,_that.rating,_that.servingsCooked,_that.comment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: feedbackActionFromJson, toJson: feedbackActionToJson)  FeedbackAction action, @JsonKey(fromJson: _reasonOrNull, toJson: _reasonOrNullJson)  FeedbackReason? reason, @JsonKey(name: 'session_id')  int? sessionId, @JsonKey(name: 'missing_ingredient_id')  int? missingIngredientId,  int? rating, @JsonKey(name: 'servings_cooked')  double? servingsCooked,  String? comment)  $default,) {final _that = this;
switch (_that) {
case _SwipeFeedback():
return $default(_that.action,_that.reason,_that.sessionId,_that.missingIngredientId,_that.rating,_that.servingsCooked,_that.comment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: feedbackActionFromJson, toJson: feedbackActionToJson)  FeedbackAction action, @JsonKey(fromJson: _reasonOrNull, toJson: _reasonOrNullJson)  FeedbackReason? reason, @JsonKey(name: 'session_id')  int? sessionId, @JsonKey(name: 'missing_ingredient_id')  int? missingIngredientId,  int? rating, @JsonKey(name: 'servings_cooked')  double? servingsCooked,  String? comment)?  $default,) {final _that = this;
switch (_that) {
case _SwipeFeedback() when $default != null:
return $default(_that.action,_that.reason,_that.sessionId,_that.missingIngredientId,_that.rating,_that.servingsCooked,_that.comment);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SwipeFeedback implements SwipeFeedback {
  const _SwipeFeedback({@JsonKey(fromJson: feedbackActionFromJson, toJson: feedbackActionToJson) required this.action, @JsonKey(fromJson: _reasonOrNull, toJson: _reasonOrNullJson) this.reason, @JsonKey(name: 'session_id') this.sessionId, @JsonKey(name: 'missing_ingredient_id') this.missingIngredientId, this.rating, @JsonKey(name: 'servings_cooked') this.servingsCooked, this.comment});
  factory _SwipeFeedback.fromJson(Map<String, dynamic> json) => _$SwipeFeedbackFromJson(json);

@override@JsonKey(fromJson: feedbackActionFromJson, toJson: feedbackActionToJson) final  FeedbackAction action;
@override@JsonKey(fromJson: _reasonOrNull, toJson: _reasonOrNullJson) final  FeedbackReason? reason;
@override@JsonKey(name: 'session_id') final  int? sessionId;
@override@JsonKey(name: 'missing_ingredient_id') final  int? missingIngredientId;
@override final  int? rating;
@override@JsonKey(name: 'servings_cooked') final  double? servingsCooked;
@override final  String? comment;

/// Create a copy of SwipeFeedback
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SwipeFeedbackCopyWith<_SwipeFeedback> get copyWith => __$SwipeFeedbackCopyWithImpl<_SwipeFeedback>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SwipeFeedbackToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SwipeFeedback&&(identical(other.action, action) || other.action == action)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.missingIngredientId, missingIngredientId) || other.missingIngredientId == missingIngredientId)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.servingsCooked, servingsCooked) || other.servingsCooked == servingsCooked)&&(identical(other.comment, comment) || other.comment == comment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,action,reason,sessionId,missingIngredientId,rating,servingsCooked,comment);

@override
String toString() {
  return 'SwipeFeedback(action: $action, reason: $reason, sessionId: $sessionId, missingIngredientId: $missingIngredientId, rating: $rating, servingsCooked: $servingsCooked, comment: $comment)';
}


}

/// @nodoc
abstract mixin class _$SwipeFeedbackCopyWith<$Res> implements $SwipeFeedbackCopyWith<$Res> {
  factory _$SwipeFeedbackCopyWith(_SwipeFeedback value, $Res Function(_SwipeFeedback) _then) = __$SwipeFeedbackCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: feedbackActionFromJson, toJson: feedbackActionToJson) FeedbackAction action,@JsonKey(fromJson: _reasonOrNull, toJson: _reasonOrNullJson) FeedbackReason? reason,@JsonKey(name: 'session_id') int? sessionId,@JsonKey(name: 'missing_ingredient_id') int? missingIngredientId, int? rating,@JsonKey(name: 'servings_cooked') double? servingsCooked, String? comment
});




}
/// @nodoc
class __$SwipeFeedbackCopyWithImpl<$Res>
    implements _$SwipeFeedbackCopyWith<$Res> {
  __$SwipeFeedbackCopyWithImpl(this._self, this._then);

  final _SwipeFeedback _self;
  final $Res Function(_SwipeFeedback) _then;

/// Create a copy of SwipeFeedback
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? action = null,Object? reason = freezed,Object? sessionId = freezed,Object? missingIngredientId = freezed,Object? rating = freezed,Object? servingsCooked = freezed,Object? comment = freezed,}) {
  return _then(_SwipeFeedback(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as FeedbackAction,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as FeedbackReason?,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as int?,missingIngredientId: freezed == missingIngredientId ? _self.missingIngredientId : missingIngredientId // ignore: cast_nullable_to_non_nullable
as int?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int?,servingsCooked: freezed == servingsCooked ? _self.servingsCooked : servingsCooked // ignore: cast_nullable_to_non_nullable
as double?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
