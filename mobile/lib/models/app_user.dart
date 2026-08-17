import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

/// GET /auth/me yanitinin mobil karsiligi.
///
/// NEDEN SADECE TEMEL ALANLAR: backend UserRead ayrica profile/diet_tags/
/// allergens de donuyor (app/schemas/user.py). Onlari modellemek profil
/// ekrani gorevinin kapsami; burada API ISTEMCISININ calistigini
/// KANITLAMAK icin yeterli alanlar var.
@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required int id,
    required String email,
    @JsonKey(name: 'full_name') String? fullName,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'onboarding_completed') required bool onboardingCompleted,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
}