// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MealLog {

 int get id;@JsonKey(name: 'logged_date') DateTime get loggedDate;@JsonKey(name: 'meal_type', fromJson: mealTypeFromJson, toJson: mealTypeToJson) MealType get mealType;@JsonKey(fromJson: logSourceFromJson, toJson: logSourceToJson) LogSource get source;@JsonKey(name: 'item_name') String get itemName; double get servings;@JsonKey(name: 'quantity_g') double? get quantityG; double get calories;@JsonKey(name: 'protein_g') double? get proteinG;@JsonKey(name: 'carb_g') double? get carbG;@JsonKey(name: 'fat_g') double? get fatG;@JsonKey(name: 'recipe_id') String? get recipeId;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of MealLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealLogCopyWith<MealLog> get copyWith => _$MealLogCopyWithImpl<MealLog>(this as MealLog, _$identity);

  /// Serializes this MealLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealLog&&(identical(other.id, id) || other.id == id)&&(identical(other.loggedDate, loggedDate) || other.loggedDate == loggedDate)&&(identical(other.mealType, mealType) || other.mealType == mealType)&&(identical(other.source, source) || other.source == source)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.servings, servings) || other.servings == servings)&&(identical(other.quantityG, quantityG) || other.quantityG == quantityG)&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbG, carbG) || other.carbG == carbG)&&(identical(other.fatG, fatG) || other.fatG == fatG)&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,loggedDate,mealType,source,itemName,servings,quantityG,calories,proteinG,carbG,fatG,recipeId,createdAt);

@override
String toString() {
  return 'MealLog(id: $id, loggedDate: $loggedDate, mealType: $mealType, source: $source, itemName: $itemName, servings: $servings, quantityG: $quantityG, calories: $calories, proteinG: $proteinG, carbG: $carbG, fatG: $fatG, recipeId: $recipeId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MealLogCopyWith<$Res>  {
  factory $MealLogCopyWith(MealLog value, $Res Function(MealLog) _then) = _$MealLogCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'logged_date') DateTime loggedDate,@JsonKey(name: 'meal_type', fromJson: mealTypeFromJson, toJson: mealTypeToJson) MealType mealType,@JsonKey(fromJson: logSourceFromJson, toJson: logSourceToJson) LogSource source,@JsonKey(name: 'item_name') String itemName, double servings,@JsonKey(name: 'quantity_g') double? quantityG, double calories,@JsonKey(name: 'protein_g') double? proteinG,@JsonKey(name: 'carb_g') double? carbG,@JsonKey(name: 'fat_g') double? fatG,@JsonKey(name: 'recipe_id') String? recipeId,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$MealLogCopyWithImpl<$Res>
    implements $MealLogCopyWith<$Res> {
  _$MealLogCopyWithImpl(this._self, this._then);

  final MealLog _self;
  final $Res Function(MealLog) _then;

/// Create a copy of MealLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? loggedDate = null,Object? mealType = null,Object? source = null,Object? itemName = null,Object? servings = null,Object? quantityG = freezed,Object? calories = null,Object? proteinG = freezed,Object? carbG = freezed,Object? fatG = freezed,Object? recipeId = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,loggedDate: null == loggedDate ? _self.loggedDate : loggedDate // ignore: cast_nullable_to_non_nullable
as DateTime,mealType: null == mealType ? _self.mealType : mealType // ignore: cast_nullable_to_non_nullable
as MealType,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as LogSource,itemName: null == itemName ? _self.itemName : itemName // ignore: cast_nullable_to_non_nullable
as String,servings: null == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as double,quantityG: freezed == quantityG ? _self.quantityG : quantityG // ignore: cast_nullable_to_non_nullable
as double?,calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as double,proteinG: freezed == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as double?,carbG: freezed == carbG ? _self.carbG : carbG // ignore: cast_nullable_to_non_nullable
as double?,fatG: freezed == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as double?,recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MealLog].
extension MealLogPatterns on MealLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealLog value)  $default,){
final _that = this;
switch (_that) {
case _MealLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealLog value)?  $default,){
final _that = this;
switch (_that) {
case _MealLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'logged_date')  DateTime loggedDate, @JsonKey(name: 'meal_type', fromJson: mealTypeFromJson, toJson: mealTypeToJson)  MealType mealType, @JsonKey(fromJson: logSourceFromJson, toJson: logSourceToJson)  LogSource source, @JsonKey(name: 'item_name')  String itemName,  double servings, @JsonKey(name: 'quantity_g')  double? quantityG,  double calories, @JsonKey(name: 'protein_g')  double? proteinG, @JsonKey(name: 'carb_g')  double? carbG, @JsonKey(name: 'fat_g')  double? fatG, @JsonKey(name: 'recipe_id')  String? recipeId, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealLog() when $default != null:
return $default(_that.id,_that.loggedDate,_that.mealType,_that.source,_that.itemName,_that.servings,_that.quantityG,_that.calories,_that.proteinG,_that.carbG,_that.fatG,_that.recipeId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'logged_date')  DateTime loggedDate, @JsonKey(name: 'meal_type', fromJson: mealTypeFromJson, toJson: mealTypeToJson)  MealType mealType, @JsonKey(fromJson: logSourceFromJson, toJson: logSourceToJson)  LogSource source, @JsonKey(name: 'item_name')  String itemName,  double servings, @JsonKey(name: 'quantity_g')  double? quantityG,  double calories, @JsonKey(name: 'protein_g')  double? proteinG, @JsonKey(name: 'carb_g')  double? carbG, @JsonKey(name: 'fat_g')  double? fatG, @JsonKey(name: 'recipe_id')  String? recipeId, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _MealLog():
return $default(_that.id,_that.loggedDate,_that.mealType,_that.source,_that.itemName,_that.servings,_that.quantityG,_that.calories,_that.proteinG,_that.carbG,_that.fatG,_that.recipeId,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'logged_date')  DateTime loggedDate, @JsonKey(name: 'meal_type', fromJson: mealTypeFromJson, toJson: mealTypeToJson)  MealType mealType, @JsonKey(fromJson: logSourceFromJson, toJson: logSourceToJson)  LogSource source, @JsonKey(name: 'item_name')  String itemName,  double servings, @JsonKey(name: 'quantity_g')  double? quantityG,  double calories, @JsonKey(name: 'protein_g')  double? proteinG, @JsonKey(name: 'carb_g')  double? carbG, @JsonKey(name: 'fat_g')  double? fatG, @JsonKey(name: 'recipe_id')  String? recipeId, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MealLog() when $default != null:
return $default(_that.id,_that.loggedDate,_that.mealType,_that.source,_that.itemName,_that.servings,_that.quantityG,_that.calories,_that.proteinG,_that.carbG,_that.fatG,_that.recipeId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MealLog implements MealLog {
  const _MealLog({required this.id, @JsonKey(name: 'logged_date') required this.loggedDate, @JsonKey(name: 'meal_type', fromJson: mealTypeFromJson, toJson: mealTypeToJson) required this.mealType, @JsonKey(fromJson: logSourceFromJson, toJson: logSourceToJson) required this.source, @JsonKey(name: 'item_name') required this.itemName, required this.servings, @JsonKey(name: 'quantity_g') this.quantityG, required this.calories, @JsonKey(name: 'protein_g') this.proteinG, @JsonKey(name: 'carb_g') this.carbG, @JsonKey(name: 'fat_g') this.fatG, @JsonKey(name: 'recipe_id') this.recipeId, @JsonKey(name: 'created_at') required this.createdAt});
  factory _MealLog.fromJson(Map<String, dynamic> json) => _$MealLogFromJson(json);

@override final  int id;
@override@JsonKey(name: 'logged_date') final  DateTime loggedDate;
@override@JsonKey(name: 'meal_type', fromJson: mealTypeFromJson, toJson: mealTypeToJson) final  MealType mealType;
@override@JsonKey(fromJson: logSourceFromJson, toJson: logSourceToJson) final  LogSource source;
@override@JsonKey(name: 'item_name') final  String itemName;
@override final  double servings;
@override@JsonKey(name: 'quantity_g') final  double? quantityG;
@override final  double calories;
@override@JsonKey(name: 'protein_g') final  double? proteinG;
@override@JsonKey(name: 'carb_g') final  double? carbG;
@override@JsonKey(name: 'fat_g') final  double? fatG;
@override@JsonKey(name: 'recipe_id') final  String? recipeId;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of MealLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealLogCopyWith<_MealLog> get copyWith => __$MealLogCopyWithImpl<_MealLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MealLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealLog&&(identical(other.id, id) || other.id == id)&&(identical(other.loggedDate, loggedDate) || other.loggedDate == loggedDate)&&(identical(other.mealType, mealType) || other.mealType == mealType)&&(identical(other.source, source) || other.source == source)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.servings, servings) || other.servings == servings)&&(identical(other.quantityG, quantityG) || other.quantityG == quantityG)&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbG, carbG) || other.carbG == carbG)&&(identical(other.fatG, fatG) || other.fatG == fatG)&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,loggedDate,mealType,source,itemName,servings,quantityG,calories,proteinG,carbG,fatG,recipeId,createdAt);

@override
String toString() {
  return 'MealLog(id: $id, loggedDate: $loggedDate, mealType: $mealType, source: $source, itemName: $itemName, servings: $servings, quantityG: $quantityG, calories: $calories, proteinG: $proteinG, carbG: $carbG, fatG: $fatG, recipeId: $recipeId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MealLogCopyWith<$Res> implements $MealLogCopyWith<$Res> {
  factory _$MealLogCopyWith(_MealLog value, $Res Function(_MealLog) _then) = __$MealLogCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'logged_date') DateTime loggedDate,@JsonKey(name: 'meal_type', fromJson: mealTypeFromJson, toJson: mealTypeToJson) MealType mealType,@JsonKey(fromJson: logSourceFromJson, toJson: logSourceToJson) LogSource source,@JsonKey(name: 'item_name') String itemName, double servings,@JsonKey(name: 'quantity_g') double? quantityG, double calories,@JsonKey(name: 'protein_g') double? proteinG,@JsonKey(name: 'carb_g') double? carbG,@JsonKey(name: 'fat_g') double? fatG,@JsonKey(name: 'recipe_id') String? recipeId,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$MealLogCopyWithImpl<$Res>
    implements _$MealLogCopyWith<$Res> {
  __$MealLogCopyWithImpl(this._self, this._then);

  final _MealLog _self;
  final $Res Function(_MealLog) _then;

/// Create a copy of MealLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? loggedDate = null,Object? mealType = null,Object? source = null,Object? itemName = null,Object? servings = null,Object? quantityG = freezed,Object? calories = null,Object? proteinG = freezed,Object? carbG = freezed,Object? fatG = freezed,Object? recipeId = freezed,Object? createdAt = null,}) {
  return _then(_MealLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,loggedDate: null == loggedDate ? _self.loggedDate : loggedDate // ignore: cast_nullable_to_non_nullable
as DateTime,mealType: null == mealType ? _self.mealType : mealType // ignore: cast_nullable_to_non_nullable
as MealType,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as LogSource,itemName: null == itemName ? _self.itemName : itemName // ignore: cast_nullable_to_non_nullable
as String,servings: null == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as double,quantityG: freezed == quantityG ? _self.quantityG : quantityG // ignore: cast_nullable_to_non_nullable
as double?,calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as double,proteinG: freezed == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as double?,carbG: freezed == carbG ? _self.carbG : carbG // ignore: cast_nullable_to_non_nullable
as double?,fatG: freezed == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as double?,recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
