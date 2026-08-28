import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/hata/hata_kaydi.dart';
import '../../widgets/empty_state.dart';

/// Bellekteki son hatalarin listesi (W4-T15'te acilan HataKaydi halkasi).
///
/// NEDEN VAR: hatalar bugun yalnizca debugPrint ile konsola gidiyor. Gercek
/// bir cihazda -veya sunum sirasinda- konsol elimizde olmuyor; "bir sey
/// olmadi" diyen bir butonun neden calismadigini soracak yer kalmiyordu.
/// HataKaydi son 50 kaydi zaten tutuyordu, burasi onu GORUNUR yapiyor.
///
/// Kayitlar YALNIZCA BELLEKTE: uygulama kapaninca silinirler ve hicbir
/// yere gonderilmezler.
class HataGunluguScreen extends StatefulWidget {
  const HataGunluguScreen({super.key});

  @override
  State<HataGunluguScreen> createState() => _HataGunluguScreenState();
}

class _HataGunluguScreenState extends State<HataGunluguScreen> {
  @override
  Widget build(BuildContext context) {
    // Statik bir liste okunuyor; degisimi dinleyecek bir akis yok. Yenile
    // dugmesi bilincli bir tercih - listenin altindan kayip durmasindansa
    // kullanici ne zaman baktigini bilsin.
    final hatalar = HataKaydi.sonHatalar;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Son Hatalar'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
          IconButton(
            tooltip: 'Temizle',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: hatalar.isEmpty
                ? null
                : () => setState(HataKaydi.temizle),
          ),
        ],
      ),
      body: hatalar.isEmpty
          ? const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'Kayıtlı hata yok',
              message: 'Uygulama açıldığından beri yakalanan bir hata olmadı.',
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: hatalar.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              // sonHatalar zaten YENIDEN ESKIYE sirali (HataKaydi.reversed).
              itemBuilder: (context, i) => _HataSatiri(satir: hatalar[i]),
            ),
    );
  }
}

class _HataSatiri extends StatelessWidget {
  const _HataSatiri({required this.satir});

  final HataSatiri satir;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;

    return ExpansionTile(
      leading: Icon(Icons.error_outline, color: renkler.error),
      title: Text(
        satir.kaynak,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Text(
        '${_saat(satir.an)} · ${satir.mesaj}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: renkler.onSurfaceVariant),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SelectableText: yigin izini elle secip kopyalayabilmek, hata
        // ayiklarken ekran fotografi cekmekten hizli.
        SelectableText(
          satir.mesaj,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (satir.iz != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: renkler.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              // Yigin izinin tamami cok uzun olabiliyor; ilk satirlar
              // hatanin nerede dogdugunu zaten soyluyor.
              _ilkSatirlar(satir.iz!, 12),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.copy_all_outlined, size: 18),
            label: const Text('Kopyala'),
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: '[${satir.kaynak}] ${satir.an}\n'
                    '${satir.mesaj}\n${satir.iz ?? ''}',
              ));
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text('Panoya kopyalandı')),
                );
            },
          ),
        ),
      ],
    );
  }

  static String _saat(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';

  static String _ilkSatirlar(String metin, int adet) {
    final satirlar = metin.split('\n');
    if (satirlar.length <= adet) return metin;
    return '${satirlar.take(adet).join('\n')}\n… (${satirlar.length - adet} satır daha)';
  }
}
