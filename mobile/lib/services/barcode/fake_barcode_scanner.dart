import 'package:flutter/material.dart';

import 'barcode_scanner.dart';

/// Kamera kullanmayan sahte tarayici.
///
/// Hazir barkodlardan secim yaptirir veya elle giris aldirir. Boylece
/// W2-T11'deki "barkod -> urun -> kiler" akisinin tamami cihazsiz test edilir.
class FakeBarcodeScanner implements BarcodeScanner {
  const FakeBarcodeScanner();

  @override
  String get name => 'Sahte Tarayıcı (geliştirme)';

  /// Gercek Turk market urunlerinin barkodlari.
  /// W2-T04'te Open Food Facts sorgusu bunlarla denenecek.
  static const List<({String barkod, String etiket})> demoBarkodlar = [
    (barkod: '8690504010203', etiket: 'Örnek ürün 1'),
    (barkod: '8690632010045', etiket: 'Örnek ürün 2'),
    (barkod: '8690526080901', etiket: 'Örnek ürün 3'),
    (barkod: '5449000000996', etiket: 'Uluslararası ürün'),
    (barkod: '0000000000000', etiket: 'Bulunamayan barkod (404 testi)'),
  ];

  @override
  Future<String?> scan(BuildContext context) async {
    final controller = TextEditingController();

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.developer_mode),
                const SizedBox(width: 8),
                Text(
                  'Sahte Barkod Tarayıcı',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Kamera kullanılmıyor. Bir barkod seçin veya elle girin.',
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
            const Divider(height: 24),
            ...demoBarkodlar.map(
              (d) => ListTile(
                dense: true,
                leading: const Icon(Icons.qr_code_2),
                title: Text(d.barkod),
                subtitle: Text(d.etiket),
                onTap: () => Navigator.pop(sheetContext, d.barkod),
              ),
            ),
            const Divider(height: 24),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Elle barkod gir',
                hintText: '8690...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (v) => Navigator.pop(sheetContext, v.trim()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Vazgeç'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    final deger = controller.text.trim();
                    Navigator.pop(sheetContext, deger.isEmpty ? null : deger);
                  },
                  child: const Text('Onayla'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}