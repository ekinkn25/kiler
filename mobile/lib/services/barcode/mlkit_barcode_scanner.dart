import 'package:flutter/material.dart';

import 'barcode_scanner.dart';

/// Google ML Kit tabanli gercek tarayici.
///
/// GOVDESI W2-T10'DA DOLDURULACAK. Su an bilincli olarak bos: arayuz ve
/// saglayici yapisi bugun kurulup, kamera entegrasyonu 8. gunde eklenecek.
/// Boylece aradaki gorevlerde barkod akisi FakeBarcodeScanner ile gelistirilir.
class MlKitBarcodeScanner implements BarcodeScanner {
  const MlKitBarcodeScanner();

  @override
  String get name => 'ML Kit (gerçek kamera)';

  @override
  Future<String?> scan(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Henüz hazır değil'),
        content: const Text(
          'Kamera ile barkod okuma W2-T10 görevinde eklenecek.\n\n'
          'Şimdilik uygulamayı --dart-define=USE_FAKE_SCANNER=true ile '
          'çalıştırarak sahte tarayıcıyı kullanabilirsiniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
    return null;
  }
}