import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';

//kullanıcı oyurumunu arka planda canlı tutuyor

/// Bearer token ekler ve 401'de otomatik yenileme dener.
///
/// AKIS:
///   1) Her istege access_token varsa Authorization basligi eklenir.
///   2) Bir istek 401 donerse, BU istek /auth/login veya /auth/refresh
///      DEGILSE, refresh_token ile yeni bir access_token alinir.
///   3) Basarili olursa ORIJINAL istek YENI token ile TEKRAR gonderilir.
///   4) Basarisiz olursa (refresh_token de gecersiz) tum token'lar
///      SILINIR - cagiran taraf bunu 401 olarak gorur, giris ekranina
///      YONLENDIRME sorumlulugu UI'dadir.
///
/// NEDEN AYRI 'plain' Dio: refresh ve retry istekleri BU interceptor'in
/// KENDISINDEN GECMEZ. Gecseydi ve retry de 401 alsaydi SONSUZ DONGU
/// olurdu.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.storage, required this.baseUrl});

  final SecureStorage storage;
  final String baseUrl;

  /// Ayni anda birden fazla istek 401 alirsa HEPSI AYNI yenileme
  /// cagrisini beklesin - backend'e gereksiz coklu /auth/refresh
  /// istegi gitmesin.
  Future<String?>? _refreshFuture;

  static const _authFreeRoutes = [
    '/auth/login',
    '/auth/refresh',
    '/auth/register',
    '/auth/token',
  ];

  bool _isAuthFree(String path) { //bazı uçlar token istemez mesela loginde 401 dönerse şifren yanlış demek token yenilemek saçma olur 
    return _authFreeRoutes.any((route) => path.contains(route));
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isAuthFree(options.path)) {
      //her istek gitmeden önce tokeni depodan alıp başlığa ekliyor bu sayede api çağrılarını yazarken tokeni hiç düşünmüyorsun kendiliğinden ekleniyor
      final token = await storage.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    //istek hata döndürürse / yetkisiz giriş ile ilgileniyor 
    final is401 = err.response?.statusCode == 401;
    if (!is401 || _isAuthFree(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    //401 gelince: yeni token almayı dene 
    //-> alamadıysan tüm tokenleri sil hatayı yukarı bak kullanıcıyı çıkış yaptır 
    //-> eğer yeni token aldıysan başarısız olan orjinal isteği al üzerinden eski tokeni yenisiyle değiştir tekrar 
    //handler.resolve(response): resolve hata yoktu işte başarılı cevap demek yani ekranı çağıran kod hiç hata görmüyor onun açısından istek ilk seferde başarılı olmuş gibi arka planda token yenilendi istek tekrarlandı hepsi görünmez
    final newAccessToken = await _refreshAccessToken();
    if (newAccessToken == null) {
      await storage.clear();
      handler.next(err);
      return;
    }

    final retryOptions = err.requestOptions;
    retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

    try {
      final retryDio = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await retryDio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<String?> _refreshAccessToken() {
    return _refreshFuture ??= _doRefresh().whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await storage.refreshToken;
    if (refreshToken == null) return null;

    try {
      final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = response.data!;
      final newAccess = data['access_token'] as String;
      final newRefresh = data['refresh_token'] as String? ?? refreshToken;
      await storage.saveTokens(accessToken: newAccess, refreshToken: newRefresh);
      return newAccess;
    } on DioException {
      return null;
    }
  }
}