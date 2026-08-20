import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/deck_response.dart';

//keşfetteki swipe destesi
class SwipeDeckNotifier extends AutoDisposeAsyncNotifier<DeckResponse>{
  int? _sessionId;
  int? get sessionId => _sessionId;
  @override
  Future<DeckResponse> build() => _cek();
  Future<DeckResponse> _cek() async {
    final dio = ref.read(dioProvider);
    final response = await dio.get<Map<String, dynamic>>(
      '/recipes/deck',
      queryParameters: {
        'limit': 10,
        if (_sessionId != null) 'session_id': _sessionId,
      },
    );
    final deste = DeckResponse.fromJson(response.data!);
    _sessionId = deste.sessionId;
    return deste;
  }

  /// AYNI oturumla yeni kart ister.
  ///
  /// Iki yerde cagrilir: (1) deste bitince, (2) 'zamani fazla' sonrasi -
  /// cunku o an oturumun sure filtresi DARALIR ve elde kalan uzun kartlari
  /// gostermeye devam etmek kullaniciya verilen sozu bozar.
  Future<void> yenile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_cek);
  }

  /// Oturumu SIFIRDAN baslatir; daralmis filtreler de sifirlanir.
  Future<void> oturumuSifirla() async {
    _sessionId = null;
    await yenile();
  }
}

final swipeDeckProvider =
    AsyncNotifierProvider.autoDispose<SwipeDeckNotifier, DeckResponse>(
  SwipeDeckNotifier.new,
);