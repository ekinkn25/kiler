import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/kilo_kaydi.dart';
import 'auth_provider.dart';
import 'meal_provider.dart';

/// Profil yazma ve kilo gunlugu servisi (PATCH /me/profile, /me/weight).
///
/// NEDEN authProvider'in ICINDE DEGIL: authProvider OTURUMU temsil eder -
/// kim giris yapmis, token gecerli mi. Profil duzenleme bir oturum islemi
/// degil; ayni sinifa konsaydi 'cikis yap' ile 'kilomu degistir' yan yana
/// durup ikisi de ayni AsyncValue'yu loading'e cekerdi.
class ProfilServisi {
  const ProfilServisi(this._dio);

  final Dio _dio;

  /// PATCH /me/profile - null gecilen alan GONDERILMEZ.
  ///
  /// Backend PATCH semantigi uyguluyor: gonderilmeyen alan degismez.
  /// Bu yuzden burada null 'temizle' degil 'dokunma' anlamina gelir.
  Future<UserProfile> guncelle({
    double? kiloKg,
    double? boyCm,
    int? dogumYili,
    Gender? cinsiyet,
    ActivityLevel? aktivite,
    Goal? hedef,
    int? haneBuyuklugu,
  }) async {
    // '?deger': null olan alan govdeye HIC KONMAZ. Backend gonderilmeyen
    // alani "degistirme" diye okuyor; null gonderseydik "temizle" olurdu.
    final govde = <String, dynamic>{
      'weight_kg': ?kiloKg,
      'height_cm': ?boyCm,
      'birth_year': ?dogumYili,
      if (cinsiyet != null) 'gender': genderToJson(cinsiyet),
      if (aktivite != null) 'activity_level': activityLevelToJson(aktivite),
      if (hedef != null) 'goal': goalToJson(hedef),
      'household_size': ?haneBuyuklugu,
    };

    final response =
        await _dio.patch<Map<String, dynamic>>('/me/profile', data: govde);
    return UserProfile.fromJson(response.data!);
  }

  Future<List<KiloKaydi>> kiloGecmisi({int gun = 90}) async {
    final response = await _dio.get<List<dynamic>>(
      '/me/weight',
      queryParameters: {'days': gun},
    );
    return response.data!
        .map((e) => KiloKaydi.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// [gun] verilmezse backend BUGUNU kullanir.
  Future<KiloKaydi> kiloEkle({required double kiloKg, DateTime? gun}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/me/weight',
      data: {
        'weight_kg': kiloKg,
        if (gun != null) 'logged_date': gunAnahtari(gun),
      },
    );
    return KiloKaydi.fromJson(response.data!);
  }

  Future<void> kiloSil(int id) => _dio.delete<void>('/me/weight/$id');
}

final profilServisiProvider = Provider<ProfilServisi>(
  (ref) => ProfilServisi(ref.read(dioProvider)),
);

// ==================================================================
// Kilo gecmisi (grafik ekrani)
// ==================================================================

/// Grafikte gosterilen pencere (gun). Ekrandaki aralik dugmeleri bunu yazar.
final kiloAraligiProvider = StateProvider<int>((ref) => 90);

/// autoDispose: gecmis YALNIZCA kilo ekraninda gorunuyor. Kalici olsaydi
/// kullanici ekrandan ciktiktan sonra bile bellekte durur ve baska bir
/// yerden gelen `invalidate` gereksiz bir ag istegi baslatirdi.
class KiloGecmisiNotifier extends AutoDisposeAsyncNotifier<List<KiloKaydi>> {
  @override
  Future<List<KiloKaydi>> build() {
    // watch: aralik degisince notifier kendiliginden yeniden kurulur,
    // ekranin ayrica 'yenile' cagirmasina gerek kalmaz.
    final gun = ref.watch(kiloAraligiProvider);
    return ref.read(profilServisiProvider).kiloGecmisi(gun: gun);
  }

  Future<void> yenile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(profilServisiProvider)
          .kiloGecmisi(gun: ref.read(kiloAraligiProvider)),
    );
  }

  /// Kilo ekler ve OTURUMDAKI profili de tazeler.
  ///
  /// Backend en yeni tarihe yazilan kiloyu profile de isliyor ve kalori
  /// hedefini yeniden hesapliyor. Istemci bunu bilmezse profil ekraninda
  /// eski kilo, kalori ekraninda eski hedef gorunurdu.
  Future<KiloKaydi> ekle({required double kiloKg, DateTime? gun}) async {
    final kayit =
        await ref.read(profilServisiProvider).kiloEkle(kiloKg: kiloKg, gun: gun);
    await ref.read(authProvider.notifier).profiliTazele();
    ref.invalidate(dailySummaryProvider);
    await yenile();
    return kayit;
  }

  Future<void> sil(int id) async {
    await ref.read(profilServisiProvider).kiloSil(id);
    await yenile();
  }
}

final kiloGecmisiProvider =
    AsyncNotifierProvider.autoDispose<KiloGecmisiNotifier, List<KiloKaydi>>(
  KiloGecmisiNotifier.new,
);
