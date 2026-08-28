import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

/// GET /auth/me yanitinin mobil karsiligi (backend: UserRead).
///
/// W4-T15 sonrasi genisletildi: backend zaten profile/diet_tags/allergens
/// donuyordu, mobil taraf yalnizca parse etmiyordu. Yeni UC bile
/// eklenmedi - var olan yanitin kullanilmayan kismi acildi.
@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required int id,
    required String email,
    @JsonKey(name: 'full_name') String? fullName,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'onboarding_completed') required bool onboardingCompleted,
    @JsonKey(name: 'created_at') required DateTime createdAt,

    /// Anket tamamlanmadan ONCE null gelir - onboarding_completed=false
    /// olan kullanicida profil satiri henuz yok.
    UserProfile? profile,

    @JsonKey(name: 'diet_tags') @Default(<Etiket>[]) List<Etiket> dietTags,
    @Default(<Etiket>[]) List<Etiket> allergens,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
}

/// Vucut olculeri ve hesaplanmis hedefler (backend: UserProfileRead).
@freezed
abstract class UserProfile with _$UserProfile {
  /// Bu satir freezed'de OZEL GETTER eklemenin sarti. Yazilmazsa
  /// asagidaki `bmi` getter'i derlenmez.
  const UserProfile._();

  const factory UserProfile({
    required int id,
    @JsonKey(name: 'birth_year') int? birthYear,

    /// Backend'de @computed_field: dogum yilindan anlik hesaplaniyor,
    /// veritabaninda saklanmiyor.
    int? age,

    @JsonKey(fromJson: genderFromJson, toJson: genderToJsonNullable) Gender? gender,
    @JsonKey(name: 'height_cm') double? heightCm,
    @JsonKey(name: 'weight_kg') double? weightKg,

    @JsonKey(name: 'activity_level', unknownEnumValue: ActivityLevel.orta)
    @Default(ActivityLevel.orta) ActivityLevel activityLevel,

    @JsonKey(unknownEnumValue: Goal.koruma)
    @Default(Goal.koruma) Goal goal,

    @JsonKey(name: 'household_size') @Default(1) int householdSize,

    /// Bazal metabolizma hizi ve gunluk toplam enerji harcamasi.
    /// Backend hesapliyor (profile_service._bmr_hesapla).
    double? bmr,
    double? tdee,

    @JsonKey(name: 'daily_calorie_target') required double dailyCalorieTarget,
    @JsonKey(name: 'protein_target_g') double? proteinTargetG,
    @JsonKey(name: 'carb_target_g') double? carbTargetG,
    @JsonKey(name: 'fat_target_g') double? fatTargetG,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  /// Vucut kitle indeksi.
  ///
  /// NEDEN ISTEMCIDE: boy ve kilo zaten elimizde, tek bolme islemi.
  /// Backend'e alan eklemek yeni bir migration ve yeni bir sozlesme
  /// demek olurdu - karsiliginda hicbir sey kazanmadan.
  double? get bmi {
    final boy = heightCm;
    final kilo = weightKg;
    if (boy == null || kilo == null || boy <= 0) return null;
    final metre = boy / 100;
    return kilo / (metre * metre);
  }

  /// Dunya Saglik Orgutu esikleri. Bilgilendirme amacli; tibbi tavsiye degil.
  String? get bmiEtiketi {
    final d = bmi;
    if (d == null) return null;
    if (d < 18.5) return 'Zayıf';
    if (d < 25) return 'Normal';
    if (d < 30) return 'Fazla kilolu';
    return 'Obez';
  }
}

/// diet_tags ve allergens ayni sekle sahip: {id, code, display_name}.
/// Tek model ikisine de yetiyor (backend: DietTagRead / AllergenRead).
@freezed
abstract class Etiket with _$Etiket {
  const factory Etiket({
    required int id,
    required String code,
    @JsonKey(name: 'display_name') required String displayName,
  }) = _Etiket;

  factory Etiket.fromJson(Map<String, dynamic> json) => _$EtiketFromJson(json);
}