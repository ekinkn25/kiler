import 'package:flutter/material.dart';

import '../../models/detected_ingredient.dart';
import '../app_button.dart';

/// Gorme modelinin bulduklarini onaylatan alt sayfa (W3-T13).
///
/// KURAL: dusuk guvenli tespitler VARSAYILAN OLARAK ISARETSIZ gelir.
/// Model yanlis taniyorsa kullanici kutuyu kaldirmak zorunda kalmasin,
/// bilincli olarak EKLEMEK zorunda kalsin - yanlis veri kilere sizmaz.
///
/// Doner: kilere yazilacak canonical_name listesi. Iptal edilirse null.
Future<List<String>?> showDetectedIngredientsSheet(
  BuildContext context, {
  required List<DetectedIngredient> tespitler,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _TespitGovdesi(tespitler: tespitler),
  );
}

class _TespitGovdesi extends StatefulWidget {
  const _TespitGovdesi({required this.tespitler});

  final List<DetectedIngredient> tespitler;

  @override
  State<_TespitGovdesi> createState() => _TespitGovdesiState();
}

class _TespitGovdesiState extends State<_TespitGovdesi> {
  /// Bu esigin ALTINDAKI tespitler 'dusuk guven' sayilir.
  static const double _guvenEsigi = 0.6;

  late final Set<String> _secilenler = {
    for (final t in widget.tespitler)
      // Sozlukte karsiligi olmayanlar kilere YAZILAMAZ (backend atlar),
      // dusuk guvenliler de varsayilan olarak isaretsiz gelir.
      if (t.canonicalName != null && t.confidence >= _guvenEsigi)
        t.canonicalName!,
  };

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;
    final TextTheme yazi = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bunları gördüm',
              textAlign: TextAlign.center,
              style: yazi.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Yanlış tanıdıklarımın işaretini kaldır.',
              textAlign: TextAlign.center,
              style: yazi.bodySmall?.copyWith(color: renkler.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final tespit in widget.tespitler)
                    _satir(tespit, renkler, yazi),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: _secilenler.isEmpty
                  ? 'Malzeme seç'
                  : '${_secilenler.length} malzemeyi kilerime ekle',
              icon: Icons.kitchen_outlined,
              // Bos gonderim backend'de 422 doner (min_length=1).
              onPressed: _secilenler.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_secilenler.toList()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Şimdi değil'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _satir(
    DetectedIngredient tespit,
    ColorScheme renkler,
    TextTheme yazi,
  ) {
    // Sozlukte karsiligi yoksa kilere yazilamaz: secilemez ve sebebi yazar.
    final bool eklenebilir = tespit.canonicalName != null;
    final bool yuksekGuven = tespit.confidence >= _guvenEsigi;
    final bool secili =
        eklenebilir && _secilenler.contains(tespit.canonicalName);

    return CheckboxListTile(
      value: secili,
      onChanged: eklenebilir
          ? (isaretli) => setState(() {
                if (isaretli ?? false) {
                  _secilenler.add(tespit.canonicalName!);
                } else {
                  _secilenler.remove(tespit.canonicalName);
                }
              })
          : null,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        tespit.displayName,
        style: TextStyle(
          color: eklenebilir ? null : renkler.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        !eklenebilir
            ? 'Sözlüğümde yok, ekleyemiyorum'
            : yuksekGuven
                ? 'Eminim'
                : 'Emin değilim',
        style: yazi.labelSmall?.copyWith(
          color: yuksekGuven && eklenebilir
              ? renkler.primary
              : renkler.onSurfaceVariant,
        ),
      ),
    );
  }
}