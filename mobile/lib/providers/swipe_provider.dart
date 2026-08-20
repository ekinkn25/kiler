import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../models/enums.dart';
import '../models/ingredient_lite.dart';
import '../models/swipe_feedback.dart';

// riverpod statei tutmaz swipe katdı ateşle ve unut bir olaydır, ekranın yeniden çizilmesini gerektirmez 

class SwipeResult {
  const SwipeResult({ required this.effect, this.sessionFilters = const {}});
    final String effect;
    final Map<String,dynamic> sessionFilters;
}

class SwipeFeedbackService {
  const SwipeFeedbackService(this._dio);

  final Dio _dio;

  /// Doner: backend'in insan okunur `effect` metni (SnackBar'da gosterilir).
  ///
  /// DIKKAT (backend SwipeRequest dogrulamasi):
  ///   - `reason` yalnizca action='begenmedim' ile gonderilebilir,
  ///   - `missingIngredientId` yalnizca reason='malzeme_yok' ile.
  /// Yanlis kombinasyon 422 doner.
  Future<SwipeResult> gonder({
    required String recipeId,
    required FeedbackAction action,
    FeedbackReason? reason,
    int? sessionId,
    int? missingIngredientId,
  }) async {
    final govde = SwipeFeedback(
      action: action,
      reason: reason,
      sessionId: sessionId,
      missingIngredientId: missingIngredientId,
    );

    final response = await _dio.post<Map<String, dynamic>>(
      '/recipes/$recipeId/swipe',
      data: govde.toJson(),
    );
    final veri = response.data ?? const <String, dynamic>{};
    return SwipeResult(
      effect: veri['effect'] as String? ?? 'Kaydedildi.',
      sessionFilters:
          (veri['session_filters'] as Map<String, dynamic>?) ?? const {},
    );
  }
  }

final swipeFeedbackServiceProvider = Provider<SwipeFeedbackService>(
  (ref) => SwipeFeedbackService(ref.read(dioProvider)),
);

/// canonical_name listesi -> malzeme kimlikleri.
///
/// family anahtari VIRGULLE BIRLESTIRILMIS METIN: List String  anahtar
/// olarak kullanilamaz, cunku Riverpod family degerlerini == ile
/// karsilastirir; iki ayri liste asla esit sayilmaz ve her build yeni
/// istek atardi. String'in deger esitligi vardir.
final missingIngredientsProvider =
    FutureProvider.autoDispose.family<List<IngredientLite>, String>((ref, names) async {
  if (names.isEmpty) return const [];

  final dio = ref.read(dioProvider);
  final response = await dio.get<List<dynamic>>(
    '/catalog/ingredients',
    queryParameters: {'names': names},
  );
  return response.data!
      .map((e) => IngredientLite.fromJson(e as Map<String, dynamic>))
      .toList();
});