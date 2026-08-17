import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';

/// GET /health sonucunu tutan AsyncNotifier.
///
/// NEDEN AsyncNotifier: Riverpod'un yukleniyor/veri/hata UC durumunu
/// (AsyncValue) HAZIR yonetir - ekran kendi StatefulWidget'inda
/// isLoading/error/data booleanlarini elle TUTMAZ.
class HealthNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() => _fetch();

  Future<Map<String, dynamic>> _fetch() async {
    final dio = ref.read(dioProvider);
    // /health API_V1_PREFIX disindadir (bkz. backend app/main.py) - kok
    // adresten '/api/v1' kirpilir.
    final baseWithoutPrefix = dio.options.baseUrl.replaceAll('/api/v1', '');
    final response = await dio.get<Map<String, dynamic>>('$baseWithoutPrefix/health');
    return response.data!;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

final healthProvider = AsyncNotifierProvider<HealthNotifier, Map<String, dynamic>>(
  HealthNotifier.new,
);