import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../core/network/dio_client.dart';
import '../models/daily_summary.dart';
import '../core/network/multipart_helper.dart';
import '../models/meal_estimate.dart';
import 'package:dio/dio.dart';

/// DateTime -> 'yyyy-MM-dd'.
///
/// intl'e gitmiyoruz: tek bicimlendirme icin paket cagirmak gereksiz.
String gunAnahtari(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-'
    '${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')}';

/// Kalori ekraninin gosterdigi GUN, 'yyyy-MM-dd' bicminde.
///
/// NEDEN DateTime DEGIL METIN: DateTime saat/dakika da tasir; iki ayri
/// 'bugun' nesnesi birbirine esit olmaz ve family saglayici her build'de
/// yeni istek atardi. Metnin deger esitligi vardir.
final selectedDateProvider =
    StateProvider<String>((ref) => gunAnahtari(DateTime.now()));

/// GET /meals/daily?date=
///
/// Backend halkayi, makrolari VE ogun gruplarini TEK istekte donuyor
/// (DailySummary). Ayri saglayicilara bolmek gereksiz istek uretirdi.
final dailySummaryProvider =
    FutureProvider.autoDispose.family<DailySummary, String>((ref, tarih) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get<Map<String, dynamic>>(
    '/meals/daily',
    // date GONDERILMEZSE backend SUNUCUNUN gununu kullaniyor. Kullanici
    // baska saat diliminde olabilir; yerel gun HER ZAMAN gonderilmeli.
    queryParameters: {'date': tarih},
  );
  return DailySummary.fromJson(response.data!);
});


/// Fotograftan ogun akisi (W3-T15).
///
/// Iki islem: tabak fotografini tahmine cevir, sonra onaylanan ogunu
/// gunluge yaz. Ekran state'i tutmaz (atesle-unut), bu yuzden Notifier
/// degil sade servis.
class MealPhotoService {
  const MealPhotoService(this._dio);

  final Dio _dio;

  /// Tabak fotografini POST /vision/meal'e gonderir.
  ///
  /// Foto sikistirma image_picker tarafinda (maxWidth/quality) yapiliyor;
  /// backend prepare_image ile ikinci kez kucultuyor.
  Future<MealEstimate> tahminEt(File dosya) async {
    final form = await MultipartHelper.singleImageForm(dosya);
    final response = await _dio.post<Map<String, dynamic>>(
      '/vision/meal',
      data: form,
    );
    return MealEstimate.fromJson(response.data!);
  }

  /// Onaylanan ogunu gunluge yazar (POST /meals).
  ///
  /// ANLIK GORUNTU: custom_name + calories + makrolar dogrudan
  /// gonderiliyor. Kullanici kartta ne gorduyse gunluge o yazilir;
  /// katalog referansina baglanmiyoruz cunku tahmin zaten hesaplandi.
  Future<void> gunlugeYaz({
    required String date,
    required String mealType,
    required String dishName,
    required double calories,
    double? grams,
    double? proteinG,
    double? carbG,
    double? fatG,
    
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/meals',
      data: {
        'logged_date': date,
        'meal_type': mealType,
        'source': 'foto',
        'custom_name': dishName,
        'calories': calories,
        'servings': 1,
        'quantity_g': ?grams,
        'protein_g': ?proteinG,
        'carb_g': ?carbG,
        'fat_g': ?fatG,
      },
    );
  }
}

final mealPhotoServiceProvider = Provider<MealPhotoService>(
  (ref) => MealPhotoService(ref.read(dioProvider)),
);