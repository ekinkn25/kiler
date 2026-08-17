import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../core/storage/secure_storage.dart';
import '../models/app_user.dart';

/// Uygulamanin oturum durumu. AsyncValue'nun uc hali dogrudan kullanilir:
///   loading    -> oturum kontrol ediliyor (splash ekrani)
///   data(null) -> giris yapilmamis
///   data(user) -> giris yapilmis
///   error      -> /auth/me'ye ULASILAMADI (ag sorunu) - token'lar
///                 SILINMEDI, tekrar denenebilir. Kullaniciyi geregi
///                 yokken giris ekranina ATMIYORUZ.
class AuthNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() => _restoreSession();

  Future<AppUser?> _restoreSession() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.accessToken;
    if (token == null) return null; // hic giris yapilmamis, hata degil

    return _fetchMe();
  }

  Future<AppUser?> _fetchMe() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get<Map<String, dynamic>>('/auth/me');
      return AppUser.fromJson(response.data!);
    } on DioException catch (e) {
      // AuthInterceptor 401'de refresh_token'i ZATEN denedi (bkz.
      // auth_interceptor.dart). Hala 401 ise token'lar orada SILINMISTI -
      // burada 'giris yapilmamis' olarak ele aliyoruz.
      if (e.apiException.statusCode == 401) return null;
      rethrow; // network/timeout: state error'a duser, UI 'tekrar dene' gosterir
    }
  }

  /// Giris formundan cagrilir.
  Future<void> login({required String email, required String password}) async {
    // copyWithPrevious ONEMLI: bu 'loading', ILK ACILIS 'loading'inden
    // FARKLI olmali - router splash'a ATLAMASIN, giris ekraninda kalsin.
    state = const AsyncValue<AppUser?>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final dio = ref.read(dioProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data!;
      await ref.read(secureStorageProvider).saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      final user = await _fetchMe();
      if (user == null) {
        throw const ApiException(code: 'unauthorized', message: 'Giriş başarısız oldu.');
      }
      return user;
    });
  }

  /// Cikis. Token'lar SILINIR, durum aninda 'giris yapilmamis'a doner.
  Future<void> logout() async {
    await ref.read(secureStorageProvider).clear();
    state = const AsyncValue.data(null);
  }

  /// Oturumu yeniden kontrol eder (orn. ag hatasi sonrasi 'tekrar dene').
  Future<void> retry() async {
    state = const AsyncValue<AppUser?>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(_restoreSession);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);