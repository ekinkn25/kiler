import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/daily_summary.dart';

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