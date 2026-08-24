import 'package:flutter/material.dart';

/// Sohbet acilisindaki hazir soru cipleri (W3-T11).
///
/// KLAVYESIZ YOL ILKESI: cipe dokunmak mesaji DOGRUDAN gonderir.
/// Dokunmadan once odak temizlenir (bkz. [onSecildi] cagiran taraf) ki
/// metin kutusu daha once odaklanmissa klavye kapansin.
class SuggestionChips extends StatelessWidget {
  const SuggestionChips({required this.onSecildi, super.key});

  /// Secilen cipin metni - AYNEN mesaj olarak gonderilir.
  final ValueChanged<String> onSecildi;

  /// Gorev tanimindaki dort soru. Metinler DEGISTIRILMEMELI: kullaniciya
  /// gosterilen sey ile backend'e giden sey ayni olmali.
  static const List<String> sorular = [
    'Hafif bir şey öner',
    'Kilerimde ne var?',
    '30 dakikada ne yaparım?',
    'Mercimekli bir şey',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final soru in sorular)
          ActionChip(
            label: Text(soru),
            avatar: const Icon(Icons.bolt_outlined, size: 16),
            onPressed: () => onSecildi(soru),
          ),
      ],
    );
  }
}