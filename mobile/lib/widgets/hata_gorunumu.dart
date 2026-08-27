import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import 'empty_state.dart';

/// ErrorWidget.builder yerine gecen NOTR kart (W4-T15).
///
/// Varsayilan ErrorWidget uretimde de kirmizi/gri "exception" kutusu cizer.
/// Kullaniciya yigin izi gostermek hem korkutucu hem bilgi sizintisidir.
/// Debug modda gercek hatayi gosteriyoruz - gelistirirken korlesmeyelim.
class HataGorunumu extends StatelessWidget {
  const HataGorunumu({required this.details, super.key});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      return Material(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'DEBUG — çizim hatası:\n${details.exception}',
            style: const TextStyle(fontSize: 12, color: Colors.red),
          ),
        ),
      );
    }
    return const Material(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Bu bölüm şu an gösterilemiyor.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// AsyncValue.error durumlari icin standart govde (W4-T15).
///
/// Mevcut EmptyState'i yeniden kullanir: uygulamada tek gorsel dil.
/// Bes ekranda birebir ayni EmptyState blogu kopyalanmisti; hata
/// gorunumunu degistirmek gerektiginde tek yer degissin diye toplandi.
///
/// [baslik] verilmezse notr varsayilan kullanilir. Ekrana ozel baslik
/// ('Kiler yuklenemedi') kullaniciya NEYIN yuklenemedigini soyler,
/// o yuzden cagiranlar genelde kendi basligini gecer.
class HataDurumu extends StatelessWidget {
  const HataDurumu({
    required this.hata,
    this.baslik,
    this.onTekrar,
    this.icon = Icons.cloud_off_outlined,
    super.key,
  });

  final Object hata;
  final String? baslik;
  final VoidCallback? onTekrar;
  final IconData icon;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: icon,
    title: baslik ?? 'Şu an bağlanamadık',
    message: friendlyErrorMessage(hata),
    actionLabel: onTekrar == null ? null : 'Yeniden dene',
    actionIcon: Icons.refresh,
    onAction: onTekrar,
  );
}

/// Dar alanlarda (onboarding adimi, arama sonucu listesi) kullanilan
/// KUCUK hata satiri.
///
/// NEDEN AYRI: EmptyState 32 px dolgu + 64 px ikonla tam ekran icin
/// tasarlandi; bir Wrap'in veya kisa bir listenin yerine konunca yerlesimi
/// bozuyor. Burada tek satir metin + kucuk bir 'Yeniden dene' var.
class HataSatiriKucuk extends StatelessWidget {
  const HataSatiriKucuk({required this.mesaj, this.onTekrar, super.key});

  final String mesaj;
  final VoidCallback? onTekrar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off_outlined, size: 18, color: renkler.outline),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            mesaj,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: renkler.onSurfaceVariant,
            ),
          ),
        ),
        if (onTekrar != null)
          TextButton(onPressed: onTekrar, child: const Text('Yeniden dene')),
      ],
    );
  }
}