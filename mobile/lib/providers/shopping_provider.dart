import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/hata/hata_kaydi.dart';
import '../core/network/dio_client.dart';
import '../models/shopping_item.dart';

/// Alisveris listesi yazma servisi.
///
/// Okuma tarafi (liste ekrani) W3-T21'de eklenecek; burada yalnizca
/// swipe akisinin ihtiyaci olan TOPLU EKLEME var.
class ShoppingService {
  const ShoppingService(this._dio);

  final Dio _dio;

  /// Doner: backend'in olusturdugu/guncelledigi kayit sayisi.
  ///
  /// Backend zaten listede olan malzeme icin yeni satir acmaz, var olani
  /// gunceller - bu yuzden donen sayi 'eklenen' degil 'islenen' sayisidir.
  Future<int> tariftenEkle({
    required String recipeId,
    required List<int> ingredientIds,
  }) async {
    if (ingredientIds.isEmpty) return 0;

    final response = await _dio.post<List<dynamic>>(
      '/shopping/bulk',
      data: {
        'recipe_id': recipeId,
        'items': [
          for (final kimlik in ingredientIds) {'ingredient_id': kimlik},
        ],
      },
    );
    return response.data?.length ?? 0;
  }
}

final shoppingServiceProvider = Provider<ShoppingService>(
  (ref) => ShoppingService(ref.read(dioProvider)),
);

// ==================================================================
// Alisveris listesi ekrani (W3-T21)
// ==================================================================
class ShoppingNotifier extends AsyncNotifier<List<ShoppingItem>> {
  @override
  Future<List<ShoppingItem>> build() => _cek();

  Future<List<ShoppingItem>> _cek() async {
    final dio = ref.read(dioProvider);
    final response = await dio.get<List<dynamic>>('/shopping');
    return response.data!
        .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> yenile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_cek);
  }

  /// Elle tek oge ekler. Backend adi sozlukle eslestirir.
  Future<void> elleEkle(String name) async {
    final dio = ref.read(dioProvider);
    await dio.post<Map<String, dynamic>>('/shopping', data: {'name': name});
    await yenile();
  }

  /// Isaretle/kaldir - yaniti YERINDE isler (checkbox aninda tepki versin).
  Future<void> isaretle(int id, bool checked) async {
    final mevcut = state.valueOrNull;
    if (mevcut == null) return;

    final dio = ref.read(dioProvider);
    try {
      final response = await dio.patch<Map<String, dynamic>>(
        '/shopping/$id',
        queryParameters: {'checked': checked},
      );
      final guncel = ShoppingItem.fromJson(response.data!);
      state = AsyncData([
        for (final k in mevcut) if (k.id == id) guncel else k,
      ]);
    } catch (hata, iz) {
      HataKaydi.yaz(hata, iz, kaynak: 'alisveris.isaretle');
      state = AsyncData(mevcut);   // eski liste: kutucuk geri doner
      rethrow;                     // ekran kullaniciya mesaj gosterebilsin
    }
  }

  /// Isaretlenenleri kilere aktarir. Aktarilanlar listeden duser.
  /// Doner: (aktarilan adlar, atlanan adlar).
  Future<({List<String> transferred, List<String> skipped})> kilereAktar() async {
    final dio = ref.read(dioProvider);
    final response = await dio.post<Map<String, dynamic>>(
      '/shopping/transfer-to-pantry',
      data: {'item_ids': <int>[]}, // bos = tum isaretliler
    );
    final t = ((response.data?['transferred'] as List<dynamic>?) ?? const [])
        .cast<String>();
    final s = ((response.data?['skipped'] as List<dynamic>?) ?? const [])
        .cast<String>();
    await yenile();
    return (transferred: t, skipped: s);
  }
}

final shoppingListProvider =
    AsyncNotifierProvider<ShoppingNotifier, List<ShoppingItem>>(
  ShoppingNotifier.new,
);