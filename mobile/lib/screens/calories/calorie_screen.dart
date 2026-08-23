import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../models/daily_summary.dart';
import '../../models/meal_log.dart';
import '../../providers/meal_provider.dart';
import '../../widgets/calories/calorie_ring.dart';
import '../../widgets/calories/macro_bars.dart';
import '../../widgets/calories/meal_group_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';

/// KALORI sekmesi (W3-T14).
///
/// Ogun EKLEME yollari W3-T15 (fotograf) ve W3-T16'da (arama/barkod)
/// gelecek; bu ekran su an salt GORUNTULEME.
class CalorieScreen extends ConsumerWidget {
  const CalorieScreen({super.key});

  /// Backend'in ogun tipi anahtarlari -> ekranda gorunecek basliklar.
  /// Sira DA onemli: gunun akisina gore diziliyor.
  static const Map<String, String> _grupBasliklari = {
    'kahvalti': 'Kahvaltı',
    'ogle': 'Öğle',
    'aksam': 'Akşam',
    'atistirma': 'Atıştırma',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String secilenGun = ref.watch(selectedDateProvider);
    final ozet = ref.watch(dailySummaryProvider(secilenGun));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalori'),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _TarihSecici(secilenGun: secilenGun),
          ),
        ),
      ),
      body: ozet.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              LoadingSkeleton(width: 180, height: 180, borderRadius: 90),
              SizedBox(height: 24),
              LoadingSkeleton.card(),
            ],
          ),
        ),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Özet yüklenemedi',
          message: friendlyErrorMessage(error),
          actionLabel: 'Tekrar dene',
          onAction: () => ref.invalidate(dailySummaryProvider(secilenGun)),
        ),
        data: (veri) => _govde(context, veri),
      ),
    );
  }

  Widget _govde(BuildContext context, DailySummary veri) {
    // Backend TUM ogun tiplerini donuyor; bos gruplari gostermiyoruz ki
    // ekran dort bos kartla dolmasin.
    final doluGruplar = _grupBasliklari.entries
        .map((e) => (baslik: e.value, meals: veri.meals[e.key] ?? const <MealLog>[]))
        .where((g) => g.meals.isNotEmpty)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        CalorieRing(
          consumed: veri.caloriesConsumed,
          target: veri.calorieTarget,
        ),
        const SizedBox(height: 28),
        MacroBars(consumed: veri.macrosConsumed, target: veri.macrosTarget),
        const SizedBox(height: 28),
        if (doluGruplar.isEmpty)
          const EmptyState(
            icon: Icons.restaurant_outlined,
            title: 'Bugün henüz bir şey eklemedin',
            message: 'Yediklerini eklemeye başlayınca burada göreceksin.',
          )
        else
          for (final grup in doluGruplar)
            MealGroupCard(baslik: grup.baslik, meals: grup.meals),
      ],
    );
  }
}

class _TarihSecici extends ConsumerWidget {
  const _TarihSecici({required this.secilenGun});

  final String secilenGun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime bugun = DateTime.now();
    final String bugunAnahtar = gunAnahtari(bugun);
    final String dunAnahtar =
        gunAnahtari(bugun.subtract(const Duration(days: 1)));

    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: dunAnahtar, label: const Text('Dün')),
        ButtonSegment(value: bugunAnahtar, label: const Text('Bugün')),
      ],
      selected: {secilenGun},
      showSelectedIcon: false,
      onSelectionChanged: (secim) {
        ref.read(selectedDateProvider.notifier).state = secim.first;
      },
    );
  }
}