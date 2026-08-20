import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';

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