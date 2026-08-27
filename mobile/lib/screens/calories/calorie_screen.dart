import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/daily_summary.dart';
import '../../models/meal_log.dart';
import '../../providers/meal_provider.dart';
import '../../widgets/calories/calorie_ring.dart';
import '../../widgets/calories/macro_bars.dart';
import '../../widgets/calories/meal_add_flow.dart';
import '../../widgets/calories/meal_group_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/hata_gorunumu.dart';
import '../../widgets/loading_skeleton.dart';

/// KALORI sekmesi (W3-T14 + W3-T15 + W3-T16 cekirdegi).
class CalorieScreen extends ConsumerStatefulWidget {
  const CalorieScreen({super.key});

  @override
  ConsumerState<CalorieScreen> createState() => _CalorieScreenState();
}

class _CalorieScreenState extends ConsumerState<CalorieScreen> {
  static const Map<String, String> _grupBasliklari = {
    'kahvalti': 'Kahvaltı',
    'ogle': 'Öğle',
    'aksam': 'Akşam',
    'atistirma': 'Atıştırma',
  };

  Future<void> _ekle() async {
    final String gun = ref.read(selectedDateProvider);
    final eklendi = await baslatOgunEkle(context, ref, date: gun);
    if (eklendi && mounted) {
      ref.invalidate(dailySummaryProvider(gun));
      _bilgi('Öğün günlüğe eklendi.');
    }
  }

  void _bilgi(String mesaj) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mesaj), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(_ekle()),
        icon: const Icon(Icons.add),
        label: const Text('Öğün ekle'),
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
        error: (error, _) => HataDurumu(
          hata: error,
          baslik: 'Özet yüklenemedi',
          onTekrar: () => ref.invalidate(dailySummaryProvider(secilenGun)),
        ),
        data: (veri) => _govde(context, veri),
      ),
    );
  }

  Widget _govde(BuildContext context, DailySummary veri) {
    final doluGruplar = _grupBasliklari.entries
        .map((e) => (baslik: e.value, meals: veri.meals[e.key] ?? const <MealLog>[]))
        .where((g) => g.meals.isNotEmpty)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
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
            message: 'Sağ alttaki butonla öğün ekleyebilirsin.',
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

  static const List<String> _aylar = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  String _etiket(DateTime gun) {
    final DateTime bugun = DateTime.now();
    final String gunKey = gunAnahtari(gun);
    if (gunKey == gunAnahtari(bugun)) return 'Bugün';
    if (gunKey == gunAnahtari(bugun.subtract(const Duration(days: 1)))) {
      return 'Dün';
    }
    return '${gun.day} ${_aylar[gun.month - 1]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime gun = DateTime.parse(secilenGun);
    final DateTime bugun = DateTime.now();
    final bool bugunMu = gunAnahtari(gun) == gunAnahtari(bugun);

    void ayarla(DateTime yeni) {
      ref.read(selectedDateProvider.notifier).state = gunAnahtari(yeni);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Önceki gün',
          onPressed: () => ayarla(gun.subtract(const Duration(days: 1))),
        ),
        TextButton.icon(
          onPressed: () async {
            final secilen = await showDatePicker(
              context: context,
              initialDate: gun,
              firstDate: DateTime(bugun.year - 1),
              lastDate: bugun,
            );
            if (secilen != null) ayarla(secilen);
          },
          icon: const Icon(Icons.calendar_today, size: 16),
          label: Text(_etiket(gun)),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Sonraki gün',
          onPressed: bugunMu
              ? null
              : () => ayarla(gun.add(const Duration(days: 1))),
        ),
      ],
    );
  }
}