import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

//token gibi hassas verilerin saklandığı TEK yer olacak
//flutter_secure_storage: Android'de Keystore, iOS'ta Keychain kullanir - SharedPreferences gibi duz metin DEGIL. Token'lar baska hicbir yerde (ornegin bellekte statik degisken) tutulmamali.

class SecureStorage {
  const SecureStorage(this._storage);
  final FlutterSecureStorage _storage;
  static const _accessTokenKey = "access_token";
  static const _refreshTokenKey = "refresh_token";
  static const _temaKey = "tema_modu";
  Future<String?> get accessToken => _storage.read(key: _accessTokenKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshTokenKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Tema tercihi ('sistem' | 'acik' | 'koyu').
  ///
  /// NEDEN BURADA: hassas bir veri degil ama projede kalici anahtar-deger
  /// deposu olarak SADECE burasi var. Tek bir tercih ugruna
  /// shared_preferences bagimliligi eklemek yerine var olan depoyu
  /// kullaniyoruz.
  Future<String?> get temaModu => _storage.read(key: _temaKey);

  Future<void> temaModuYaz(String deger) =>
      _storage.write(key: _temaKey, value: deger);

  /// Cikista YALNIZCA token'lari siler.
  ///
  /// NEDEN deleteAll() DEGIL: depoda artik token disinda da veri var. Once
  /// deleteAll cagriliyordu; tema tercihi eklendikten sonra bu, cikis yapan
  /// kullanicinin temasini da sifirlardi - guvenlikle hicbir ilgisi olmayan
  /// bir kayip. Depoya yeni bir OTURUM verisi eklenirse buraya da eklenmeli.
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return const SecureStorage(FlutterSecureStorage());
});