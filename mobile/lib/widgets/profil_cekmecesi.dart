import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/hata/guvenli.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';

/// Sol taraftan acilan profil cekmecesi.
///
/// NEDEN VAR: /profil rotasi tanimliydi ama ona giden TEK link gelistirici
/// ekranindaydi - yani gercek kullanici hesabini goremiyor ve CIKIS
/// YAPAMIYORDU. Cekmece bu bosluğu kapatir ve ilerideki profil
/// ozelliklerinin (vucut olculeri, KVKK, tema) tek toplanma noktasi olur.
///
/// NEDEN MainShell'DE DEGIL: dort sekmenin her birinin KENDI Scaffold'u ve
/// AppBar'i var. MainShell'in Scaffold'una drawer koyulursa hamburger
/// ikonu cikmaz, cunku ekranda gorunen AppBar cocugun Scaffold'una aittir.
/// Bu yuzden her sekme kendi Scaffold'una `drawer: const ProfilCekmecesi()`
/// ekliyor - dort satir, router'a dokunmadan.
class ProfilCekmecesi extends ConsumerWidget {
  const ProfilCekmecesi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oturum = ref.watch(authProvider);

    return Drawer(
      child: SafeArea(
        // ListView: kucuk ekranlarda ve klavye acikken tasma olmasin.
        // Column kullanilsaydi 'RenderFlex overflowed' hatasi alinirdi.
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            oturum.when(
              loading: () => const _BaslikIskelet(),
              error: (hata, _) => _BaslikHata(
                onTekrar: () =>
                    unawaited(ref.read(authProvider.notifier).retry()),
              ),
              data: (kullanici) => kullanici == null
                  ? const _BaslikIskelet()
                  : _KimlikKarti(kullanici: kullanici),
            ),

            const SizedBox(height: 8),

            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profilim'),
              onTap: () {
                // ONCE cekmeceyi kapat, SONRA gez. Ters sirada yapilirsa
                // yeni ekranin ustunde acik cekmece kalir.
                Navigator.of(context).pop();
                context.push('/profil');
              },
            ),

            // ---------------------------------------------------------
            // Sonraki adimlarda buraya eklenecek:
            //   2) Vucut olculeri + hedef karti (AppUser genisletilince)
            //   3) KVKK: verilerimi indir / hesabimi sil
            //   4) Canli sayaclar (kiler, alisveris, yapacaklarim)
            //   5) Kilo/boy duzenleme (PATCH /me/profile)
            //   6) Tema secimi + debug: son hatalar
            // ---------------------------------------------------------

            const Divider(height: 24),

            ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Çıkış Yap',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => unawaited(_cikisYap(context, ref)),
            ),

            const SizedBox(height: 16),
            Center(
              child: Text(
                '${AppConfig.appName} · ${AppConfig.appVersion}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// Cikis ONAY ISTER.
  ///
  /// Tek dokunusla cikis yaptirmak, yanlislikla basan kullanicinin
  /// yeniden e-posta ve sifre girmesi demek. Geri alinamayan her islem
  /// gibi bu da soruluyor.
  Future<void> _cikisYap(BuildContext context, WidgetRef ref) async {
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

    // Cekmeceyi kapat: router /giris'e yonlendirdiginde acik kalmasin.
    Navigator.of(context).pop();

    // guvenliCalistir (W4-T15): secure storage temizligi patlarsa
    // kullanici sessizce 'cikis yapamayan' bir ekranda kalmasin.
    await guvenliCalistir(
      () => ref.read(authProvider.notifier).logout(),
      etiket: 'profil.cikis',
      context: context,
      onEk: 'Çıkış yapılamadı:',
    );
    // Yonlendirme YOK: app_router redirect'i authProvider'i dinliyor,
    // durum null'a dusunce /giris'e kendisi gidiyor.
  }
}

// ====================================================================
// Kimlik karti
// ====================================================================
class _KimlikKarti extends StatelessWidget {
  const _KimlikKarti({required this.kullanici});

  final AppUser kullanici;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;
    final String ad = (kullanici.fullName ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      color: renkler.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: renkler.primary,
            child: Text(
              _basHarf(ad, kullanici.email),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: renkler.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ad.isEmpty ? 'Merhaba!' : ad,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: renkler.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            kullanici.email,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: renkler.onPrimaryContainer.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '${_tarihMetni(kullanici.createdAt)} tarihinden beri üye',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: renkler.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatardaki bas harf.
///
/// TURKCE INCELIGI: Dart'in toUpperCase()'i dilden bagimsizdir ve
/// 'ismail' -> 'I' verir; dogrusu 'İ'. Tek karakterlik bir ayrinti ama
/// kullanicinin kendi adini yanlis gormesi demek.
String _basHarf(String ad, String eposta) {
  final kaynak = ad.isNotEmpty ? ad : eposta;
  if (kaynak.isEmpty) return '?';
  final ilk = kaynak[0];
  if (ilk == 'i') return 'İ';
  return ilk.toUpperCase();
}

/// '27 Ağustos 2026' bicimi.
///
/// NEDEN intl'in DateFormat'i DEGIL: Turkce ay adlari icin
/// initializeDateFormatting('tr') cagrilmasi ve MaterialApp'e
/// localizationsDelegates eklenmesi gerekiyor. Projede ikisi de yok;
/// tek bir tarih icin o kurulumu yapmak yerine sabit liste yeterli.
/// (Uygulama coklu dile gecerse burasi DateFormat'a devredilir.)
const List<String> _aylar = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

String _tarihMetni(DateTime utc) {
  // Backend UTC gonderiyor; kullaniciya KENDI saat diliminde gosteriyoruz.
  final t = utc.toLocal();
  return '${t.day} ${_aylar[t.month - 1]} ${t.year}';
}

// ====================================================================
// Yukleniyor / hata basliklari
// ====================================================================
class _BaslikIskelet extends StatelessWidget {
  const _BaslikIskelet();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: 168,
    color: Theme.of(context).colorScheme.primaryContainer,
    alignment: Alignment.center,
    child: const CircularProgressIndicator(),
  );
}

/// /auth/me'ye ULASILAMADI (ag sorunu). Token silinmedi, tekrar denenebilir.
class _BaslikHata extends StatelessWidget {
  const _BaslikHata({required this.onTekrar});

  final VoidCallback onTekrar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      color: renkler.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_outlined, color: renkler.onPrimaryContainer),
          const SizedBox(height: 8),
          Text(
            'Bilgilerin yüklenemedi',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: renkler.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          TextButton(onPressed: onTekrar, child: const Text('Yeniden dene')),
        ],
      ),
    );
  }
}