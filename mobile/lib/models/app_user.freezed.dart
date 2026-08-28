// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppUser {

 int get id; String get email;@JsonKey(name: 'full_name') String? get fullName;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'onboarding_completed') bool get onboardingCompleted;@JsonKey(name: 'created_at') DateTime get createdAt;/// Anket tamamlanmadan ONCE null gelir - onboarding_completed=false
/// olan kullanicida profil satiri henuz yok.
 UserProfile? get profile;@JsonKey(name: 'diet_tags') List<Etiket> get dietTags; List<Etiket> get allergens;
/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppUserCopyWith<AppUser> get copyWith => _$AppUserCopyWithImpl<AppUser>(this as AppUser, _$identity);

  /// Serializes this AppUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUser&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.onboardingCompleted, onboardingCompleted) || other.onboardingCompleted == onboardingCompleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.profile, profile) || other.profile == profile)&&const DeepCollectionEquality().equals(other.dietTags, dietTags)&&const DeepCollectionEquality().equals(other.allergens, allergens));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,fullName,isActive,onboardingCompleted,createdAt,profile,const DeepCollectionEquality().hash(dietTags),const DeepCollectionEquality().hash(allergens));

@override
String toString() {
  return 'AppUser(id: $id, email: $email, fullName: $fullName, isActive: $isActive, onboardingCompleted: $onboardingCompleted, createdAt: $createdAt, profile: $profile, dietTags: $dietTags, allergens: $allergens)';
}


}

/// @nodoc
abstract mixin class $AppUserCopyWith<$Res>  {
  factory $AppUserCopyWith(AppUser value, $Res Function(AppUser) _then) = _$AppUserCopyWithImpl;
@useResult
$Res call({
 int id, String email,@JsonKey(name: 'full_name') String? fullName,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'onboarding_completed') bool onboardingCompleted,@JsonKey(name: 'created_at') DateTime createdAt, UserProfile? profile,@JsonKey(name: 'diet_tags') List<Etiket> dietTags, List<Etiket> allergens
});


$UserProfileCopyWith<$Res>? get profile;

}
/// @nodoc
class _$AppUserCopyWithImpl<$Res>
    implements $AppUserCopyWith<$Res> {
  _$AppUserCopyWithImpl(this._self, this._then);

  final AppUser _self;
  final $Res Function(AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? email = null,Object? fullName = freezed,Object? isActive = null,Object? onboardingCompleted = null,Object? createdAt = null,Object? profile = freezed,Object? dietTags = null,Object? allergens = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,onboardingCompleted: null == onboardingCompleted ? _self.onboardingCompleted : onboardingCompleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,profile: freezed == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as UserProfile?,dietTags: null == dietTags ? _self.dietTags : dietTags // ignore: cast_nullable_to_non_nullable
as List<Etiket>,allergens: null == allergens ? _self.allergens : allergens // ignore: cast_nullable_to_non_nullable
as List<Etiket>,
  ));
}
/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserProfileCopyWith<$Res>? get profile {
    if (_self.profile == null) {
    return null;
  }

  return $UserProfileCopyWith<$Res>(_self.profile!, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppUser].
extension AppUserPatterns on AppUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppUser value)  $default,){
final _that = this;
switch (_that) {
case _AppUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppUser value)?  $default,){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String email, @JsonKey(name: 'full_name')  String? fullName, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'onboarding_completed')  bool onboardingCompleted, @JsonKey(name: 'created_at')  DateTime createdAt,  UserProfile? profile, @JsonKey(name: 'diet_tags')  List<Etiket> dietTags,  List<Etiket> allergens)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.id,_that.email,_that.fullName,_that.isActive,_that.onboardingCompleted,_that.createdAt,_that.profile,_that.dietTags,_that.allergens);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String email, @JsonKey(name: 'full_name')  String? fullName, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'onboarding_completed')  bool onboardingCompleted, @JsonKey(name: 'created_at')  DateTime createdAt,  UserProfile? profile, @JsonKey(name: 'diet_tags')  List<Etiket> dietTags,  List<Etiket> allergens)  $default,) {final _that = this;
switch (_that) {
case _AppUser():
return $default(_that.id,_that.email,_that.fullName,_that.isActive,_that.onboardingCompleted,_that.createdAt,_that.profile,_that.dietTags,_that.allergens);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String email, @JsonKey(name: 'full_name')  String? fullName, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'onboarding_completed')  bool onboardingCompleted, @JsonKey(name: 'created_at')  DateTime createdAt,  UserProfile? profile, @JsonKey(name: 'diet_tags')  List<Etiket> dietTags,  List<Etiket> allergens)?  $default,) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.id,_that.email,_that.fullName,_that.isActive,_that.onboardingCompleted,_that.createdAt,_that.profile,_that.dietTags,_that.allergens);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppUser implements AppUser {
  const _AppUser({required this.id, required this.email, @JsonKey(name: 'full_name') this.fullName, @JsonKey(name: 'is_active') required this.isActive, @JsonKey(name: 'onboarding_completed') required this.onboardingCompleted, @JsonKey(name: 'created_at') required this.createdAt, this.profile, @JsonKey(name: 'diet_tags') final  List<Etiket> dietTags = const <Etiket>[], final  List<Etiket> allergens = const <Etiket>[]}): _dietTags = dietTags,_allergens = allergens;
  factory _AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);

@override final  int id;
@override final  String email;
@override@JsonKey(name: 'full_name') final  String? fullName;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'onboarding_completed') final  bool onboardingCompleted;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
/// Anket tamamlanmadan ONCE null gelir - onboarding_completed=false
/// olan kullanicida profil satiri henuz yok.
@override final  UserProfile? profile;
 final  List<Etiket> _dietTags;
@override@JsonKey(name: 'diet_tags') List<Etiket> get dietTags {
  if (_dietTags is EqualUnmodifiableListView) return _dietTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dietTags);
}

 final  List<Etiket> _allergens;
@override@JsonKey() List<Etiket> get allergens {
  if (_allergens is EqualUnmodifiableListView) return _allergens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allergens);
}


/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppUserCopyWith<_AppUser> get copyWith => __$AppUserCopyWithImpl<_AppUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppUser&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.onboardingCompleted, onboardingCompleted) || other.onboardingCompleted == onboardingCompleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.profile, profile) || other.profile == profile)&&const DeepCollectionEquality().equals(other._dietTags, _dietTags)&&const DeepCollectionEquality().equals(other._allergens, _allergens));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,fullName,isActive,onboardingCompleted,createdAt,profile,const DeepCollectionEquality().hash(_dietTags),const DeepCollectionEquality().hash(_allergens));

@override
String toString() {
  return 'AppUser(id: $id, email: $email, fullName: $fullName, isActive: $isActive, onboardingCompleted: $onboardingCompleted, createdAt: $createdAt, profile: $profile, dietTags: $dietTags, allergens: $allergens)';
}


}

/// @nodoc
abstract mixin class _$AppUserCopyWith<$Res> implements $AppUserCopyWith<$Res> {
  factory _$AppUserCopyWith(_AppUser value, $Res Function(_AppUser) _then) = __$AppUserCopyWithImpl;
@override @useResult
$Res call({
 int id, String email,@JsonKey(name: 'full_name') String? fullName,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'onboarding_completed') bool onboardingCompleted,@JsonKey(name: 'created_at') DateTime createdAt, UserProfile? profile,@JsonKey(name: 'diet_tags') List<Etiket> dietTags, List<Etiket> allergens
});


@override $UserProfileCopyWith<$Res>? get profile;

}
/// @nodoc
class __$AppUserCopyWithImpl<$Res>
    implements _$AppUserCopyWith<$Res> {
  __$AppUserCopyWithImpl(this._self, this._then);

  final _AppUser _self;
  final $Res Function(_AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? email = null,Object? fullName = freezed,Object? isActive = null,Object? onboardingCompleted = null,Object? createdAt = null,Object? profile = freezed,Object? dietTags = null,Object? allergens = null,}) {
  return _then(_AppUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,onboardingCompleted: null == onboardingCompleted ? _self.onboardingCompleted : onboardingCompleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,profile: freezed == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as UserProfile?,dietTags: null == dietTags ? _self._dietTags : dietTags // ignore: cast_nullable_to_non_nullable
as List<Etiket>,allergens: null == allergens ? _self._allergens : allergens // ignore: cast_nullable_to_non_nullable
as List<Etiket>,
  ));
}

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserProfileCopyWith<$Res>? get profile {
    if (_self.profile == null) {
    return null;
  }

  return $UserProfileCopyWith<$Res>(_self.profile!, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}


/// @nodoc
mixin _$UserProfile {

 int get id;@JsonKey(name: 'birth_year') int? get birthYear;/// Backend'de @computed_field: dogum yilindan anlik hesaplaniyor,
/// veritabaninda saklanmiyor.
 int? get age;@JsonKey(fromJson: genderFromJson, toJson: genderToJsonNullable) Gender? get gender;@JsonKey(name: 'height_cm') double? get heightCm;@JsonKey(name: 'weight_kg') double? get weightKg;@JsonKey(name: 'activity_level', unknownEnumValue: ActivityLevel.orta) ActivityLevel get activityLevel;@JsonKey(unknownEnumValue: Goal.koruma) Goal get goal;@JsonKey(name: 'household_size') int get householdSize;/// Bazal metabolizma hizi ve gunluk toplam enerji harcamasi.
/// Backend hesapliyor (profile_service._bmr_hesapla).
 double? get bmr; double? get tdee;@JsonKey(name: 'daily_calorie_target') double get dailyCalorieTarget;@JsonKey(name: 'protein_target_g') double? get proteinTargetG;@JsonKey(name: 'carb_target_g') double? get carbTargetG;@JsonKey(name: 'fat_target_g') double? get fatTargetG;
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileCopyWith<UserProfile> get copyWith => _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.birthYear, birthYear) || other.birthYear == birthYear)&&(identical(other.age, age) || other.age == age)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.activityLevel, activityLevel) || other.activityLevel == activityLevel)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.householdSize, householdSize) || other.householdSize == householdSize)&&(identical(other.bmr, bmr) || other.bmr == bmr)&&(identical(other.tdee, tdee) || other.tdee == tdee)&&(identical(other.dailyCalorieTarget, dailyCalorieTarget) || other.dailyCalorieTarget == dailyCalorieTarget)&&(identical(other.proteinTargetG, proteinTargetG) || other.proteinTargetG == proteinTargetG)&&(identical(other.carbTargetG, carbTargetG) || other.carbTargetG == carbTargetG)&&(identical(other.fatTargetG, fatTargetG) || other.fatTargetG == fatTargetG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,birthYear,age,gender,heightCm,weightKg,activityLevel,goal,householdSize,bmr,tdee,dailyCalorieTarget,proteinTargetG,carbTargetG,fatTargetG);

@override
String toString() {
  return 'UserProfile(id: $id, birthYear: $birthYear, age: $age, gender: $gender, heightCm: $heightCm, weightKg: $weightKg, activityLevel: $activityLevel, goal: $goal, householdSize: $householdSize, bmr: $bmr, tdee: $tdee, dailyCalorieTarget: $dailyCalorieTarget, proteinTargetG: $proteinTargetG, carbTargetG: $carbTargetG, fatTargetG: $fatTargetG)';
}


}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res>  {
  factory $UserProfileCopyWith(UserProfile value, $Res Function(UserProfile) _then) = _$UserProfileCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'birth_year') int? birthYear, int? age,@JsonKey(fromJson: genderFromJson, toJson: genderToJsonNullable) Gender? gender,@JsonKey(name: 'height_cm') double? heightCm,@JsonKey(name: 'weight_kg') double? weightKg,@JsonKey(name: 'activity_level', unknownEnumValue: ActivityLevel.orta) ActivityLevel activityLevel,@JsonKey(unknownEnumValue: Goal.koruma) Goal goal,@JsonKey(name: 'household_size') int householdSize, double? bmr, double? tdee,@JsonKey(name: 'daily_calorie_target') double dailyCalorieTarget,@JsonKey(name: 'protein_target_g') double? proteinTargetG,@JsonKey(name: 'carb_target_g') double? carbTargetG,@JsonKey(name: 'fat_target_g') double? fatTargetG
});




}
/// @nodoc
class _$UserProfileCopyWithImpl<$Res>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? birthYear = freezed,Object? age = freezed,Object? gender = freezed,Object? heightCm = freezed,Object? weightKg = freezed,Object? activityLevel = null,Object? goal = null,Object? householdSize = null,Object? bmr = freezed,Object? tdee = freezed,Object? dailyCalorieTarget = null,Object? proteinTargetG = freezed,Object? carbTargetG = freezed,Object? fatTargetG = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,birthYear: freezed == birthYear ? _self.birthYear : birthYear // ignore: cast_nullable_to_non_nullable
as int?,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as Gender?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,activityLevel: null == activityLevel ? _self.activityLevel : activityLevel // ignore: cast_nullable_to_non_nullable
as ActivityLevel,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as Goal,householdSize: null == householdSize ? _self.householdSize : householdSize // ignore: cast_nullable_to_non_nullable
as int,bmr: freezed == bmr ? _self.bmr : bmr // ignore: cast_nullable_to_non_nullable
as double?,tdee: freezed == tdee ? _self.tdee : tdee // ignore: cast_nullable_to_non_nullable
as double?,dailyCalorieTarget: null == dailyCalorieTarget ? _self.dailyCalorieTarget : dailyCalorieTarget // ignore: cast_nullable_to_non_nullable
as double,proteinTargetG: freezed == proteinTargetG ? _self.proteinTargetG : proteinTargetG // ignore: cast_nullable_to_non_nullable
as double?,carbTargetG: freezed == carbTargetG ? _self.carbTargetG : carbTargetG // ignore: cast_nullable_to_non_nullable
as double?,fatTargetG: freezed == fatTargetG ? _self.fatTargetG : fatTargetG // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfile].
extension UserProfilePatterns on UserProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfile value)  $default,){
final _that = this;
switch (_that) {
case _UserProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfile value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'birth_year')  int? birthYear,  int? age, @JsonKey(fromJson: genderFromJson, toJson: genderToJsonNullable)  Gender? gender, @JsonKey(name: 'height_cm')  double? heightCm, @JsonKey(name: 'weight_kg')  double? weightKg, @JsonKey(name: 'activity_level', unknownEnumValue: ActivityLevel.orta)  ActivityLevel activityLevel, @JsonKey(unknownEnumValue: Goal.koruma)  Goal goal, @JsonKey(name: 'household_size')  int householdSize,  double? bmr,  double? tdee, @JsonKey(name: 'daily_calorie_target')  double dailyCalorieTarget, @JsonKey(name: 'protein_target_g')  double? proteinTargetG, @JsonKey(name: 'carb_target_g')  double? carbTargetG, @JsonKey(name: 'fat_target_g')  double? fatTargetG)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.birthYear,_that.age,_that.gender,_that.heightCm,_that.weightKg,_that.activityLevel,_that.goal,_that.householdSize,_that.bmr,_that.tdee,_that.dailyCalorieTarget,_that.proteinTargetG,_that.carbTargetG,_that.fatTargetG);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'birth_year')  int? birthYear,  int? age, @JsonKey(fromJson: genderFromJson, toJson: genderToJsonNullable)  Gender? gender, @JsonKey(name: 'height_cm')  double? heightCm, @JsonKey(name: 'weight_kg')  double? weightKg, @JsonKey(name: 'activity_level', unknownEnumValue: ActivityLevel.orta)  ActivityLevel activityLevel, @JsonKey(unknownEnumValue: Goal.koruma)  Goal goal, @JsonKey(name: 'household_size')  int householdSize,  double? bmr,  double? tdee, @JsonKey(name: 'daily_calorie_target')  double dailyCalorieTarget, @JsonKey(name: 'protein_target_g')  double? proteinTargetG, @JsonKey(name: 'carb_target_g')  double? carbTargetG, @JsonKey(name: 'fat_target_g')  double? fatTargetG)  $default,) {final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that.id,_that.birthYear,_that.age,_that.gender,_that.heightCm,_that.weightKg,_that.activityLevel,_that.goal,_that.householdSize,_that.bmr,_that.tdee,_that.dailyCalorieTarget,_that.proteinTargetG,_that.carbTargetG,_that.fatTargetG);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'birth_year')  int? birthYear,  int? age, @JsonKey(fromJson: genderFromJson, toJson: genderToJsonNullable)  Gender? gender, @JsonKey(name: 'height_cm')  double? heightCm, @JsonKey(name: 'weight_kg')  double? weightKg, @JsonKey(name: 'activity_level', unknownEnumValue: ActivityLevel.orta)  ActivityLevel activityLevel, @JsonKey(unknownEnumValue: Goal.koruma)  Goal goal, @JsonKey(name: 'household_size')  int householdSize,  double? bmr,  double? tdee, @JsonKey(name: 'daily_calorie_target')  double dailyCalorieTarget, @JsonKey(name: 'protein_target_g')  double? proteinTargetG, @JsonKey(name: 'carb_target_g')  double? carbTargetG, @JsonKey(name: 'fat_target_g')  double? fatTargetG)?  $default,) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.birthYear,_that.age,_that.gender,_that.heightCm,_that.weightKg,_that.activityLevel,_that.goal,_that.householdSize,_that.bmr,_that.tdee,_that.dailyCalorieTarget,_that.proteinTargetG,_that.carbTargetG,_that.fatTargetG);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserProfile extends UserProfile {
  const _UserProfile({required this.id, @JsonKey(name: 'birth_year') this.birthYear, this.age, @JsonKey(fromJson: genderFromJson, toJson: genderToJsonNullable) this.gender, @JsonKey(name: 'height_cm') this.heightCm, @JsonKey(name: 'weight_kg') this.weightKg, @JsonKey(name: 'activity_level', unknownEnumValue: ActivityLevel.orta) this.activityLevel = ActivityLevel.orta, @JsonKey(unknownEnumValue: Goal.koruma) this.goal = Goal.koruma, @JsonKey(name: 'household_size') this.householdSize = 1, this.bmr, this.tdee, @JsonKey(name: 'daily_calorie_target') required this.dailyCalorieTarget, @JsonKey(name: 'protein_target_g') this.proteinTargetG, @JsonKey(name: 'carb_target_g') this.carbTargetG, @JsonKey(name: 'fat_target_g') this.fatTargetG}): super._();
  factory _UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

@override final  int id;
@override@JsonKey(name: 'birth_year') final  int? birthYear;
/// Backend'de @computed_field: dogum yilindan anlik hesaplaniyor,
/// veritabaninda saklanmiyor.
@override final  int? age;
@override@JsonKey(fromJson: genderFromJson, toJson: genderToJsonNullable) final  Gender? gender;
@override@JsonKey(name: 'height_cm') final  double? heightCm;
@override@JsonKey(name: 'weight_kg') final  double? weightKg;
@override@JsonKey(name: 'activity_level', unknownEnumValue: ActivityLevel.orta) final  ActivityLevel activityLevel;
@override@JsonKey(unknownEnumValue: Goal.koruma) final  Goal goal;
@override@JsonKey(name: 'household_size') final  int householdSize;
/// Bazal metabolizma hizi ve gunluk toplam enerji harcamasi.
/// Backend hesapliyor (profile_service._bmr_hesapla).
@override final  double? bmr;
@override final  double? tdee;
@override@JsonKey(name: 'daily_calorie_target') final  double dailyCalorieTarget;
@override@JsonKey(name: 'protein_target_g') final  double? proteinTargetG;
@override@JsonKey(name: 'carb_target_g') final  double? carbTargetG;
@override@JsonKey(name: 'fat_target_g') final  double? fatTargetG;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileCopyWith<_UserProfile> get copyWith => __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.birthYear, birthYear) || other.birthYear == birthYear)&&(identical(other.age, age) || other.age == age)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.activityLevel, activityLevel) || other.activityLevel == activityLevel)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.householdSize, householdSize) || other.householdSize == householdSize)&&(identical(other.bmr, bmr) || other.bmr == bmr)&&(identical(other.tdee, tdee) || other.tdee == tdee)&&(identical(other.dailyCalorieTarget, dailyCalorieTarget) || other.dailyCalorieTarget == dailyCalorieTarget)&&(identical(other.proteinTargetG, proteinTargetG) || other.proteinTargetG == proteinTargetG)&&(identical(other.carbTargetG, carbTargetG) || other.carbTargetG == carbTargetG)&&(identical(other.fatTargetG, fatTargetG) || other.fatTargetG == fatTargetG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,birthYear,age,gender,heightCm,weightKg,activityLevel,goal,householdSize,bmr,tdee,dailyCalorieTarget,proteinTargetG,carbTargetG,fatTargetG);

@override
String toString() {
  return 'UserProfile(id: $id, birthYear: $birthYear, age: $age, gender: $gender, heightCm: $heightCm, weightKg: $weightKg, activityLevel: $activityLevel, goal: $goal, householdSize: $householdSize, bmr: $bmr, tdee: $tdee, dailyCalorieTarget: $dailyCalorieTarget, proteinTargetG: $proteinTargetG, carbTargetG: $carbTargetG, fatTargetG: $fatTargetG)';
}


}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res> implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(_UserProfile value, $Res Function(_UserProfile) _then) = __$UserProfileCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'birth_year') int? birthYear, int? age,@JsonKey(fromJson: genderFromJson, toJson: genderToJsonNullable) Gender? gender,@JsonKey(name: 'height_cm') double? heightCm,@JsonKey(name: 'weight_kg') double? weightKg,@JsonKey(name: 'activity_level', unknownEnumValue: ActivityLevel.orta) ActivityLevel activityLevel,@JsonKey(unknownEnumValue: Goal.koruma) Goal goal,@JsonKey(name: 'household_size') int householdSize, double? bmr, double? tdee,@JsonKey(name: 'daily_calorie_target') double dailyCalorieTarget,@JsonKey(name: 'protein_target_g') double? proteinTargetG,@JsonKey(name: 'carb_target_g') double? carbTargetG,@JsonKey(name: 'fat_target_g') double? fatTargetG
});




}
/// @nodoc
class __$UserProfileCopyWithImpl<$Res>
    implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? birthYear = freezed,Object? age = freezed,Object? gender = freezed,Object? heightCm = freezed,Object? weightKg = freezed,Object? activityLevel = null,Object? goal = null,Object? householdSize = null,Object? bmr = freezed,Object? tdee = freezed,Object? dailyCalorieTarget = null,Object? proteinTargetG = freezed,Object? carbTargetG = freezed,Object? fatTargetG = freezed,}) {
  return _then(_UserProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,birthYear: freezed == birthYear ? _self.birthYear : birthYear // ignore: cast_nullable_to_non_nullable
as int?,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as Gender?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,activityLevel: null == activityLevel ? _self.activityLevel : activityLevel // ignore: cast_nullable_to_non_nullable
as ActivityLevel,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as Goal,householdSize: null == householdSize ? _self.householdSize : householdSize // ignore: cast_nullable_to_non_nullable
as int,bmr: freezed == bmr ? _self.bmr : bmr // ignore: cast_nullable_to_non_nullable
as double?,tdee: freezed == tdee ? _self.tdee : tdee // ignore: cast_nullable_to_non_nullable
as double?,dailyCalorieTarget: null == dailyCalorieTarget ? _self.dailyCalorieTarget : dailyCalorieTarget // ignore: cast_nullable_to_non_nullable
as double,proteinTargetG: freezed == proteinTargetG ? _self.proteinTargetG : proteinTargetG // ignore: cast_nullable_to_non_nullable
as double?,carbTargetG: freezed == carbTargetG ? _self.carbTargetG : carbTargetG // ignore: cast_nullable_to_non_nullable
as double?,fatTargetG: freezed == fatTargetG ? _self.fatTargetG : fatTargetG // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$Etiket {

 int get id; String get code;@JsonKey(name: 'display_name') String get displayName;
/// Create a copy of Etiket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EtiketCopyWith<Etiket> get copyWith => _$EtiketCopyWithImpl<Etiket>(this as Etiket, _$identity);

  /// Serializes this Etiket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Etiket&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,displayName);

@override
String toString() {
  return 'Etiket(id: $id, code: $code, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class $EtiketCopyWith<$Res>  {
  factory $EtiketCopyWith(Etiket value, $Res Function(Etiket) _then) = _$EtiketCopyWithImpl;
@useResult
$Res call({
 int id, String code,@JsonKey(name: 'display_name') String displayName
});




}
/// @nodoc
class _$EtiketCopyWithImpl<$Res>
    implements $EtiketCopyWith<$Res> {
  _$EtiketCopyWithImpl(this._self, this._then);

  final Etiket _self;
  final $Res Function(Etiket) _then;

/// Create a copy of Etiket
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


/// Adds pattern-matching-related methods to [Etiket].
extension EtiketPatterns on Etiket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Etiket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Etiket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Etiket value)  $default,){
final _that = this;
switch (_that) {
case _Etiket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Etiket value)?  $default,){
final _that = this;
switch (_that) {
case _Etiket() when $default != null:
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
case _Etiket() when $default != null:
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
case _Etiket():
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
case _Etiket() when $default != null:
return $default(_that.id,_that.code,_that.displayName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Etiket implements Etiket {
  const _Etiket({required this.id, required this.code, @JsonKey(name: 'display_name') required this.displayName});
  factory _Etiket.fromJson(Map<String, dynamic> json) => _$EtiketFromJson(json);

@override final  int id;
@override final  String code;
@override@JsonKey(name: 'display_name') final  String displayName;

/// Create a copy of Etiket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EtiketCopyWith<_Etiket> get copyWith => __$EtiketCopyWithImpl<_Etiket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EtiketToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Etiket&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,displayName);

@override
String toString() {
  return 'Etiket(id: $id, code: $code, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class _$EtiketCopyWith<$Res> implements $EtiketCopyWith<$Res> {
  factory _$EtiketCopyWith(_Etiket value, $Res Function(_Etiket) _then) = __$EtiketCopyWithImpl;
@override @useResult
$Res call({
 int id, String code,@JsonKey(name: 'display_name') String displayName
});




}
/// @nodoc
class __$EtiketCopyWithImpl<$Res>
    implements _$EtiketCopyWith<$Res> {
  __$EtiketCopyWithImpl(this._self, this._then);

  final _Etiket _self;
  final $Res Function(_Etiket) _then;

/// Create a copy of Etiket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? displayName = null,}) {
  return _then(_Etiket(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
