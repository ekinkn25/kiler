import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

//token gibi hassas verilerin saklandığı TEK yer olacak
//flutter_secure_storage: Android'de Keystore, iOS'ta Keychain kullanir - SharedPreferences gibi duz metin DEGIL. Token'lar baska hicbir yerde (ornegin bellekte statik degisken) tutulmamali.

class SecureStorage {
  const SecureStorage(this._storage);
  final FlutterSecureStorage _storage;
  static const _accessTokenKey = "access_token";
  static const _refreshTokenKey = "refresh_token";
  Future<String?> get accessToken => _storage.read(key: _accessTokenKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshTokenKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }
  Future<void> clear() => _storage.deleteAll();
}
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return const SecureStorage(FlutterSecureStorage());
});