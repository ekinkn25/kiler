// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DailySummary {

@JsonKey(name: 'logged_date') DateTime get loggedDate;@JsonKey(name: 'calorie_target') double get calorieTarget;@JsonKey(name: 'calories_consumed') double get caloriesConsumed;@JsonKey(name: 'calories_remaining') double get caloriesRemaining;@JsonKey(name: 'macros_consumed') MacroBreakdown get macrosConsumed;@JsonKey(name: 'macros_target') MacroBreakdown get macrosTarget;// NEDEN Map<String,...>: backend'de meal_type ENUM anahtarli bir
// sozluk, ama JSON'da anahtarlar HER ZAMAN metindir ('kahvalti' gibi).
// Gerekirse cagiran taraf mealTypeFromJson(anahtar) ile enum'a cevirir.
 Map<String, List<MealLog>> get meals;
/// Create a copy of DailySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailySummaryCopyWith<DailySummary> get copyWith => _$DailySummaryCopyWithImpl<DailySummary>(this as DailySummary, _$identity);

  /// Serializes this DailySummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailySummary&&(identical(other.loggedDate, loggedDate) || other.loggedDate == loggedDate)&&(identical(other.calorieTarget, calorieTarget) || other.calorieTarget == calorieTarget)&&(identical(other.caloriesConsumed, caloriesConsumed) || other.caloriesConsumed == caloriesConsumed)&&(identical(other.caloriesRemaining, caloriesRemaining) || other.caloriesRemaining == caloriesRemaining)&&(identical(other.macrosConsumed, macrosConsumed) || other.macrosConsumed == macrosConsumed)&&(identical(other.macrosTarget, macrosTarget) || other.macrosTarget == macrosTarget)&&const DeepCollectionEquality().equals(other.meals, meals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,loggedDate,calorieTarget,caloriesConsumed,caloriesRemaining,macrosConsumed,macrosTarget,const DeepCollectionEquality().hash(meals));

@override
String toString() {
  return 'DailySummary(loggedDate: $loggedDate, calorieTarget: $calorieTarget, caloriesConsumed: $caloriesConsumed, caloriesRemaining: $caloriesRemaining, macrosConsumed: $macrosConsumed, macrosTarget: $macrosTarget, meals: $meals)';
}


}

/// @nodoc
abstract mixin class $DailySummaryCopyWith<$Res>  {
  factory $DailySummaryCopyWith(DailySummary value, $Res Function(DailySummary) _then) = _$DailySummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'logged_date') DateTime loggedDate,@JsonKey(name: 'calorie_target') double calorieTarget,@JsonKey(name: 'calories_consumed') double caloriesConsumed,@JsonKey(name: 'calories_remaining') double caloriesRemaining,@JsonKey(name: 'macros_consumed') MacroBreakdown macrosConsumed,@JsonKey(name: 'macros_target') MacroBreakdown macrosTarget, Map<String, List<MealLog>> meals
});


$MacroBreakdownCopyWith<$Res> get macrosConsumed;$MacroBreakdownCopyWith<$Res> get macrosTarget;

}
/// @nodoc
class _$DailySummaryCopyWithImpl<$Res>
    implements $DailySummaryCopyWith<$Res> {
  _$DailySummaryCopyWithImpl(this._self, this._then);

  final DailySummary _self;
  final $Res Function(DailySummary) _then;

/// Create a copy of DailySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loggedDate = null,Object? calorieTarget = null,Object? caloriesConsumed = null,Object? caloriesRemaining = null,Object? macrosConsumed = null,Object? macrosTarget = null,Object? meals = null,}) {
  return _then(_self.copyWith(
loggedDate: null == loggedDate ? _self.loggedDate : loggedDate // ignore: cast_nullable_to_non_nullable
as DateTime,calorieTarget: null == calorieTarget ? _self.calorieTarget : calorieTarget // ignore: cast_nullable_to_non_nullable
as double,caloriesConsumed: null == caloriesConsumed ? _self.caloriesConsumed : caloriesConsumed // ignore: cast_nullable_to_non_nullable
as double,caloriesRemaining: null == caloriesRemaining ? _self.caloriesRemaining : caloriesRemaining // ignore: cast_nullable_to_non_nullable
as double,macrosConsumed: null == macrosConsumed ? _self.macrosConsumed : macrosConsumed // ignore: cast_nullable_to_non_nullable
as MacroBreakdown,macrosTarget: null == macrosTarget ? _self.macrosTarget : macrosTarget // ignore: cast_nullable_to_non_nullable
as MacroBreakdown,meals: null == meals ? _self.meals : meals // ignore: cast_nullable_to_non_nullable
as Map<String, List<MealLog>>,
  ));
}
/// Create a copy of DailySummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MacroBreakdownCopyWith<$Res> get macrosConsumed {
  
  return $MacroBreakdownCopyWith<$Res>(_self.macrosConsumed, (value) {
    return _then(_self.copyWith(macrosConsumed: value));
  });
}/// Create a copy of DailySummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MacroBreakdownCopyWith<$Res> get macrosTarget {
  
  return $MacroBreakdownCopyWith<$Res>(_self.macrosTarget, (value) {
    return _then(_self.copyWith(macrosTarget: value));
  });
}
}


/// Adds pattern-matching-related methods to [DailySummary].
extension DailySummaryPatterns on DailySummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailySummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailySummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailySummary value)  $default,){
final _that = this;
switch (_that) {
case _DailySummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailySummary value)?  $default,){
final _that = this;
switch (_that) {
case _DailySummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'logged_date')  DateTime loggedDate, @JsonKey(name: 'calorie_target')  double calorieTarget, @JsonKey(name: 'calories_consumed')  double caloriesConsumed, @JsonKey(name: 'calories_remaining')  double caloriesRemaining, @JsonKey(name: 'macros_consumed')  MacroBreakdown macrosConsumed, @JsonKey(name: 'macros_target')  MacroBreakdown macrosTarget,  Map<String, List<MealLog>> meals)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailySummary() when $default != null:
return $default(_that.loggedDate,_that.calorieTarget,_that.caloriesConsumed,_that.caloriesRemaining,_that.macrosConsumed,_that.macrosTarget,_that.meals);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'logged_date')  DateTime loggedDate, @JsonKey(name: 'calorie_target')  double calorieTarget, @JsonKey(name: 'calories_consumed')  double caloriesConsumed, @JsonKey(name: 'calories_remaining')  double caloriesRemaining, @JsonKey(name: 'macros_consumed')  MacroBreakdown macrosConsumed, @JsonKey(name: 'macros_target')  MacroBreakdown macrosTarget,  Map<String, List<MealLog>> meals)  $default,) {final _that = this;
switch (_that) {
case _DailySummary():
return $default(_that.loggedDate,_that.calorieTarget,_that.caloriesConsumed,_that.caloriesRemaining,_that.macrosConsumed,_that.macrosTarget,_that.meals);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'logged_date')  DateTime loggedDate, @JsonKey(name: 'calorie_target')  double calorieTarget, @JsonKey(name: 'calories_consumed')  double caloriesConsumed, @JsonKey(name: 'calories_remaining')  double caloriesRemaining, @JsonKey(name: 'macros_consumed')  MacroBreakdown macrosConsumed, @JsonKey(name: 'macros_target')  MacroBreakdown macrosTarget,  Map<String, List<MealLog>> meals)?  $default,) {final _that = this;
switch (_that) {
case _DailySummary() when $default != null:
return $default(_that.loggedDate,_that.calorieTarget,_that.caloriesConsumed,_that.caloriesRemaining,_that.macrosConsumed,_that.macrosTarget,_that.meals);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailySummary implements DailySummary {
  const _DailySummary({@JsonKey(name: 'logged_date') required this.loggedDate, @JsonKey(name: 'calorie_target') required this.calorieTarget, @JsonKey(name: 'calories_consumed') required this.caloriesConsumed, @JsonKey(name: 'calories_remaining') required this.caloriesRemaining, @JsonKey(name: 'macros_consumed') required this.macrosConsumed, @JsonKey(name: 'macros_target') required this.macrosTarget, required final  Map<String, List<MealLog>> meals}): _meals = meals;
  factory _DailySummary.fromJson(Map<String, dynamic> json) => _$DailySummaryFromJson(json);

@override@JsonKey(name: 'logged_date') final  DateTime loggedDate;
@override@JsonKey(name: 'calorie_target') final  double calorieTarget;
@override@JsonKey(name: 'calories_consumed') final  double caloriesConsumed;
@override@JsonKey(name: 'calories_remaining') final  double caloriesRemaining;
@override@JsonKey(name: 'macros_consumed') final  MacroBreakdown macrosConsumed;
@override@JsonKey(name: 'macros_target') final  MacroBreakdown macrosTarget;
// NEDEN Map<String,...>: backend'de meal_type ENUM anahtarli bir
// sozluk, ama JSON'da anahtarlar HER ZAMAN metindir ('kahvalti' gibi).
// Gerekirse cagiran taraf mealTypeFromJson(anahtar) ile enum'a cevirir.
 final  Map<String, List<MealLog>> _meals;
// NEDEN Map<String,...>: backend'de meal_type ENUM anahtarli bir
// sozluk, ama JSON'da anahtarlar HER ZAMAN metindir ('kahvalti' gibi).
// Gerekirse cagiran taraf mealTypeFromJson(anahtar) ile enum'a cevirir.
@override Map<String, List<MealLog>> get meals {
  if (_meals is EqualUnmodifiableMapView) return _meals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_meals);
}


/// Create a copy of DailySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailySummaryCopyWith<_DailySummary> get copyWith => __$DailySummaryCopyWithImpl<_DailySummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailySummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailySummary&&(identical(other.loggedDate, loggedDate) || other.loggedDate == loggedDate)&&(identical(other.calorieTarget, calorieTarget) || other.calorieTarget == calorieTarget)&&(identical(other.caloriesConsumed, caloriesConsumed) || other.caloriesConsumed == caloriesConsumed)&&(identical(other.caloriesRemaining, caloriesRemaining) || other.caloriesRemaining == caloriesRemaining)&&(identical(other.macrosConsumed, macrosConsumed) || other.macrosConsumed == macrosConsumed)&&(identical(other.macrosTarget, macrosTarget) || other.macrosTarget == macrosTarget)&&const DeepCollectionEquality().equals(other._meals, _meals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,loggedDate,calorieTarget,caloriesConsumed,caloriesRemaining,macrosConsumed,macrosTarget,const DeepCollectionEquality().hash(_meals));

@override
String toString() {
  return 'DailySummary(loggedDate: $loggedDate, calorieTarget: $calorieTarget, caloriesConsumed: $caloriesConsumed, caloriesRemaining: $caloriesRemaining, macrosConsumed: $macrosConsumed, macrosTarget: $macrosTarget, meals: $meals)';
}


}

/// @nodoc
abstract mixin class _$DailySummaryCopyWith<$Res> implements $DailySummaryCopyWith<$Res> {
  factory _$DailySummaryCopyWith(_DailySummary value, $Res Function(_DailySummary) _then) = __$DailySummaryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'logged_date') DateTime loggedDate,@JsonKey(name: 'calorie_target') double calorieTarget,@JsonKey(name: 'calories_consumed') double caloriesConsumed,@JsonKey(name: 'calories_remaining') double caloriesRemaining,@JsonKey(name: 'macros_consumed') MacroBreakdown macrosConsumed,@JsonKey(name: 'macros_target') MacroBreakdown macrosTarget, Map<String, List<MealLog>> meals
});


@override $MacroBreakdownCopyWith<$Res> get macrosConsumed;@override $MacroBreakdownCopyWith<$Res> get macrosTarget;

}
/// @nodoc
class __$DailySummaryCopyWithImpl<$Res>
    implements _$DailySummaryCopyWith<$Res> {
  __$DailySummaryCopyWithImpl(this._self, this._then);

  final _DailySummary _self;
  final $Res Function(_DailySummary) _then;

/// Create a copy of DailySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? loggedDate = null,Object? calorieTarget = null,Object? caloriesConsumed = null,Object? caloriesRemaining = null,Object? macrosConsumed = null,Object? macrosTarget = null,Object? meals = null,}) {
  return _then(_DailySummary(
loggedDate: null == loggedDate ? _self.loggedDate : loggedDate // ignore: cast_nullable_to_non_nullable
as DateTime,calorieTarget: null == calorieTarget ? _self.calorieTarget : calorieTarget // ignore: cast_nullable_to_non_nullable
as double,caloriesConsumed: null == caloriesConsumed ? _self.caloriesConsumed : caloriesConsumed // ignore: cast_nullable_to_non_nullable
as double,caloriesRemaining: null == caloriesRemaining ? _self.caloriesRemaining : caloriesRemaining // ignore: cast_nullable_to_non_nullable
as double,macrosConsumed: null == macrosConsumed ? _self.macrosConsumed : macrosConsumed // ignore: cast_nullable_to_non_nullable
as MacroBreakdown,macrosTarget: null == macrosTarget ? _self.macrosTarget : macrosTarget // ignore: cast_nullable_to_non_nullable
as MacroBreakdown,meals: null == meals ? _self._meals : meals // ignore: cast_nullable_to_non_nullable
as Map<String, List<MealLog>>,
  ));
}

/// Create a copy of DailySummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MacroBreakdownCopyWith<$Res> get macrosConsumed {
  
  return $MacroBreakdownCopyWith<$Res>(_self.macrosConsumed, (value) {
    return _then(_self.copyWith(macrosConsumed: value));
  });
}/// Create a copy of DailySummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MacroBreakdownCopyWith<$Res> get macrosTarget {
  
  return $MacroBreakdownCopyWith<$Res>(_self.macrosTarget, (value) {
    return _then(_self.copyWith(macrosTarget: value));
  });
}
}


/// @nodoc
mixin _$MacroBreakdown {

@JsonKey(name: 'protein_g') double get proteinG;@JsonKey(name: 'carb_g') double get carbG;@JsonKey(name: 'fat_g') double get fatG;@JsonKey(name: 'fiber_g') double get fiberG;
/// Create a copy of MacroBreakdown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MacroBreakdownCopyWith<MacroBreakdown> get copyWith => _$MacroBreakdownCopyWithImpl<MacroBreakdown>(this as MacroBreakdown, _$identity);

  /// Serializes this MacroBreakdown to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MacroBreakdown&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbG, carbG) || other.carbG == carbG)&&(identical(other.fatG, fatG) || other.fatG == fatG)&&(identical(other.fiberG, fiberG) || other.fiberG == fiberG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,proteinG,carbG,fatG,fiberG);

@override
String toString() {
  return 'MacroBreakdown(proteinG: $proteinG, carbG: $carbG, fatG: $fatG, fiberG: $fiberG)';
}


}

/// @nodoc
abstract mixin class $MacroBreakdownCopyWith<$Res>  {
  factory $MacroBreakdownCopyWith(MacroBreakdown value, $Res Function(MacroBreakdown) _then) = _$MacroBreakdownCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'protein_g') double proteinG,@JsonKey(name: 'carb_g') double carbG,@JsonKey(name: 'fat_g') double fatG,@JsonKey(name: 'fiber_g') double fiberG
});




}
/// @nodoc
class _$MacroBreakdownCopyWithImpl<$Res>
    implements $MacroBreakdownCopyWith<$Res> {
  _$MacroBreakdownCopyWithImpl(this._self, this._then);

  final MacroBreakdown _self;
  final $Res Function(MacroBreakdown) _then;

/// Create a copy of MacroBreakdown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? proteinG = null,Object? carbG = null,Object? fatG = null,Object? fiberG = null,}) {
  return _then(_self.copyWith(
proteinG: null == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as double,carbG: null == carbG ? _self.carbG : carbG // ignore: cast_nullable_to_non_nullable
as double,fatG: null == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as double,fiberG: null == fiberG ? _self.fiberG : fiberG // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [MacroBreakdown].
extension MacroBreakdownPatterns on MacroBreakdown {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MacroBreakdown value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MacroBreakdown() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MacroBreakdown value)  $default,){
final _that = this;
switch (_that) {
case _MacroBreakdown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MacroBreakdown value)?  $default,){
final _that = this;
switch (_that) {
case _MacroBreakdown() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'protein_g')  double proteinG, @JsonKey(name: 'carb_g')  double carbG, @JsonKey(name: 'fat_g')  double fatG, @JsonKey(name: 'fiber_g')  double fiberG)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MacroBreakdown() when $default != null:
return $default(_that.proteinG,_that.carbG,_that.fatG,_that.fiberG);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'protein_g')  double proteinG, @JsonKey(name: 'carb_g')  double carbG, @JsonKey(name: 'fat_g')  double fatG, @JsonKey(name: 'fiber_g')  double fiberG)  $default,) {final _that = this;
switch (_that) {
case _MacroBreakdown():
return $default(_that.proteinG,_that.carbG,_that.fatG,_that.fiberG);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'protein_g')  double proteinG, @JsonKey(name: 'carb_g')  double carbG, @JsonKey(name: 'fat_g')  double fatG, @JsonKey(name: 'fiber_g')  double fiberG)?  $default,) {final _that = this;
switch (_that) {
case _MacroBreakdown() when $default != null:
return $default(_that.proteinG,_that.carbG,_that.fatG,_that.fiberG);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MacroBreakdown implements MacroBreakdown {
  const _MacroBreakdown({@JsonKey(name: 'protein_g') this.proteinG = 0, @JsonKey(name: 'carb_g') this.carbG = 0, @JsonKey(name: 'fat_g') this.fatG = 0, @JsonKey(name: 'fiber_g') this.fiberG = 0});
  factory _MacroBreakdown.fromJson(Map<String, dynamic> json) => _$MacroBreakdownFromJson(json);

@override@JsonKey(name: 'protein_g') final  double proteinG;
@override@JsonKey(name: 'carb_g') final  double carbG;
@override@JsonKey(name: 'fat_g') final  double fatG;
@override@JsonKey(name: 'fiber_g') final  double fiberG;

/// Create a copy of MacroBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MacroBreakdownCopyWith<_MacroBreakdown> get copyWith => __$MacroBreakdownCopyWithImpl<_MacroBreakdown>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MacroBreakdownToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MacroBreakdown&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbG, carbG) || other.carbG == carbG)&&(identical(other.fatG, fatG) || other.fatG == fatG)&&(identical(other.fiberG, fiberG) || other.fiberG == fiberG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,proteinG,carbG,fatG,fiberG);

@override
String toString() {
  return 'MacroBreakdown(proteinG: $proteinG, carbG: $carbG, fatG: $fatG, fiberG: $fiberG)';
}


}

/// @nodoc
abstract mixin class _$MacroBreakdownCopyWith<$Res> implements $MacroBreakdownCopyWith<$Res> {
  factory _$MacroBreakdownCopyWith(_MacroBreakdown value, $Res Function(_MacroBreakdown) _then) = __$MacroBreakdownCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'protein_g') double proteinG,@JsonKey(name: 'carb_g') double carbG,@JsonKey(name: 'fat_g') double fatG,@JsonKey(name: 'fiber_g') double fiberG
});




}
/// @nodoc
class __$MacroBreakdownCopyWithImpl<$Res>
    implements _$MacroBreakdownCopyWith<$Res> {
  __$MacroBreakdownCopyWithImpl(this._self, this._then);

  final _MacroBreakdown _self;
  final $Res Function(_MacroBreakdown) _then;

/// Create a copy of MacroBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? proteinG = null,Object? carbG = null,Object? fatG = null,Object? fiberG = null,}) {
  return _then(_MacroBreakdown(
proteinG: null == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as double,carbG: null == carbG ? _self.carbG : carbG // ignore: cast_nullable_to_non_nullable
as double,fatG: null == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as double,fiberG: null == fiberG ? _self.fiberG : fiberG // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
