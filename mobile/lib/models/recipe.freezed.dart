// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Recipe {

@JsonKey(name: '_id') String get id; String get title; String get slug; String? get description;@JsonKey(name: 'image_url') String? get imageUrl; List<RecipeIngredient> get ingredients; List<String> get steps; int get servings;@JsonKey(name: 'prep_time') int get prepTime;@JsonKey(name: 'cook_time') int get cookTime; String get difficulty;@JsonKey(name: 'calories_per_serving') double get caloriesPerServing; RecipeMacros get macros;@JsonKey(name: 'diet_tags') List<String> get dietTags; List<String> get allergens; String get cuisine; String? get source;@JsonKey(name: 'source_url') String? get sourceUrl;@JsonKey(name: 'is_active') bool get isActive;
/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeCopyWith<Recipe> get copyWith => _$RecipeCopyWithImpl<Recipe>(this as Recipe, _$identity);

  /// Serializes this Recipe to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Recipe&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.description, description) || other.description == description)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&const DeepCollectionEquality().equals(other.ingredients, ingredients)&&const DeepCollectionEquality().equals(other.steps, steps)&&(identical(other.servings, servings) || other.servings == servings)&&(identical(other.prepTime, prepTime) || other.prepTime == prepTime)&&(identical(other.cookTime, cookTime) || other.cookTime == cookTime)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.caloriesPerServing, caloriesPerServing) || other.caloriesPerServing == caloriesPerServing)&&(identical(other.macros, macros) || other.macros == macros)&&const DeepCollectionEquality().equals(other.dietTags, dietTags)&&const DeepCollectionEquality().equals(other.allergens, allergens)&&(identical(other.cuisine, cuisine) || other.cuisine == cuisine)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,slug,description,imageUrl,const DeepCollectionEquality().hash(ingredients),const DeepCollectionEquality().hash(steps),servings,prepTime,cookTime,difficulty,caloriesPerServing,macros,const DeepCollectionEquality().hash(dietTags),const DeepCollectionEquality().hash(allergens),cuisine,source,sourceUrl,isActive]);

@override
String toString() {
  return 'Recipe(id: $id, title: $title, slug: $slug, description: $description, imageUrl: $imageUrl, ingredients: $ingredients, steps: $steps, servings: $servings, prepTime: $prepTime, cookTime: $cookTime, difficulty: $difficulty, caloriesPerServing: $caloriesPerServing, macros: $macros, dietTags: $dietTags, allergens: $allergens, cuisine: $cuisine, source: $source, sourceUrl: $sourceUrl, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $RecipeCopyWith<$Res>  {
  factory $RecipeCopyWith(Recipe value, $Res Function(Recipe) _then) = _$RecipeCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '_id') String id, String title, String slug, String? description,@JsonKey(name: 'image_url') String? imageUrl, List<RecipeIngredient> ingredients, List<String> steps, int servings,@JsonKey(name: 'prep_time') int prepTime,@JsonKey(name: 'cook_time') int cookTime, String difficulty,@JsonKey(name: 'calories_per_serving') double caloriesPerServing, RecipeMacros macros,@JsonKey(name: 'diet_tags') List<String> dietTags, List<String> allergens, String cuisine, String? source,@JsonKey(name: 'source_url') String? sourceUrl,@JsonKey(name: 'is_active') bool isActive
});


$RecipeMacrosCopyWith<$Res> get macros;

}
/// @nodoc
class _$RecipeCopyWithImpl<$Res>
    implements $RecipeCopyWith<$Res> {
  _$RecipeCopyWithImpl(this._self, this._then);

  final Recipe _self;
  final $Res Function(Recipe) _then;

/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? slug = null,Object? description = freezed,Object? imageUrl = freezed,Object? ingredients = null,Object? steps = null,Object? servings = null,Object? prepTime = null,Object? cookTime = null,Object? difficulty = null,Object? caloriesPerServing = null,Object? macros = null,Object? dietTags = null,Object? allergens = null,Object? cuisine = null,Object? source = freezed,Object? sourceUrl = freezed,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,ingredients: null == ingredients ? _self.ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<RecipeIngredient>,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<String>,servings: null == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as int,prepTime: null == prepTime ? _self.prepTime : prepTime // ignore: cast_nullable_to_non_nullable
as int,cookTime: null == cookTime ? _self.cookTime : cookTime // ignore: cast_nullable_to_non_nullable
as int,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as String,caloriesPerServing: null == caloriesPerServing ? _self.caloriesPerServing : caloriesPerServing // ignore: cast_nullable_to_non_nullable
as double,macros: null == macros ? _self.macros : macros // ignore: cast_nullable_to_non_nullable
as RecipeMacros,dietTags: null == dietTags ? _self.dietTags : dietTags // ignore: cast_nullable_to_non_nullable
as List<String>,allergens: null == allergens ? _self.allergens : allergens // ignore: cast_nullable_to_non_nullable
as List<String>,cuisine: null == cuisine ? _self.cuisine : cuisine // ignore: cast_nullable_to_non_nullable
as String,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecipeMacrosCopyWith<$Res> get macros {
  
  return $RecipeMacrosCopyWith<$Res>(_self.macros, (value) {
    return _then(_self.copyWith(macros: value));
  });
}
}


/// Adds pattern-matching-related methods to [Recipe].
extension RecipePatterns on Recipe {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Recipe value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Recipe() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Recipe value)  $default,){
final _that = this;
switch (_that) {
case _Recipe():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Recipe value)?  $default,){
final _that = this;
switch (_that) {
case _Recipe() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String title,  String slug,  String? description, @JsonKey(name: 'image_url')  String? imageUrl,  List<RecipeIngredient> ingredients,  List<String> steps,  int servings, @JsonKey(name: 'prep_time')  int prepTime, @JsonKey(name: 'cook_time')  int cookTime,  String difficulty, @JsonKey(name: 'calories_per_serving')  double caloriesPerServing,  RecipeMacros macros, @JsonKey(name: 'diet_tags')  List<String> dietTags,  List<String> allergens,  String cuisine,  String? source, @JsonKey(name: 'source_url')  String? sourceUrl, @JsonKey(name: 'is_active')  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Recipe() when $default != null:
return $default(_that.id,_that.title,_that.slug,_that.description,_that.imageUrl,_that.ingredients,_that.steps,_that.servings,_that.prepTime,_that.cookTime,_that.difficulty,_that.caloriesPerServing,_that.macros,_that.dietTags,_that.allergens,_that.cuisine,_that.source,_that.sourceUrl,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String title,  String slug,  String? description, @JsonKey(name: 'image_url')  String? imageUrl,  List<RecipeIngredient> ingredients,  List<String> steps,  int servings, @JsonKey(name: 'prep_time')  int prepTime, @JsonKey(name: 'cook_time')  int cookTime,  String difficulty, @JsonKey(name: 'calories_per_serving')  double caloriesPerServing,  RecipeMacros macros, @JsonKey(name: 'diet_tags')  List<String> dietTags,  List<String> allergens,  String cuisine,  String? source, @JsonKey(name: 'source_url')  String? sourceUrl, @JsonKey(name: 'is_active')  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _Recipe():
return $default(_that.id,_that.title,_that.slug,_that.description,_that.imageUrl,_that.ingredients,_that.steps,_that.servings,_that.prepTime,_that.cookTime,_that.difficulty,_that.caloriesPerServing,_that.macros,_that.dietTags,_that.allergens,_that.cuisine,_that.source,_that.sourceUrl,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '_id')  String id,  String title,  String slug,  String? description, @JsonKey(name: 'image_url')  String? imageUrl,  List<RecipeIngredient> ingredients,  List<String> steps,  int servings, @JsonKey(name: 'prep_time')  int prepTime, @JsonKey(name: 'cook_time')  int cookTime,  String difficulty, @JsonKey(name: 'calories_per_serving')  double caloriesPerServing,  RecipeMacros macros, @JsonKey(name: 'diet_tags')  List<String> dietTags,  List<String> allergens,  String cuisine,  String? source, @JsonKey(name: 'source_url')  String? sourceUrl, @JsonKey(name: 'is_active')  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _Recipe() when $default != null:
return $default(_that.id,_that.title,_that.slug,_that.description,_that.imageUrl,_that.ingredients,_that.steps,_that.servings,_that.prepTime,_that.cookTime,_that.difficulty,_that.caloriesPerServing,_that.macros,_that.dietTags,_that.allergens,_that.cuisine,_that.source,_that.sourceUrl,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Recipe implements Recipe {
  const _Recipe({@JsonKey(name: '_id') required this.id, required this.title, required this.slug, this.description, @JsonKey(name: 'image_url') this.imageUrl, required final  List<RecipeIngredient> ingredients, required final  List<String> steps, required this.servings, @JsonKey(name: 'prep_time') this.prepTime = 0, @JsonKey(name: 'cook_time') this.cookTime = 0, this.difficulty = 'orta', @JsonKey(name: 'calories_per_serving') required this.caloriesPerServing, required this.macros, @JsonKey(name: 'diet_tags') final  List<String> dietTags = const [], final  List<String> allergens = const [], this.cuisine = 'turk', this.source, @JsonKey(name: 'source_url') this.sourceUrl, @JsonKey(name: 'is_active') this.isActive = true}): _ingredients = ingredients,_steps = steps,_dietTags = dietTags,_allergens = allergens;
  factory _Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);

@override@JsonKey(name: '_id') final  String id;
@override final  String title;
@override final  String slug;
@override final  String? description;
@override@JsonKey(name: 'image_url') final  String? imageUrl;
 final  List<RecipeIngredient> _ingredients;
@override List<RecipeIngredient> get ingredients {
  if (_ingredients is EqualUnmodifiableListView) return _ingredients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ingredients);
}

 final  List<String> _steps;
@override List<String> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

@override final  int servings;
@override@JsonKey(name: 'prep_time') final  int prepTime;
@override@JsonKey(name: 'cook_time') final  int cookTime;
@override@JsonKey() final  String difficulty;
@override@JsonKey(name: 'calories_per_serving') final  double caloriesPerServing;
@override final  RecipeMacros macros;
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

@override@JsonKey() final  String cuisine;
@override final  String? source;
@override@JsonKey(name: 'source_url') final  String? sourceUrl;
@override@JsonKey(name: 'is_active') final  bool isActive;

/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeCopyWith<_Recipe> get copyWith => __$RecipeCopyWithImpl<_Recipe>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Recipe&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.description, description) || other.description == description)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&const DeepCollectionEquality().equals(other._ingredients, _ingredients)&&const DeepCollectionEquality().equals(other._steps, _steps)&&(identical(other.servings, servings) || other.servings == servings)&&(identical(other.prepTime, prepTime) || other.prepTime == prepTime)&&(identical(other.cookTime, cookTime) || other.cookTime == cookTime)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.caloriesPerServing, caloriesPerServing) || other.caloriesPerServing == caloriesPerServing)&&(identical(other.macros, macros) || other.macros == macros)&&const DeepCollectionEquality().equals(other._dietTags, _dietTags)&&const DeepCollectionEquality().equals(other._allergens, _allergens)&&(identical(other.cuisine, cuisine) || other.cuisine == cuisine)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,slug,description,imageUrl,const DeepCollectionEquality().hash(_ingredients),const DeepCollectionEquality().hash(_steps),servings,prepTime,cookTime,difficulty,caloriesPerServing,macros,const DeepCollectionEquality().hash(_dietTags),const DeepCollectionEquality().hash(_allergens),cuisine,source,sourceUrl,isActive]);

@override
String toString() {
  return 'Recipe(id: $id, title: $title, slug: $slug, description: $description, imageUrl: $imageUrl, ingredients: $ingredients, steps: $steps, servings: $servings, prepTime: $prepTime, cookTime: $cookTime, difficulty: $difficulty, caloriesPerServing: $caloriesPerServing, macros: $macros, dietTags: $dietTags, allergens: $allergens, cuisine: $cuisine, source: $source, sourceUrl: $sourceUrl, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$RecipeCopyWith<$Res> implements $RecipeCopyWith<$Res> {
  factory _$RecipeCopyWith(_Recipe value, $Res Function(_Recipe) _then) = __$RecipeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '_id') String id, String title, String slug, String? description,@JsonKey(name: 'image_url') String? imageUrl, List<RecipeIngredient> ingredients, List<String> steps, int servings,@JsonKey(name: 'prep_time') int prepTime,@JsonKey(name: 'cook_time') int cookTime, String difficulty,@JsonKey(name: 'calories_per_serving') double caloriesPerServing, RecipeMacros macros,@JsonKey(name: 'diet_tags') List<String> dietTags, List<String> allergens, String cuisine, String? source,@JsonKey(name: 'source_url') String? sourceUrl,@JsonKey(name: 'is_active') bool isActive
});


@override $RecipeMacrosCopyWith<$Res> get macros;

}
/// @nodoc
class __$RecipeCopyWithImpl<$Res>
    implements _$RecipeCopyWith<$Res> {
  __$RecipeCopyWithImpl(this._self, this._then);

  final _Recipe _self;
  final $Res Function(_Recipe) _then;

/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? slug = null,Object? description = freezed,Object? imageUrl = freezed,Object? ingredients = null,Object? steps = null,Object? servings = null,Object? prepTime = null,Object? cookTime = null,Object? difficulty = null,Object? caloriesPerServing = null,Object? macros = null,Object? dietTags = null,Object? allergens = null,Object? cuisine = null,Object? source = freezed,Object? sourceUrl = freezed,Object? isActive = null,}) {
  return _then(_Recipe(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,ingredients: null == ingredients ? _self._ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<RecipeIngredient>,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<String>,servings: null == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as int,prepTime: null == prepTime ? _self.prepTime : prepTime // ignore: cast_nullable_to_non_nullable
as int,cookTime: null == cookTime ? _self.cookTime : cookTime // ignore: cast_nullable_to_non_nullable
as int,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as String,caloriesPerServing: null == caloriesPerServing ? _self.caloriesPerServing : caloriesPerServing // ignore: cast_nullable_to_non_nullable
as double,macros: null == macros ? _self.macros : macros // ignore: cast_nullable_to_non_nullable
as RecipeMacros,dietTags: null == dietTags ? _self._dietTags : dietTags // ignore: cast_nullable_to_non_nullable
as List<String>,allergens: null == allergens ? _self._allergens : allergens // ignore: cast_nullable_to_non_nullable
as List<String>,cuisine: null == cuisine ? _self.cuisine : cuisine // ignore: cast_nullable_to_non_nullable
as String,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecipeMacrosCopyWith<$Res> get macros {
  
  return $RecipeMacrosCopyWith<$Res>(_self.macros, (value) {
    return _then(_self.copyWith(macros: value));
  });
}
}


/// @nodoc
mixin _$RecipeIngredient {

 String get name;@JsonKey(name: 'canonical_name') String? get canonicalName; double? get quantity;@JsonKey(fromJson: _unitOrNull, toJson: _unitOrNullJson) UnitCode? get unit; bool get optional; String? get note;
/// Create a copy of RecipeIngredient
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeIngredientCopyWith<RecipeIngredient> get copyWith => _$RecipeIngredientCopyWithImpl<RecipeIngredient>(this as RecipeIngredient, _$identity);

  /// Serializes this RecipeIngredient to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeIngredient&&(identical(other.name, name) || other.name == name)&&(identical(other.canonicalName, canonicalName) || other.canonicalName == canonicalName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.optional, optional) || other.optional == optional)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,canonicalName,quantity,unit,optional,note);

@override
String toString() {
  return 'RecipeIngredient(name: $name, canonicalName: $canonicalName, quantity: $quantity, unit: $unit, optional: $optional, note: $note)';
}


}

/// @nodoc
abstract mixin class $RecipeIngredientCopyWith<$Res>  {
  factory $RecipeIngredientCopyWith(RecipeIngredient value, $Res Function(RecipeIngredient) _then) = _$RecipeIngredientCopyWithImpl;
@useResult
$Res call({
 String name,@JsonKey(name: 'canonical_name') String? canonicalName, double? quantity,@JsonKey(fromJson: _unitOrNull, toJson: _unitOrNullJson) UnitCode? unit, bool optional, String? note
});




}
/// @nodoc
class _$RecipeIngredientCopyWithImpl<$Res>
    implements $RecipeIngredientCopyWith<$Res> {
  _$RecipeIngredientCopyWithImpl(this._self, this._then);

  final RecipeIngredient _self;
  final $Res Function(RecipeIngredient) _then;

/// Create a copy of RecipeIngredient
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? canonicalName = freezed,Object? quantity = freezed,Object? unit = freezed,Object? optional = null,Object? note = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,canonicalName: freezed == canonicalName ? _self.canonicalName : canonicalName // ignore: cast_nullable_to_non_nullable
as String?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as UnitCode?,optional: null == optional ? _self.optional : optional // ignore: cast_nullable_to_non_nullable
as bool,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipeIngredient].
extension RecipeIngredientPatterns on RecipeIngredient {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeIngredient value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeIngredient() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeIngredient value)  $default,){
final _that = this;
switch (_that) {
case _RecipeIngredient():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeIngredient value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeIngredient() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'canonical_name')  String? canonicalName,  double? quantity, @JsonKey(fromJson: _unitOrNull, toJson: _unitOrNullJson)  UnitCode? unit,  bool optional,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeIngredient() when $default != null:
return $default(_that.name,_that.canonicalName,_that.quantity,_that.unit,_that.optional,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'canonical_name')  String? canonicalName,  double? quantity, @JsonKey(fromJson: _unitOrNull, toJson: _unitOrNullJson)  UnitCode? unit,  bool optional,  String? note)  $default,) {final _that = this;
switch (_that) {
case _RecipeIngredient():
return $default(_that.name,_that.canonicalName,_that.quantity,_that.unit,_that.optional,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name, @JsonKey(name: 'canonical_name')  String? canonicalName,  double? quantity, @JsonKey(fromJson: _unitOrNull, toJson: _unitOrNullJson)  UnitCode? unit,  bool optional,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _RecipeIngredient() when $default != null:
return $default(_that.name,_that.canonicalName,_that.quantity,_that.unit,_that.optional,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecipeIngredient implements RecipeIngredient {
  const _RecipeIngredient({required this.name, @JsonKey(name: 'canonical_name') this.canonicalName, this.quantity, @JsonKey(fromJson: _unitOrNull, toJson: _unitOrNullJson) this.unit, this.optional = false, this.note});
  factory _RecipeIngredient.fromJson(Map<String, dynamic> json) => _$RecipeIngredientFromJson(json);

@override final  String name;
@override@JsonKey(name: 'canonical_name') final  String? canonicalName;
@override final  double? quantity;
@override@JsonKey(fromJson: _unitOrNull, toJson: _unitOrNullJson) final  UnitCode? unit;
@override@JsonKey() final  bool optional;
@override final  String? note;

/// Create a copy of RecipeIngredient
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeIngredientCopyWith<_RecipeIngredient> get copyWith => __$RecipeIngredientCopyWithImpl<_RecipeIngredient>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipeIngredientToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeIngredient&&(identical(other.name, name) || other.name == name)&&(identical(other.canonicalName, canonicalName) || other.canonicalName == canonicalName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.optional, optional) || other.optional == optional)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,canonicalName,quantity,unit,optional,note);

@override
String toString() {
  return 'RecipeIngredient(name: $name, canonicalName: $canonicalName, quantity: $quantity, unit: $unit, optional: $optional, note: $note)';
}


}

/// @nodoc
abstract mixin class _$RecipeIngredientCopyWith<$Res> implements $RecipeIngredientCopyWith<$Res> {
  factory _$RecipeIngredientCopyWith(_RecipeIngredient value, $Res Function(_RecipeIngredient) _then) = __$RecipeIngredientCopyWithImpl;
@override @useResult
$Res call({
 String name,@JsonKey(name: 'canonical_name') String? canonicalName, double? quantity,@JsonKey(fromJson: _unitOrNull, toJson: _unitOrNullJson) UnitCode? unit, bool optional, String? note
});




}
/// @nodoc
class __$RecipeIngredientCopyWithImpl<$Res>
    implements _$RecipeIngredientCopyWith<$Res> {
  __$RecipeIngredientCopyWithImpl(this._self, this._then);

  final _RecipeIngredient _self;
  final $Res Function(_RecipeIngredient) _then;

/// Create a copy of RecipeIngredient
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? canonicalName = freezed,Object? quantity = freezed,Object? unit = freezed,Object? optional = null,Object? note = freezed,}) {
  return _then(_RecipeIngredient(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,canonicalName: freezed == canonicalName ? _self.canonicalName : canonicalName // ignore: cast_nullable_to_non_nullable
as String?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as UnitCode?,optional: null == optional ? _self.optional : optional // ignore: cast_nullable_to_non_nullable
as bool,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$RecipeMacros {

@JsonKey(name: 'protein_g') double get proteinG;@JsonKey(name: 'carb_g') double get carbG;@JsonKey(name: 'fat_g') double get fatG;@JsonKey(name: 'fiber_g') double get fiberG;
/// Create a copy of RecipeMacros
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeMacrosCopyWith<RecipeMacros> get copyWith => _$RecipeMacrosCopyWithImpl<RecipeMacros>(this as RecipeMacros, _$identity);

  /// Serializes this RecipeMacros to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeMacros&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbG, carbG) || other.carbG == carbG)&&(identical(other.fatG, fatG) || other.fatG == fatG)&&(identical(other.fiberG, fiberG) || other.fiberG == fiberG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,proteinG,carbG,fatG,fiberG);

@override
String toString() {
  return 'RecipeMacros(proteinG: $proteinG, carbG: $carbG, fatG: $fatG, fiberG: $fiberG)';
}


}

/// @nodoc
abstract mixin class $RecipeMacrosCopyWith<$Res>  {
  factory $RecipeMacrosCopyWith(RecipeMacros value, $Res Function(RecipeMacros) _then) = _$RecipeMacrosCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'protein_g') double proteinG,@JsonKey(name: 'carb_g') double carbG,@JsonKey(name: 'fat_g') double fatG,@JsonKey(name: 'fiber_g') double fiberG
});




}
/// @nodoc
class _$RecipeMacrosCopyWithImpl<$Res>
    implements $RecipeMacrosCopyWith<$Res> {
  _$RecipeMacrosCopyWithImpl(this._self, this._then);

  final RecipeMacros _self;
  final $Res Function(RecipeMacros) _then;

/// Create a copy of RecipeMacros
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


/// Adds pattern-matching-related methods to [RecipeMacros].
extension RecipeMacrosPatterns on RecipeMacros {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeMacros value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeMacros() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeMacros value)  $default,){
final _that = this;
switch (_that) {
case _RecipeMacros():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeMacros value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeMacros() when $default != null:
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
case _RecipeMacros() when $default != null:
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
case _RecipeMacros():
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
case _RecipeMacros() when $default != null:
return $default(_that.proteinG,_that.carbG,_that.fatG,_that.fiberG);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecipeMacros implements RecipeMacros {
  const _RecipeMacros({@JsonKey(name: 'protein_g') this.proteinG = 0, @JsonKey(name: 'carb_g') this.carbG = 0, @JsonKey(name: 'fat_g') this.fatG = 0, @JsonKey(name: 'fiber_g') this.fiberG = 0});
  factory _RecipeMacros.fromJson(Map<String, dynamic> json) => _$RecipeMacrosFromJson(json);

@override@JsonKey(name: 'protein_g') final  double proteinG;
@override@JsonKey(name: 'carb_g') final  double carbG;
@override@JsonKey(name: 'fat_g') final  double fatG;
@override@JsonKey(name: 'fiber_g') final  double fiberG;

/// Create a copy of RecipeMacros
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeMacrosCopyWith<_RecipeMacros> get copyWith => __$RecipeMacrosCopyWithImpl<_RecipeMacros>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipeMacrosToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeMacros&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbG, carbG) || other.carbG == carbG)&&(identical(other.fatG, fatG) || other.fatG == fatG)&&(identical(other.fiberG, fiberG) || other.fiberG == fiberG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,proteinG,carbG,fatG,fiberG);

@override
String toString() {
  return 'RecipeMacros(proteinG: $proteinG, carbG: $carbG, fatG: $fatG, fiberG: $fiberG)';
}


}

/// @nodoc
abstract mixin class _$RecipeMacrosCopyWith<$Res> implements $RecipeMacrosCopyWith<$Res> {
  factory _$RecipeMacrosCopyWith(_RecipeMacros value, $Res Function(_RecipeMacros) _then) = __$RecipeMacrosCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'protein_g') double proteinG,@JsonKey(name: 'carb_g') double carbG,@JsonKey(name: 'fat_g') double fatG,@JsonKey(name: 'fiber_g') double fiberG
});




}
/// @nodoc
class __$RecipeMacrosCopyWithImpl<$Res>
    implements _$RecipeMacrosCopyWith<$Res> {
  __$RecipeMacrosCopyWithImpl(this._self, this._then);

  final _RecipeMacros _self;
  final $Res Function(_RecipeMacros) _then;

/// Create a copy of RecipeMacros
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? proteinG = null,Object? carbG = null,Object? fatG = null,Object? fiberG = null,}) {
  return _then(_RecipeMacros(
proteinG: null == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as double,carbG: null == carbG ? _self.carbG : carbG // ignore: cast_nullable_to_non_nullable
as double,fatG: null == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as double,fiberG: null == fiberG ? _self.fiberG : fiberG // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
