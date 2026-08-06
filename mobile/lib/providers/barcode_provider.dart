import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../services/barcode/barcode_scanner.dart';
import '../services/barcode/fake_barcode_scanner.dart';
import '../services/barcode/mlkit_barcode_scanner.dart';

/// Hangi tarayici uygulamasinin kullanilacagina karar veren tek nokta.
///
/// Ekranlar `ref.read(barcodeScannerProvider).scan(context)` cagirir ve
/// arkada hangi uygulamanin oldugunu BILMEZ. Testlerde bu saglayici
/// override edilerek sahte bir tarayici enjekte edilebilir.
final barcodeScannerProvider = Provider<BarcodeScanner>((ref) {
  return AppConfig.useFakeScanner
      ? const FakeBarcodeScanner()
      : const MlKitBarcodeScanner();
});