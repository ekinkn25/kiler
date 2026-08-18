import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/deck_response.dart';

/// Kesfet sekmesindeki swipe destesi. limit=10: W3-T06 kabul kriteri
/// '10 kartlik destede takilma yok' ile birebir eslesir.
final swipeDeckProvider = FutureProvider.autoDispose<DeckResponse>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get<Map<String, dynamic>>(
    '/recipes/deck',
    queryParameters: {'limit': 10},
  );
  return DeckResponse.fromJson(response.data!);
});