import 'package:flutter/widgets.dart';

/// Barkod okuma davranisinin soyutlamasi.
///
/// NEDEN SOYUTLAMA?
/// Gelistirme ortaminda fiziksel Android cihaz yok; emulator kamerasi da her
/// zaman guvenilir degil. Barkod okumayi dogrudan ekranlara gomseydik, kiler
/// akisinin TAMAMI (barkod -> API -> Open Food Facts -> onay -> kiler) donanima
/// bagimli olurdu.
///
/// Bu arayuz sayesinde:
///   - Gelistirme  : FakeBarcodeScanner  (kamera gerekmez)
///   - Uretim      : MlKitBarcodeScanner (W2-T10)
/// Cagiran kod ikisini de ayirt etmez.
abstract interface class BarcodeScanner {
  /// Kullaniciya gosterilecek uygulama adi (hata ayiklama ekraninda gorunur).
  String get name;

  /// Barkodu okur. Kullanici vazgecerse veya okuma basarisiz olursa null doner.
  Future<String?> scan(BuildContext context);
}