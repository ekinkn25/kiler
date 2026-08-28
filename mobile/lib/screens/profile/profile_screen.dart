import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/cikis_akisi.dart';
import '../../widgets/hata_gorunumu.dart';
import '../../widgets/profil_duzenle_sheet.dart';
import '../../widgets/profil_parcalari.dart';

/// Profil ekrani: kimlik, vucut olculeri, hedef ve diyet tercihleri.
///
/// NEDEN CEKMECEDE DEGIL: cekmece hizli gecis icin - uzun bir bilgi
/// listesi orada kaydirma gerektiriyor ve menu ogelerini asagi itiyordu.
/// Bilgiler burada nefes alan bir duzende duruyor; cekmecede yalnizca
/// kimlik karti ve menu kaldi.
///
/// TUM VERI GET /auth/me'den geliyor - ek istek YOK.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oturum = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: oturum.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (hata, _) => HataDurumu(
          hata: hata,
          baslik: 'Profil yüklenemedi',
          onTekrar: () => unawaited(ref.read(authProvider.notifier).retry()),
        ),
        data: (kullanici) => kullanici == null
            // Router zaten /giris'e yonlendiriyor; bu yalnizca o an icin.
            ? const SizedBox.shrink()
            : _Govde(kullanici: kullanici),
      ),
    );
  }
}

class _Govde extends ConsumerWidget {
  const _Govde({required this.kullanici});

  final AppUser kullanici;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme renkler = Theme.of(context).colorScheme;
    final UserProfile? p = kullanici.profile;
    final String ad = (kullanici.fullName ?? '').trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        // ---------------- kimlik ----------------
        Center(
          child: Column(
            children: [
              ProfilAvatar(ad: ad, eposta: kullanici.email, yaricap: 48),
              const SizedBox(height: 14),
              Text(
                ad.isEmpty ? 'Merhaba!' : ad,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                kullanici.email,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: renkler.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '${uyelikTarihi(kullanici.createdAt)} tarihinden beri üye',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: renkler.outline),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ---------------- vucut olculeri ----------------
        if (p != null) ...[
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ölçülerin',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    // Duzenleme GIRISI burada: kullanici degistirmek
                    // istedigi sayiya bakarken duzeltebilsin. Ayri bir
                    // 'Ayarlar' ekranina gomulseydi kimse bulamazdi.
                    TextButton.icon(
                      onPressed: () =>
                          unawaited(profilDuzenleAc(context, p)),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Düzenle'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    OlcuKutusu(
                      etiket: 'Boy',
                      deger: p.heightCm == null
                          ? '—'
                          : '${p.heightCm!.toStringAsFixed(0)} cm',
                    ),
                    OlcuKutusu(
                      etiket: 'Kilo',
                      deger: p.weightKg == null
                          ? '—'
                          : '${p.weightKg!.toStringAsFixed(1)} kg',
                    ),
                    OlcuKutusu(etiket: 'Yaş', deger: p.age?.toString() ?? '—'),
                    OlcuKutusu(
                      etiket: 'BMI',
                      deger: p.bmi == null ? '—' : p.bmi!.toStringAsFixed(1),
                      altMetin: p.bmiEtiketi,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          AppCard(
            onTap: () => context.push('/kilo-gecmisi'),
            child: Row(
              children: [
                Icon(Icons.show_chart, color: renkler.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kilo geçmişi',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        'Değişim grafiğin ve tüm kayıtların',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: renkler.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: renkler.outline),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---------------- hedef ----------------
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(p.goal.ikon, size: 20, color: renkler.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.goal.etiket,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _Satir(etiket: 'Aktivite', deger: p.activityLevel.etiket),
                _Satir(
                  etiket: 'Günlük hedef',
                  deger: '${p.dailyCalorieTarget.toStringAsFixed(0)} kcal',
                ),
                if (p.proteinTargetG != null)
                  _Satir(
                    etiket: 'Makro',
                    deger: 'P ${p.proteinTargetG!.toStringAsFixed(0)} g · '
                        'K ${p.carbTargetG?.toStringAsFixed(0) ?? '—'} g · '
                        'Y ${p.fatTargetG?.toStringAsFixed(0) ?? '—'} g',
                  ),
                if (p.householdSize > 1)
                  _Satir(
                    etiket: 'Hane',
                    deger: '${p.householdSize} kişi',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ---------------- cipler ----------------
        if (kullanici.dietTags.isNotEmpty || kullanici.allergens.isNotEmpty)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kullanici.dietTags.isNotEmpty)
                  CipGrubu(
                    baslik: 'Diyet tercihlerin',
                    etiketler: kullanici.dietTags,
                    renk: renkler.secondaryContainer,
                    yaziRengi: renkler.onSecondaryContainer,
                  ),
                if (kullanici.dietTags.isNotEmpty &&
                    kullanici.allergens.isNotEmpty)
                  const SizedBox(height: 16),
                if (kullanici.allergens.isNotEmpty)
                  CipGrubu(
                    baslik: 'Alerjenlerin',
                    etiketler: kullanici.allergens,
                    // Alerjen UYARIDIR, tercih degil: rengi de oyle olmali.
                    renk: renkler.errorContainer,
                    yaziRengi: renkler.onErrorContainer,
                  ),
              ],
            ),
          ),

        const SizedBox(height: 28),
        AppButton(
          label: 'Çıkış Yap',
          variant: AppButtonVariant.secondary,
          onPressed: () => unawaited(cikisAkisi(context, ref)),
        ),
      ],
    );
  }
}

/// Etiket solda, deger sagda tek satir.
class _Satir extends StatelessWidget {
  const _Satir({required this.etiket, required this.deger});

  final String etiket;
  final String deger;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              etiket,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: renkler.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(deger, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}