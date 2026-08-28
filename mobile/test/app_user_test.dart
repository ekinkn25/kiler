// AppUser / UserProfile ayristirma testleri (Adim 2).
//
// NEDEN BU TESTLER: /auth/me uygulamanin HER ACILISINDA cagriliyor
// (auth_provider._restoreSession). Buradaki bir ayristirma hatasi
// kullaniciyi splash ekraninda kilitler - yani en pahali hata turu.
// Ozellikle null alanlar ve BILINMEYEN enum degerleri sinaniyor.
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/models/app_user.dart';
import 'package:kalori/models/enums.dart';

/// Backend'in GET /auth/me'den dondugu gercek sekil (app/schemas/user.py).
Map<String, dynamic> tamYanit() => {
  'id': 12,
  'email': 'ekin@example.com',
  'full_name': 'Ekin Karıncalı',
  'is_active': true,
  'onboarding_completed': true,
  'created_at': '2026-08-01T09:30:00Z',
  'profile': <String, dynamic>{
    'id': 5,
    'birth_year': 2001,
    'age': 25,
    'gender': 'erkek',
    'height_cm': 170.0,
    'weight_kg': 65.0,
    'activity_level': 'orta',
    'goal': 'kilo_verme',
    'household_size': 3,
    'bmr': 1650.0,
    'tdee': 2400.0,
    'daily_calorie_target': 2000.0,
    'protein_target_g': 120.0,
    'carb_target_g': 220.0,
    'fat_target_g': 65.0,
  },
  'diet_tags': [
    {'id': 1, 'code': 'vegan', 'display_name': 'Vegan'},
    {'id': 2, 'code': 'glutensiz', 'display_name': 'Glütensiz'},
  ],
  'allergens': [
    {'id': 7, 'code': 'findik', 'display_name': 'Fındık'},
  ],
};

void main() {
  group('AppUser.fromJson', () {
    test('tam yanit eksiksiz ayristirilir', () {
      final k = AppUser.fromJson(tamYanit());

      expect(k.id, 12);
      expect(k.fullName, 'Ekin Karıncalı');
      expect(k.onboardingCompleted, isTrue);
      expect(k.profile, isNotNull);
      expect(k.dietTags, hasLength(2));
      expect(k.dietTags.first.displayName, 'Vegan');
      expect(k.allergens.single.code, 'findik');
    });

    test('profil alanlari dogru esleniyor', () {
      final p = AppUser.fromJson(tamYanit()).profile!;

      expect(p.heightCm, 170.0);
      expect(p.weightKg, 65.0);
      expect(p.age, 25);
      expect(p.gender, Gender.erkek);
      expect(p.activityLevel, ActivityLevel.orta);
      expect(p.goal, Goal.kiloVerme);   // 'kilo_verme' -> kiloVerme
      expect(p.householdSize, 3);
      expect(p.dailyCalorieTarget, 2000.0);
      expect(p.proteinTargetG, 120.0);
    });

    test('anket tamamlanmamis kullanicida profile null', () {
      final json = tamYanit()
        ..['onboarding_completed'] = false
        ..['profile'] = null;

      final k = AppUser.fromJson(json);
      expect(k.profile, isNull);   // cekmece bu durumda vucut bolumunu cizmez
    });

    test('diet_tags/allergens anahtarlari HIC yoksa bos liste', () {
      final json = tamYanit()
        ..remove('diet_tags')
        ..remove('allergens');

      final k = AppUser.fromJson(json);
      expect(k.dietTags, isEmpty);
      expect(k.allergens, isEmpty);
    });
  });

  group('Dayaniklilik - bilinmeyen ve bos degerler', () {
    test('bilinmeyen activity_level varsayilana duser, COKMEZ', () {
      // Backend'e yarin yeni bir aktivite duzeyi eklenirse eski surumdeki
      // uygulama acilamamali DEGIL, calismaya devam etmeli.
      final json = tamYanit();
      (json['profile'] as Map)['activity_level'] = 'profesyonel_sporcu';

      final p = AppUser.fromJson(json).profile!;
      expect(p.activityLevel, ActivityLevel.orta);
    });

    test('bilinmeyen goal varsayilana duser', () {
      final json = tamYanit();
      (json['profile'] as Map)['goal'] = 'kas_yapma';

      expect(AppUser.fromJson(json).profile!.goal, Goal.koruma);
    });

    test('gender null veya bilinmeyense null olur', () {
      final json = tamYanit();
      (json['profile'] as Map)['gender'] = null;
      expect(AppUser.fromJson(json).profile!.gender, isNull);

      (json['profile'] as Map)['gender'] = 'diger';
      expect(AppUser.fromJson(json).profile!.gender, isNull);
    });

    test('boy ve kilo girilmemis profil ayristirilir', () {
      final json = tamYanit();
      (json['profile'] as Map)
        ..['height_cm'] = null
        ..['weight_kg'] = null
        ..['age'] = null;

      final p = AppUser.fromJson(json).profile!;
      expect(p.heightCm, isNull);
      expect(p.bmi, isNull);          // cekmecede '—' gorunecek
      expect(p.bmiEtiketi, isNull);
    });
  });

  group('BMI', () {
    UserProfile profil({double? boy, double? kilo}) => UserProfile(
      id: 1,
      heightCm: boy,
      weightKg: kilo,
      dailyCalorieTarget: 2000,
    );

    test('dogru hesaplaniyor', () {
      // 65 / (1.70 * 1.70) = 22.49
      expect(profil(boy: 170, kilo: 65).bmi, closeTo(22.49, 0.01));
    });

    test('eksik olcude null doner', () {
      expect(profil(boy: 170).bmi, isNull);
      expect(profil(kilo: 65).bmi, isNull);
      expect(profil().bmi, isNull);
    });

    test('sifir boy sifira bolme yapmaz', () {
      expect(profil(boy: 0, kilo: 65).bmi, isNull);
    });

    test('DSO esikleri sinirlarda dogru', () {
      // 200 cm uzerinden: bolen tam 4.0, esik degerleri net cikiyor.
      expect(profil(boy: 200, kilo: 70).bmiEtiketi, 'Zayıf');        // 17.5
      expect(profil(boy: 200, kilo: 74).bmiEtiketi, 'Normal');       // 18.5
      expect(profil(boy: 200, kilo: 99).bmiEtiketi, 'Normal');       // 24.75
      expect(profil(boy: 200, kilo: 100).bmiEtiketi, 'Fazla kilolu');// 25.0
      expect(profil(boy: 200, kilo: 120).bmiEtiketi, 'Obez');        // 30.0
    });
  });

  group('Gosterim etiketleri', () {
    test('enum etiketleri Turkce ve dolu', () {
      expect(Goal.kiloVerme.etiket, 'Kilo verme');
      expect(ActivityLevel.cokYuksek.etiket, 'Aşırı aktif');
      expect(Gender.kadin.etiket, 'Kadın');
    });
  });
}