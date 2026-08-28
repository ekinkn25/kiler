import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/tema_provider.dart';

/// Tema secim penceresi.
///
/// NEDEN RadioListTile DEGIL: Material 3'te tek secimlik kisa listelerde
/// dokunma alani tum satir olan ListTile + secili olana tik isareti
/// yerlesik desen. Ayrica Radio'nun groupValue/onChanged API'si Flutter
/// tarafinda degisim gecirdi; bu ekran o degisimden etkilenmesin.
Future<void> temaSeciciAc(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const _TemaSeciciDialog(),
);

class _TemaSeciciDialog extends ConsumerWidget {
  const _TemaSeciciDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme renkler = Theme.of(context).colorScheme;
    final secili = ref.watch(temaProvider);

    return AlertDialog(
      title: const Text('Tema'),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final mod in ThemeMode.values)
            ListTile(
              leading: Icon(mod.ikon),
              title: Text(mod.etiket),
              subtitle: Text(mod.aciklama),
              trailing: mod == secili
                  ? Icon(Icons.check, color: renkler.primary)
                  : null,
              selected: mod == secili,
              onTap: () {
                // Pencere kapanmadan once tema uygulanir; kullanici
                // degisimi kapanma animasyonu sirasinda gorur.
                unawaited(ref.read(temaProvider.notifier).ayarla(mod));
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
      ],
    );
  }
}
