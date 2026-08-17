// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecipeCard {

 String get id; String get title; String get slug;@JsonKey(name: 'image_url') String? get imageUrl;@JsonKey(name: 'calories_per_serving') double get caloriesPerServing; int get servings;@JsonKey(name: 'prep_time') int? get prepTime;@JsonKey(name: 'cook_time') int? get cookTime; String? get difficulty; String? get cuisine;@JsonKey(name: 'diet_tags') List<String> get dietTags; List<String> get allergens;@JsonKey(name: 'final_score') double get finalScore;@JsonKey(name: 'score_breakdown') ScoreBreakdown get scoreBreakdown;@JsonKey(name: 'matched_ingredients') List<String> get matchedIngredients;@JsonKey(name: 'unknown_ingredients') List<String> get unknownIngredients;@JsonKey(name: 'missing_ingredients') List<String> get missingIngredients;@JsonKey(name: 'total_required') int get totalRequired;
/// Create a copy of RecipeCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeCardCopyWith<RecipeCard> get copyWith => _$RecipeCardCopyWithImpl<RecipeCard>(this as RecipeCard, _$identity);

  /// Serializes this RecipeCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeCard&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.caloriesPerServing, caloriesPerServing) || other.caloriesPerServing == caloriesPerServing)&&(identical(other.servings, servings) || other.servings == servings)&&(identical(other.prepTime, prepTime) || other.prepTime == prepTime)&&(identical(other.cookTime, cookTime) || other.cookTime == cookTime)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.cuisine, cuisine) || other.cuisine == cuisine)&&const DeepCollectionEquality().equals(other.dietTags, dietTags)&&const DeepCollectionEquality().equals(other.allergens, allergens)&&(identical(other.finalScore, finalScore) || other.finalScore == finalScore)&&(identical(other.scoreBreakdown, scoreBreakdown) || other.scoreBreakdown == scoreBreakdown)&&const DeepCollectionEquality().equals(other.matchedIngredients, matchedIngredients)&&const DeepCollectionEquality().equals(other.unknownIngredients, unknownIngredients)&&const DeepCollectionEquality().equals(other.missingIngredients, missingIngredients)&&(identical(other.totalRequired, totalRequired) || other.totalRequired == totalRequired));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,slug,imageUrl,caloriesPerServing,servings,prepTime,cookTime,difficulty,cuisine,const DeepCollectionEquality().hash(dietTags),const DeepCollectionEquality().hash(allergens),finalScore,scoreBreakdown,const DeepCollectionEquality().hash(matchedIngredients),const DeepCollectionEquality().hash(unknownIngredients),const DeepCollectionEquality().hash(missingIngredients),totalRequired);

@override
String toString() {
  return 'RecipeCard(id: $id, title: $title, slug: $slug, imageUrl: $imageUrl, caloriesPerServing: $caloriesPerServing, servings: $servings, prepTime: $prepTime, cookTime: $cookTime, difficulty: $difficulty, cuisine: $cuisine, dietTags: $dietTags, allergens: $allergens, finalScore: $finalScore, scoreBreakdown: $scoreBreakdown, matchedIngredients: $matchedIngredients, unknownIngredients: $unknownIngredients, missingIngredients: $missingIngredients, totalRequired: $totalRequired)';
}


}

/// @nodoc
abstract mixin class $RecipeCardCopyWith<$Res>  {
  factory $RecipeCardCopyWith(RecipeCard value, $Res Function(RecipeCard) _then) = _$RecipeCardCopyWithImpl;
@useResult
$Res call({
 String id, String title, String slug,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(name: 'calories_per_serving') double caloriesPerServing, int servings,@JsonKey(name: 'prep_time') int? prepTime,@JsonKey(name: 'cook_time') int? cookTime, String? difficulty, String? cuisine,@JsonKey(name: 'diet_tags') List<String> dietTags, List<String> allergens,@JsonKey(name: 'final_score') double finalScore,@JsonKey(name: 'score_breakdown') ScoreBreakdown scoreBreakdown,@JsonKey(name: 'matched_ingredients') List<String> matchedIngredients,@JsonKey(name: 'unknown_ingredients') List<String> unknownIngredients,@JsonKey(name: 'missing_ingredients') List<String> missingIngredients,@JsonKey(name: 'total_required') int totalRequired
});


$ScoreBreakdownCopyWith<$Res> get scoreBreakdown;

}
/// @nodoc
class _$RecipeCardCopyWithImpl<$Res>
    implements $RecipeCardCopyWith<$Res> {
  _$RecipeCardCopyWithImpl(this._self, this._then);

  final RecipeCard _self;
  final $Res Function(RecipeCard) _then;

/// Create a copy of RecipeCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? slug = null,Object? imageUrl = freezed,Object? caloriesPerServing = null,Object? servings = null,Object? prepTime = freezed,Object? cookTime = freezed,Object? difficulty = freezed,Object? cuisine = freezed,Object? dietTags = null,Object? allergens = null,Object? finalScore = null,Object? scoreBreakdown = null,Object? matchedIngredients = null,Object? unknownIngredients = null,Object? missingIngredients = null,Object? totalRequired = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,caloriesPerServing: null == caloriesPerServing ? _self.caloriesPerServing : caloriesPerServing // ignore: cast_nullable_to_non_nullable
as double,servings: null == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as int,prepTime: freezed == prepTime ? _self.prepTime : prepTime // ignore: cast_nullable_to_non_nullable
as int?,cookTime: freezed == cookTime ? _self.cookTime : cookTime // ignore: cast_nullable_to_non_nullable
as int?,difficulty: freezed == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as String?,cuisine: freezed == cuisine ? _self.cuisine : cuisine // ignore: cast_nullable_to_non_nullable
as String?,dietTags: null == dietTags ? _self.dietTags : dietTags // ignore: cast_nullable_to_non_nullable
as List<String>,allergens: null == allergens ? _self.allergens : allergens // ignore: cast_nullable_to_non_nullable
as List<String>,finalScore: null == finalScore ? _self.finalScore : finalScore // ignore: cast_nullable_to_non_nullable
as double,scoreBreakdown: null == scoreBreakdown ? _self.scoreBreakdown : scoreBreakdown // ignore: cast_nullable_to_non_nullable
as ScoreBreakdown,matchedIngredients: null == matchedIngredients ? _self.matchedIngredients : matchedIngredients // ignore: cast_nullable_to_non_nullable
as List<String>,unknownIngredients: null == unknownIngredients ? _self.unknownIngredients : unknownIngredients // ignore: cast_nullable_to_non_nullable
as List<String>,missingIngredients: null == missingIngredients ? _self.missingIngredients : missingIngredients // ignore: cast_nullable_to_non_nullable
as List<String>,totalRequired: null == totalRequired ? _self.totalRequired : totalRequired // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of RecipeCard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScoreBreakdownCopyWith<$Res> get scoreBreakdown {
  
  return $ScoreBreakdownCopyWith<$Res>(_self.scoreBreakdown, (value) {
    return _then(_self.copyWith(scoreBreakdown: value));
  });
}
}


/// Adds pattern-matching-related methods to [RecipeCard].
extension RecipeCardPatterns on RecipeCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeCard value)  $default,){
final _that = this;
switch (_that) {
case _RecipeCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeCard value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String slug, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'calories_per_serving')  double caloriesPerServing,  int servings, @JsonKey(name: 'prep_time')  int? prepTime, @JsonKey(name: 'cook_time')  int? cookTime,  String? difficulty,  String? cuisine, @JsonKey(name: 'diet_tags')  List<String> dietTags,  List<String> allergens, @JsonKey(name: 'final_score')  double finalScore, @JsonKey(name: 'score_breakdown')  ScoreBreakdown scoreBreakdown, @JsonKey(name: 'matched_ingredients')  List<String> matchedIngredients, @JsonKey(name: 'unknown_ingredients')  List<String> unknownIngredients, @JsonKey(name: 'missing_ingredients')  List<String> missingIngredients, @JsonKey(name: 'total_required')  int totalRequired)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeCard() when $default != null:
return $default(_that.id,_that.title,_that.slug,_that.imageUrl,_that.caloriesPerServing,_that.servings,_that.prepTime,_that.cookTime,_that.difficulty,_that.cuisine,_that.dietTags,_that.allergens,_that.finalScore,_that.scoreBreakdown,_that.matchedIngredients,_that.unknownIngredients,_that.missingIngredients,_that.totalRequired);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String slug, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'calories_per_serving')  double caloriesPerServing,  int servings, @JsonKey(name: 'prep_time')  int? prepTime, @JsonKey(name: 'cook_time')  int? cookTime,  String? difficulty,  String? cuisine, @JsonKey(name: 'diet_tags')  List<String> dietTags,  List<String> allergens, @JsonKey(name: 'final_score')  double finalScore, @JsonKey(name: 'score_breakdown')  ScoreBreakdown scoreBreakdown, @JsonKey(name: 'matched_ingredients')  List<String> matchedIngredients, @JsonKey(name: 'unknown_ingredients')  List<String> unknownIngredients, @JsonKey(name: 'missing_ingredients')  List<String> missingIngredients, @JsonKey(name: 'total_required')  int totalRequired)  $default,) {final _that = this;
switch (_that) {
case _RecipeCard():
return $default(_that.id,_that.title,_that.slug,_that.imageUrl,_that.caloriesPerServing,_that.servings,_that.prepTime,_that.cookTime,_that.difficulty,_that.cuisine,_that.dietTags,_that.allergens,_that.finalScore,_that.scoreBreakdown,_that.matchedIngredients,_that.unknownIngredients,_that.missingIngredients,_that.totalRequired);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String slug, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'calories_per_serving')  double caloriesPerServing,  int servings, @JsonKey(name: 'prep_time')  int? prepTime, @JsonKey(name: 'cook_time')  int? cookTime,  String? difficulty,  String? cuisine, @JsonKey(name: 'diet_tags')  List<String> dietTags,  List<String> allergens, @JsonKey(name: 'final_score')  double finalScore, @JsonKey(name: 'score_breakdown')  ScoreBreakdown scoreBreakdown, @JsonKey(name: 'matched_ingredients')  List<String> matchedIngredients, @JsonKey(name: 'unknown_ingredients')  List<String> unknownIngredients, @JsonKey(name: 'missing_ingredients')  List<String> missingIngredients, @JsonKey(name: 'total_required')  int totalRequired)?  $default,) {final _that = this;
switch (_that) {
case _RecipeCard() when $default != null:
return $default(_that.id,_that.title,_that.slug,_that.imageUrl,_that.caloriesPerServing,_that.servings,_that.prepTime,_that.cookTime,_that.difficulty,_that.cuisine,_that.dietTags,_that.allergens,_that.finalScore,_that.scoreBreakdown,_that.matchedIngredients,_that.unknownIngredients,_that.missingIngredients,_that.totalRequired);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecipeCard implements RecipeCard {
  const _RecipeCard({required this.id, required this.title, required this.slug, @JsonKey(name: 'image_url') this.imageUrl, @JsonKey(name: 'calories_per_serving') required this.caloriesPerServing, required this.servings, @JsonKey(name: 'prep_time') this.prepTime, @JsonKey(name: 'cook_time') this.cookTime, this.difficulty, this.cuisine, @JsonKey(name: 'diet_tags') final  List<String> dietTags = const [], final  List<String> allergens = const [], @JsonKey(name: 'final_score') required this.finalScore, @JsonKey(name: 'score_breakdown') required this.scoreBreakdown, @JsonKey(name: 'matched_ingredients') final  List<String> matchedIngredients = const [], @JsonKey(name: 'unknown_ingredients') final  List<String> unknownIngredients = const [], @JsonKey(name: 'missing_ingredients') final  List<String> missingIngredients = const [], @JsonKey(name: 'total_required') this.totalRequired = 0}): _dietTags = dietTags,_allergens = allergens,_matchedIngredients = matchedIngredients,_unknownIngredients = unknownIngredients,_missingIngredients = missingIngredients;
  factory _RecipeCard.fromJson(Map<String, dynamic> json) => _$RecipeCardFromJson(json);

@override final  String id;
@override final  String title;
@override final  String slug;
@override@JsonKey(name: 'image_url') final  String? imageUrl;
@override@JsonKey(name: 'calories_per_serving') final  double caloriesPerServing;
@override final  int servings;
@override@JsonKey(name: 'prep_time') final  int? prepTime;
@override@JsonKey(name: 'cook_time') final  int? cookTime;
@override final  String? difficulty;
@override final  String? cuisine;
 final  List<String> _dietTags;
@override@JsonKey(name: 'diet_tags') List<String> get dietTags {
  if (_dietTags is EqualUnmodifiableListView) return _dietTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dietTags);
}

 final  List<String> _allergens;
@override@JsonKey() List<String> get allergens {
  if (_allergens is EqualUnmodifiableListView) return _allergens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allergens);
}

@override@JsonKey(name: 'final_score') final  double finalScore;
@override@JsonKey(name: 'score_breakdown') final  ScoreBreakdown scoreBreakdown;
 final  List<String> _matchedIngredients;
@override@JsonKey(name: 'matched_ingredients') List<String> get matchedIngredients {
  if (_matchedIngredients is EqualUnmodifiableListView) return _matchedIngredients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_matchedIngredients);
}

 final  List<String> _unknownIngredients;
@override@JsonKey(name: 'unknown_ingredients') List<String> get unknownIngredients {
  if (_unknownIngredients is EqualUnmodifiableListView) return _unknownIngredients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_unknownIngredients);
}

 final  List<String> _missingIngredients;
@override@JsonKey(name: 'missing_ingredients') List<String> get missingIngredients {
  if (_missingIngredients is EqualUnmodifiableListView) return _missingIngredients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_missingIngredients);
}

@override@JsonKey(name: 'total_required') final  int totalRequired;

/// Create a copy of RecipeCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeCardCopyWith<_RecipeCard> get copyWith => __$RecipeCardCopyWithImpl<_RecipeCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipeCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeCard&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.caloriesPerServing, caloriesPerServing) || other.caloriesPerServing == caloriesPerServing)&&(identical(other.servings, servings) || other.servings == servings)&&(identical(other.prepTime, prepTime) || other.prepTime == prepTime)&&(identical(other.cookTime, cookTime) || other.cookTime == cookTime)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.cuisine, cuisine) || other.cuisine == cuisine)&&const DeepCollectionEquality().equals(other._dietTags, _dietTags)&&const DeepCollectionEquality().equals(other._allergens, _allergens)&&(identical(other.finalScore, finalScore) || other.finalScore == finalScore)&&(identical(other.scoreBreakdown, scoreBreakdown) || other.scoreBreakdown == scoreBreakdown)&&const DeepCollectionEquality().equals(other._matchedIngredients, _matchedIngredients)&&const DeepCollectionEquality().equals(other._unknownIngredients, _unknownIngredients)&&const DeepCollectionEquality().equals(other._missingIngredients, _missingIngredients)&&(identical(other.totalRequired, totalRequired) || other.totalRequired == totalRequired));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,slug,imageUrl,caloriesPerServing,servings,prepTime,cookTime,difficulty,cuisine,const DeepCollectionEquality().hash(_dietTags),const DeepCollectionEquality().hash(_allergens),finalScore,scoreBreakdown,const DeepCollectionEquality().hash(_matchedIngredients),const DeepCollectionEquality().hash(_unknownIngredients),const DeepCollectionEquality().hash(_missingIngredients),totalRequired);

@override
String toString() {
  return 'RecipeCard(id: $id, title: $title, slug: $slug, imageUrl: $imageUrl, caloriesPerServing: $caloriesPerServing, servings: $servings, prepTime: $prepTime, cookTime: $cookTime, difficulty: $difficulty, cuisine: $cuisine, dietTags: $dietTags, allergens: $allergens, finalScore: $finalScore, scoreBreakdown: $scoreBreakdown, matchedIngredients: $matchedIngredients, unknownIngredients: $unknownIngredients, missingIngredients: $missingIngredients, totalRequired: $totalRequired)';
}


}

/// @nodoc
abstract mixin class _$RecipeCardCopyWith<$Res> implements $RecipeCardCopyWith<$Res> {
  factory _$RecipeCardCopyWith(_RecipeCard value, $Res Function(_RecipeCard) _then) = __$RecipeCardCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String slug,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(name: 'calories_per_serving') double caloriesPerServing, int servings,@JsonKey(name: 'prep_time') int? prepTime,@JsonKey(name: 'cook_time') int? cookTime, String? difficulty, String? cuisine,@JsonKey(name: 'diet_tags') List<String> dietTags, List<String> allergens,@JsonKey(name: 'final_score') double finalScore,@JsonKey(name: 'score_breakdown') ScoreBreakdown scoreBreakdown,@JsonKey(name: 'matched_ingredients') List<String> matchedIngredients,@JsonKey(name: 'unknown_ingredients') List<String> unknownIngredients,@JsonKey(name: 'missing_ingredients') List<String> missingIngredients,@JsonKey(name: 'total_required') int totalRequired
});


@override $ScoreBreakdownCopyWith<$Res> get scoreBreakdown;

}
/// @nodoc
class __$RecipeCardCopyWithImpl<$Res>
    implements _$RecipeCardCopyWith<$Res> {
  __$RecipeCardCopyWithImpl(this._self, this._then);

  final _RecipeCard _self;
  final $Res Function(_RecipeCard) _then;

/// Create a copy of RecipeCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? slug = null,Object? imageUrl = freezed,Object? caloriesPerServing = null,Object? servings = null,Object? prepTime = freezed,Object? cookTime = freezed,Object? difficulty = freezed,Object? cuisine = freezed,Object? dietTags = null,Object? allergens = null,Object? finalScore = null,Object? scoreBreakdown = null,Object? matchedIngredients = null,Object? unknownIngredients = null,Object? missingIngredients = null,Object? totalRequired = null,}) {
  return _then(_RecipeCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,caloriesPerServing: null == caloriesPerServing ? _self.caloriesPerServing : caloriesPerServing // ignore: cast_nullable_to_non_nullable
as double,servings: null == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as int,prepTime: freezed == prepTime ? _self.prepTime : prepTime // ignore: cast_nullable_to_non_nullable
as int?,cookTime: freezed == cookTime ? _self.cookTime : cookTime // ignore: cast_nullable_to_non_nullable
as int?,difficulty: freezed == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as String?,cuisine: freezed == cuisine ? _self.cuisine : cuisine // ignore: cast_nullable_to_non_nullable
as String?,dietTags: null == dietTags ? _self._dietTags : dietTags // ignore: cast_nullable_to_non_nullable
as List<String>,allergens: null == allergens ? _self._allergens : allergens // ignore: cast_nullable_to_non_nullable
as List<String>,finalScore: null == finalScore ? _self.finalScore : finalScore // ignore: cast_nullable_to_non_nullable
as double,scoreBreakdown: null == scoreBreakdown ? _self.scoreBreakdown : scoreBreakdown // ignore: cast_nullable_to_non_nullable
as ScoreBreakdown,matchedIngredients: null == matchedIngredients ? _self._matchedIngredients : matchedIngredients // ignore: cast_nullable_to_non_nullable
as List<String>,unknownIngredients: null == unknownIngredients ? _self._unknownIngredients : unknownIngredients // ignore: cast_nullable_to_non_nullable
as List<String>,missingIngredients: null == missingIngredients ? _self._missingIngredients : missingIngredients // ignore: cast_nullable_to_non_nullable
as List<String>,totalRequired: null == totalRequired ? _self.totalRequired : totalRequired // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of RecipeCard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScoreBreakdownCopyWith<$Res> get scoreBreakdown {
  
  return $ScoreBreakdownCopyWith<$Res>(_self.scoreBreakdown, (value) {
    return _then(_self.copyWith(scoreBreakdown: value));
  });
}
}


/// @nodoc
mixin _$ScoreBreakdown {

 double get pantry; double get calorie; double get taste; double get time; ScoreWeights get weights;
/// Create a copy of ScoreBreakdown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScoreBreakdownCopyWith<ScoreBreakdown> get copyWith => _$ScoreBreakdownCopyWithImpl<ScoreBreakdown>(this as ScoreBreakdown, _$identity);

  /// Serializes this ScoreBreakdown to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScoreBreakdown&&(identical(other.pantry, pantry) || other.pantry == pantry)&&(identical(other.calorie, calorie) || other.calorie == calorie)&&(identical(other.taste, taste) || other.taste == taste)&&(identical(other.time, time) || other.time == time)&&(identical(other.weights, weights) || other.weights == weights));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pantry,calorie,taste,time,weights);

@override
String toString() {
  return 'ScoreBreakdown(pantry: $pantry, calorie: $calorie, taste: $taste, time: $time, weights: $weights)';
}


}

/// @nodoc
abstract mixin class $ScoreBreakdownCopyWith<$Res>  {
  factory $ScoreBreakdownCopyWith(ScoreBreakdown value, $Res Function(ScoreBreakdown) _then) = _$ScoreBreakdownCopyWithImpl;
@useResult
$Res call({
 double pantry, double calorie, double taste, double time, ScoreWeights weights
});


$ScoreWeightsCopyWith<$Res> get weights;

}
/// @nodoc
class _$ScoreBreakdownCopyWithImpl<$Res>
    implements $ScoreBreakdownCopyWith<$Res> {
  _$ScoreBreakdownCopyWithImpl(this._self, this._then);

  final ScoreBreakdown _self;
  final $Res Function(ScoreBreakdown) _then;

/// Create a copy of ScoreBreakdown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pantry = null,Object? calorie = null,Object? taste = null,Object? time = null,Object? weights = null,}) {
  return _then(_self.copyWith(
pantry: null == pantry ? _self.pantry : pantry // ignore: cast_nullable_to_non_nullable
as double,calorie: null == calorie ? _self.calorie : calorie // ignore: cast_nullable_to_non_nullable
as double,taste: null == taste ? _self.taste : taste // ignore: cast_nullable_to_non_nullable
as double,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as double,weights: null == weights ? _self.weights : weights // ignore: cast_nullable_to_non_nullable
as ScoreWeights,
  ));
}
/// Create a copy of ScoreBreakdown
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScoreWeightsCopyWith<$Res> get weights {
  
  return $ScoreWeightsCopyWith<$Res>(_self.weights, (value) {
    return _then(_self.copyWith(weights: value));
  });
}
}


/// Adds pattern-matching-related methods to [ScoreBreakdown].
extension ScoreBreakdownPatterns on ScoreBreakdown {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScoreBreakdown value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScoreBreakdown() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScoreBreakdown value)  $default,){
final _that = this;
switch (_that) {
case _ScoreBreakdown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScoreBreakdown value)?  $default,){
final _that = this;
switch (_that) {
case _ScoreBreakdown() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double pantry,  double calorie,  double taste,  double time,  ScoreWeights weights)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScoreBreakdown() when $default != null:
return $default(_that.pantry,_that.calorie,_that.taste,_that.time,_that.weights);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double pantry,  double calorie,  double taste,  double time,  ScoreWeights weights)  $default,) {final _that = this;
switch (_that) {
case _ScoreBreakdown():
return $default(_that.pantry,_that.calorie,_that.taste,_that.time,_that.weights);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double pantry,  double calorie,  double taste,  double time,  ScoreWeights weights)?  $default,) {final _that = this;
switch (_that) {
case _ScoreBreakdown() when $default != null:
return $default(_that.pantry,_that.calorie,_that.taste,_that.time,_that.weights);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScoreBreakdown implements ScoreBreakdown {
  const _ScoreBreakdown({required this.pantry, required this.calorie, required this.taste, required this.time, required this.weights});
  factory _ScoreBreakdown.fromJson(Map<String, dynamic> json) => _$ScoreBreakdownFromJson(json);

@override final  double pantry;
@override final  double calorie;
@override final  double taste;
@override final  double time;
@override final  ScoreWeights weights;

/// Create a copy of ScoreBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScoreBreakdownCopyWith<_ScoreBreakdown> get copyWith => __$ScoreBreakdownCopyWithImpl<_ScoreBreakdown>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScoreBreakdownToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScoreBreakdown&&(identical(other.pantry, pantry) || other.pantry == pantry)&&(identical(other.calorie, calorie) || other.calorie == calorie)&&(identical(other.taste, taste) || other.taste == taste)&&(identical(other.time, time) || other.time == time)&&(identical(other.weights, weights) || other.weights == weights));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pantry,calorie,taste,time,weights);

@override
String toString() {
  return 'ScoreBreakdown(pantry: $pantry, calorie: $calorie, taste: $taste, time: $time, weights: $weights)';
}


}

/// @nodoc
abstract mixin class _$ScoreBreakdownCopyWith<$Res> implements $ScoreBreakdownCopyWith<$Res> {
  factory _$ScoreBreakdownCopyWith(_ScoreBreakdown value, $Res Function(_ScoreBreakdown) _then) = __$ScoreBreakdownCopyWithImpl;
@override @useResult
$Res call({
 double pantry, double calorie, double taste, double time, ScoreWeights weights
});


@override $ScoreWeightsCopyWith<$Res> get weights;

}
/// @nodoc
class __$ScoreBreakdownCopyWithImpl<$Res>
    implements _$ScoreBreakdownCopyWith<$Res> {
  __$ScoreBreakdownCopyWithImpl(this._self, this._then);

  final _ScoreBreakdown _self;
  final $Res Function(_ScoreBreakdown) _then;

/// Create a copy of ScoreBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pantry = null,Object? calorie = null,Object? taste = null,Object? time = null,Object? weights = null,}) {
  return _then(_ScoreBreakdown(
pantry: null == pantry ? _self.pantry : pantry // ignore: cast_nullable_to_non_nullable
as double,calorie: null == calorie ? _self.calorie : calorie // ignore: cast_nullable_to_non_nullable
as double,taste: null == taste ? _self.taste : taste // ignore: cast_nullable_to_non_nullable
as double,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as double,weights: null == weights ? _self.weights : weights // ignore: cast_nullable_to_non_nullable
as ScoreWeights,
  ));
}

/// Create a copy of ScoreBreakdown
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScoreWeightsCopyWith<$Res> get weights {
  
  return $ScoreWeightsCopyWith<$Res>(_self.weights, (value) {
    return _then(_self.copyWith(weights: value));
  });
}
}


/// @nodoc
mixin _$ScoreWeights {

 double get pantry; double get calorie; double get taste; double get time;
/// Create a copy of ScoreWeights
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScoreWeightsCopyWith<ScoreWeights> get copyWith => _$ScoreWeightsCopyWithImpl<ScoreWeights>(this as ScoreWeights, _$identity);

  /// Serializes this ScoreWeights to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScoreWeights&&(identical(other.pantry, pantry) || other.pantry == pantry)&&(identical(other.calorie, calorie) || other.calorie == calorie)&&(identical(other.taste, taste) || other.taste == taste)&&(identical(other.time, time) || other.time == time));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pantry,calorie,taste,time);

@override
String toString() {
  return 'ScoreWeights(pantry: $pantry, calorie: $calorie, taste: $taste, time: $time)';
}


}

/// @nodoc
abstract mixin class $ScoreWeightsCopyWith<$Res>  {
  factory $ScoreWeightsCopyWith(ScoreWeights value, $Res Function(ScoreWeights) _then) = _$ScoreWeightsCopyWithImpl;
@useResult
$Res call({
 double pantry, double calorie, double taste, double time
});




}
/// @nodoc
class _$ScoreWeightsCopyWithImpl<$Res>
    implements $ScoreWeightsCopyWith<$Res> {
  _$ScoreWeightsCopyWithImpl(this._self, this._then);

  final ScoreWeights _self;
  final $Res Function(ScoreWeights) _then;

/// Create a copy of ScoreWeights
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pantry = null,Object? calorie = null,Object? taste = null,Object? time = null,}) {
  return _then(_self.copyWith(
pantry: null == pantry ? _self.pantry : pantry // ignore: cast_nullable_to_non_nullable
as double,calorie: null == calorie ? _self.calorie : calorie // ignore: cast_nullable_to_non_nullable
as double,taste: null == taste ? _self.taste : taste // ignore: cast_nullable_to_non_nullable
as double,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ScoreWeights].
extension ScoreWeightsPatterns on ScoreWeights {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScoreWeights value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScoreWeights() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScoreWeights value)  $default,){
final _that = this;
switch (_that) {
case _ScoreWeights():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScoreWeights value)?  $default,){
final _that = this;
switch (_that) {
case _ScoreWeights() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double pantry,  double calorie,  double taste,  double time)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScoreWeights() when $default != null:
return $default(_that.pantry,_that.calorie,_that.taste,_that.time);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double pantry,  double calorie,  double taste,  double time)  $default,) {final _that = this;
switch (_that) {
case _ScoreWeights():
return $default(_that.pantry,_that.calorie,_that.taste,_that.time);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double pantry,  double calorie,  double taste,  double time)?  $default,) {final _that = this;
switch (_that) {
case _ScoreWeights() when $default != null:
return $default(_that.pantry,_that.calorie,_that.taste,_that.time);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScoreWeights implements ScoreWeights {
  const _ScoreWeights({required this.pantry, required this.calorie, required this.taste, required this.time});
  factory _ScoreWeights.fromJson(Map<String, dynamic> json) => _$ScoreWeightsFromJson(json);

@override final  double pantry;
@override final  double calorie;
@override final  double taste;
@override final  double time;

/// Create a copy of ScoreWeights
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScoreWeightsCopyWith<_ScoreWeights> get copyWith => __$ScoreWeightsCopyWithImpl<_ScoreWeights>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScoreWeightsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScoreWeights&&(identical(other.pantry, pantry) || other.pantry == pantry)&&(identical(other.calorie, calorie) || other.calorie == calorie)&&(identical(other.taste, taste) || other.taste == taste)&&(identical(other.time, time) || other.time == time));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pantry,calorie,taste,time);

@override
String toString() {
  return 'ScoreWeights(pantry: $pantry, calorie: $calorie, taste: $taste, time: $time)';
}


}

/// @nodoc
abstract mixin class _$ScoreWeightsCopyWith<$Res> implements $ScoreWeightsCopyWith<$Res> {
  factory _$ScoreWeightsCopyWith(_ScoreWeights value, $Res Function(_ScoreWeights) _then) = __$ScoreWeightsCopyWithImpl;
@override @useResult
$Res call({
 double pantry, double calorie, double taste, double time
});




}
/// @nodoc
class __$ScoreWeightsCopyWithImpl<$Res>
    implements _$ScoreWeightsCopyWith<$Res> {
  __$ScoreWeightsCopyWithImpl(this._self, this._then);

  final _ScoreWeights _self;
  final $Res Function(_ScoreWeights) _then;

/// Create a copy of ScoreWeights
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pantry = null,Object? calorie = null,Object? taste = null,Object? time = null,}) {
  return _then(_ScoreWeights(
pantry: null == pantry ? _self.pantry : pantry // ignore: cast_nullable_to_non_nullable
as double,calorie: null == calorie ? _self.calorie : calorie // ignore: cast_nullable_to_non_nullable
as double,taste: null == taste ? _self.taste : taste // ignore: cast_nullable_to_non_nullable
as double,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
