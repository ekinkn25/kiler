/// Derleme zamani yapilandirmasi.
///
/// Degerler `--dart-define` ile gecilir ve `const` oldugu icin derleyici
/// tarafindan gomulur. Calisma zamaninda degistirilemez; bu bilincli bir
/// tercih: yanlislikla uretim yapilandirmasiyla test yapilmasini onler.
class AppConfig {
  const AppConfig._();

  /// Backend adresi.
  ///
  /// ONEMLI: Android emulatoru icin 10.0.2.2 kullanilir. Emulator kendi
  /// icinde bir sanal makinedir; "localhost" onun kendisini isaret eder,
  /// bilgisayarini degil. 10.0.2.2 emulatorden ana makineye giden ozel adrestir.
  ///   - Android emulatoru : http://10.0.2.2:8000/api/v1
  ///   - Gercek cihaz      : http://bilgisayarin-yerel-ip:8000/api/v1
  ///   - Chrome (web)      : http://127.0.0.1:8000/api/v1
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  /// Sahte barkod tarayiciyi devreye alir.
  ///
  /// Fiziksel Android cihaz olmadan gelistirme yapabilmek icin. true iken
  /// kamera hic acilmaz; bunun yerine hazir barkodlardan secim yapilir.
  static const bool useFakeScanner = bool.fromEnvironment(
    'USE_FAKE_SCANNER',
    defaultValue: false,
  );

  /// Ayrintili ag ve hata gunlugu.
  static const bool debugLogging = bool.fromEnvironment(
    'DEBUG_LOGGING',
    defaultValue: true,
  );

  static const String appName = 'Kalori Sayacı';
  static const Duration requestTimeout = Duration(seconds: 15);
}