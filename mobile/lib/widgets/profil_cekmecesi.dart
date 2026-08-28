import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/hata/hata_kaydi.dart';
import '../core/theme/tema_provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import 'cikis_akisi.dart';
import 'profil_parcalari.dart';
import 'tema_secici.dart';

/// Sol taraftan acilan profil cekmecesi.
///
/// NEDEN VAR: /profil rotasi tanimliydi ama ona giden TEK link gelistirici
/// ekranindaydi - yani gercek kullanici hesabini goremiyor ve CIKIS
/// YAPAMIYORDU. Cekmece bu boslugu kapatir.
///
/// NEDEN SADECE KIMLIK + MENU: vucut olculeri, hedef ve cipler burada da
/// duruyordu ama liste uzayinca menu ogelerini asagi itiyor ve kaydirma
/// gerektiriyordu. O bilgiler artik ProfileScreen'de nefes alan bir
/// duzende; cekmece hizli gecis icin sade kaldi.
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
    final temaModu = ref.watch(temaProvider);
    // Statik halka; cekmece her acilista okunuyor. Canli dinleme icin
    // HataKaydi'ni bir saglayiciya cevirmek gerekirdi - bir rozet ugruna
    // hata kayit yolunu karmasiklastirmaya degmez.
    final hataSayisi = HataKaydi.sonHatalar.length;

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
              subtitle: const Text('Ölçüler, hedef ve tercihler'),
              onTap: () {
                // ONCE cekmeceyi kapat, SONRA gez. Ters sirada yapilirsa
                // yeni ekranin ustunde acik cekmece kalir.
                Navigator.of(context).pop();
                context.push('/profil');
              },
            ),

            ListTile(
              leading: const Icon(Icons.monitor_weight_outlined),
              title: const Text('Kilo Geçmişi'),
              subtitle: Text(_kiloOzeti(oturum.valueOrNull)),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/kilo-gecmisi');
              },
            ),

            const Divider(height: 24),

            // ---------------------------------------------------------
            // Gorunum ve tanilama
            // ---------------------------------------------------------
            ListTile(
              leading: Icon(temaModu.ikon),
              title: const Text('Tema'),
              subtitle: Text(temaModu.etiket),
              onTap: () => unawaited(temaSeciciAc(context)),
            ),

            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Son Hatalar'),
              subtitle: Text(
                hataSayisi == 0
                    ? 'Kayıtlı hata yok'
                    : '$hataSayisi kayıt · yalnızca bu oturum',
              ),
              trailing: hataSayisi == 0
                  ? null
                  : Badge(label: Text('$hataSayisi')),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/dev/hatalar');
              },
            ),

            // ---------------------------------------------------------
            // Sonraki adimlarda buraya eklenecek:
            //   3) KVKK: verilerimi indir / hesabimi sil
            //   4) Canli sayaclar (kiler, alisveris, yapacaklarim)
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
              onTap: () => unawaited(cikisAkisi(
                context,
                ref,
                // Cekmece onay ALINDIKTAN sonra kapansin: kullanici
                // 'Vazgec' derse acik kalmali.
                onayVerildiginde: () => Navigator.of(context).pop(),
              )),
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
}

/// 'Kilo Geçmişi' satirinin alt yazisi.
///
/// Oturum henuz yuklenmediyse veya anket tamamlanmadiysa sayi yerine ne ise
/// yaradigini anlatan bir cumle duruyor - bos bir '— kg' hicbir sey soylemez.
String _kiloOzeti(AppUser? kullanici) {
  final kilo = kullanici?.profile?.weightKg;
  if (kilo == null) return 'Değişimini takip et';
  return 'Şu an ${kilo.toStringAsFixed(1)} kg';
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
          // Avatar ve tarih bicimi ProfileScreen ile ORTAK
          // (profil_parcalari.dart) - iki yerde ayri kopya tutulmuyor.
          ProfilAvatar(ad: ad, eposta: kullanici.email),
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
            '${uyelikTarihi(kullanici.createdAt)} tarihinden beri üye',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: renkler.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
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