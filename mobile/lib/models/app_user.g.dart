// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUser _$AppUserFromJson(Map<String, dynamic> json) => _AppUser(
  id: (json['id'] as num).toInt(),
  email: json['email'] as String,
  fullName: json['full_name'] as String?,
  isActive: json['is_active'] as bool,
  onboardingCompleted: json['onboarding_completed'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  profile: json['profile'] == null
      ? null
      : UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
  dietTags:
      (json['diet_tags'] as List<dynamic>?)
          ?.map((e) => Etiket.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Etiket>[],
  allergens:
      (json['allergens'] as List<dynamic>?)
          ?.map((e) => Etiket.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Etiket>[],
);

Map<String, dynamic> _$AppUserToJson(_AppUser instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'full_name': instance.fullName,
  'is_active': instance.isActive,
  'onboarding_completed': instance.onboardingCompleted,
  'created_at': instance.createdAt.toIso8601String(),
  'profile': instance.profile,
  'diet_tags': instance.dietTags,
  'allergens': instance.allergens,
};

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  id: (json['id'] as num).toInt(),
  birthYear: (json['birth_year'] as num?)?.toInt(),
  age: (json['age'] as num?)?.toInt(),
  gender: genderFromJson(json['gender']),
  heightCm: (json['height_cm'] as num?)?.toDouble(),
  weightKg: (json['weight_kg'] as num?)?.toDouble(),
  activityLevel:
      $enumDecodeNullable(
        _$ActivityLevelEnumMap,
        json['activity_level'],
        unknownValue: ActivityLevel.orta,
      ) ??
      ActivityLevel.orta,
  goal:
      $enumDecodeNullable(
        _$GoalEnumMap,
        json['goal'],
        unknownValue: Goal.koruma,
      ) ??
      Goal.koruma,
  householdSize: (json['household_size'] as num?)?.toInt() ?? 1,
  bmr: (json['bmr'] as num?)?.toDouble(),
  tdee: (json['tdee'] as num?)?.toDouble(),
  dailyCalorieTarget: (json['daily_calorie_target'] as num).toDouble(),
  proteinTargetG: (json['protein_target_g'] as num?)?.toDouble(),
  carbTargetG: (json['carb_target_g'] as num?)?.toDouble(),
  fatTargetG: (json['fat_target_g'] as num?)?.toDouble(),
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'birth_year': instance.birthYear,
      'age': instance.age,
      'gender': genderToJsonNullable(instance.gender),
      'height_cm': instance.heightCm,
      'weight_kg': instance.weightKg,
      'activity_level': _$ActivityLevelEnumMap[instance.activityLevel]!,
      'goal': _$GoalEnumMap[instance.goal]!,
      'household_size': instance.householdSize,
      'bmr': instance.bmr,
      'tdee': instance.tdee,
      'daily_calorie_target': instance.dailyCalorieTarget,
      'protein_target_g': instance.proteinTargetG,
      'carb_target_g': instance.carbTargetG,
      'fat_target_g': instance.fatTargetG,
    };

const _$ActivityLevelEnumMap = {
  ActivityLevel.sedanter: 'sedanter',
  ActivityLevel.hafif: 'hafif',
  ActivityLevel.orta: 'orta',
  ActivityLevel.yuksek: 'yuksek',
  ActivityLevel.cokYuksek: 'cok_yuksek',
};

const _$GoalEnumMap = {
  Goal.kiloVerme: 'kilo_verme',
  Goal.koruma: 'koruma',
  Goal.kiloAlma: 'kilo_alma',
};

_Etiket _$EtiketFromJson(Map<String, dynamic> json) => _Etiket(
  id: (json['id'] as num).toInt(),
  code: json['code'] as String,
  displayName: json['display_name'] as String,
);

Map<String, dynamic> _$EtiketToJson(_Etiket instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'display_name': instance.displayName,
};
