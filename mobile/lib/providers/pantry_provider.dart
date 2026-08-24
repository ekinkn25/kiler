import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/enums.dart';
import '../models/pantry_item.dart';
import 'package:dio/dio.dart';
import '../core/network/multipart_helper.dart';
import '../models/detected_ingredient.dart';
import '../models/ingredient_lite.dart';
import 'dart:io';

/// Kiler listesi (W3-T18).
///
/// autoDispose DEGIL: Kiler sekmesi ile Kesfet arasinda gidip gelmek
/// listeyi her seferinde yeniden cekmesin.
class PantryNotifier extends AsyncNotifier<List<PantryItem>> {
  @override
  Future<List<PantryItem>> build() => _cek();

  Future<List<PantryItem>> _cek() async {
    final dio = ref.read(dioProvider);
    final response = await dio.get<List<dynamic>>('/pantry');
    return response.data!
        .map((e) => PantryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> yenile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_cek);
  }

  /// [Var] / [Bitti] hizli aksiyonu.
  ///
  /// Yanit listeyi YERINDE gunceller, yeniden CEKMEZ: tam liste
  /// yenilemesi ekrani bir an bosaltir ve kullanici hangi satira
  /// dokundugunu kaybeder.
  ///
  /// still_have=false -> kayit 'bitti' olur ve backend'in varsayilan
  /// listesinden duser; bu yuzden yerelde de listeden CIKARILIR.
  Future<void> durumDegistir(int itemId, {required Availability hedef}) async {
    final mevcut = state.valueOrNull;
    if (mevcut == null) return;

    final dio = ref.read(dioProvider);
    final response = await dio.patch<Map<String, dynamic>>(
      '/pantry/$itemId',
      data: {'availability': availabilityToJson(hedef)},
    );
    final guncel = PantryItem.fromJson(response.data!);

    state = AsyncData(
      hedef == Availability.finished
          ? [for (final k in mevcut) if (k.id != itemId) k]
          : [for (final k in mevcut) if (k.id == itemId) guncel else k],
    );
  }

  Future<void> elleEkle(int ingredientId) async {
    final dio = ref.read(dioProvider);
    await dio.post<Map<String, dynamic>>(
      '/pantry/items',
      data: {'ingredient_id': ingredientId},
    );
    await yenile();
  }
}

final pantryProvider =
    AsyncNotifierProvider<PantryNotifier, List<PantryItem>>(PantryNotifier.new);

/// Listeyi ekranin iki bolumune ayirir.
///
/// Backend `availability` alanini GUVEN SURESI UYGULANMIS olarak donuyor:
/// 7 gunu gecmis bir 'var' kaydi buraya 'bilinmiyor' olarak geliyor.
/// Yani istemci tarafinda ek bir tarih hesabi YAPILMIYOR.
final pantryGroupsProvider = Provider<({List<PantryItem> kesinVar, List<PantryItem> eminDegiliz})>((ref) {
  final liste = ref.watch(pantryProvider).valueOrNull ?? const <PantryItem>[];
  return (
    kesinVar: liste.where((k) => k.availability == Availability.available).toList(),
    eminDegiliz: liste.where((k) => k.availability == Availability.unknown).toList(),
  );
});

/// Fotograftan tespit edilen malzemeleri kilere yazar (W3-T13).
///
/// Ayri bir servis: sohbet ekrani kiler LISTESINI dinlemiyor, yalnizca
/// yazma islemi yapiyor. Notifier'a koymak gereksiz bagimlilik olurdu.
class PantryConfirmService {
  const PantryConfirmService(this._dio);

  final Dio _dio;

  /// Doner: kilere gercekten yazilan malzeme sayisi.
  ///
  /// Sozlukte karsiligi olmayan adlar backend tarafinda ATLANIR
  /// (skipped_unknown), bu yuzden donen sayi gonderilenden az olabilir.
  Future<int> kilereEkle(List<String> canonicalNames) async {
    if (canonicalNames.isEmpty) return 0;

    final response = await _dio.post<Map<String, dynamic>>(
      '/pantry/confirm-detected',
      data: {'canonical_name': canonicalNames, 'source': 'foto'},
    );
    final onaylanan =
        (response.data?['confirmed'] as List<dynamic>?) ?? const [];
    return onaylanan.length;
  }

  /// Fotografi POST /vision/ingredients'e gonderir, tespitleri doner.
  /// Kiler ekranindaki '+' -> Kamera akisi bunu kullanir.
  Future<List<DetectedIngredient>> fotodanTespit(File dosya) async {
    final form = await MultipartHelper.singleImageForm(dosya);
    final response =
        await _dio.post<List<dynamic>>('/vision/ingredients', data: form);
    return (response.data ?? const [])
        .map((e) => DetectedIngredient.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final pantryConfirmServiceProvider = Provider<PantryConfirmService>(
  (ref) => PantryConfirmService(ref.read(dioProvider)),
);


/// Malzeme arama (elle ekleme icin). GET /catalog/ingredients/search.
///
/// family anahtari arama METNI. 2 karakterden kisa sorgu ag'a cikmaz -
/// her tus basiminda istek atmamak icin.
final ingredientSearchProvider =
    FutureProvider.autoDispose.family<List<IngredientLite>, String>((ref, q) async {
  final sorgu = q.trim();
  if (sorgu.length < 2) return const [];

  final dio = ref.read(dioProvider);
  final response = await dio.get<List<dynamic>>(
    '/catalog/ingredients/search',
    queryParameters: {'q': sorgu, 'limit': 15},
  );
  return response.data!
      .map((e) => IngredientLite.fromJson(e as Map<String, dynamic>))
      .toList();
});