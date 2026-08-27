import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/hata/guvenli.dart';
import '../providers/auth_provider.dart';

/// Uygulamadaki TEK cikis yolu.
///
/// NEDEN ORTAK FONKSIYON: cikisin iki giris noktasi var (profil cekmecesi
/// ve profil ekrani). Ayri ayri yazilinca biri onay soruyor, digeri
/// sormuyordu - kullanici hangi butona bastigina gore farkli davranisla
/// karsilasiyordu. Onay metni de degistiginde tek yer degissin.
///
/// [onayVerildiginde] onay alindiktan HEMEN SONRA, cikistan ONCE calisir.
/// Cekmece bunu kendini kapatmak icin kullanir; tam ekranda gerek yok.
Future<void> cikisAkisi(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onayVerildiginde,
}) async {
  final onay = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Çıkış yapılsın mı?'),
      content: const Text(
        'Tekrar girmek için e-posta ve şifreni yazman gerekecek.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Çıkış yap'),
        ),
      ],
    ),
  );

  if (onay != true || !context.mounted) return;

  onayVerildiginde?.call();

  // guvenliCalistir (W4-T15): secure storage temizligi patlarsa kullanici
  // sessizce 'cikis yapamayan' bir ekranda kalmasin.
  await guvenliCalistir(
    () => ref.read(authProvider.notifier).logout(),
    etiket: 'profil.cikis',
    context: context,
    onEk: 'Çıkış yapılamadı:',
  );
  // Yonlendirme YOK: app_router redirect'i authProvider'i dinliyor,
  // durum null'a dusunce /giris'e kendisi gidiyor.
}