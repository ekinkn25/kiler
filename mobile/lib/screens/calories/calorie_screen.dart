import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_exception.dart';
import '../../models/daily_summary.dart';
import '../../models/meal_log.dart';
import '../../providers/meal_provider.dart';
import '../../widgets/calories/calorie_ring.dart';
import '../../widgets/calories/macro_bars.dart';
import '../../widgets/calories/meal_confirm_sheet.dart';
import '../../widgets/calories/meal_group_card.dart';
import '../../widgets/chat/shot_guide.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';

/// KALORI sekmesi (W3-T14 + W3-T15).
///
/// Ogun ekleme: su an YALNIZCA fotograf yolu (T15). Barkod/arama yollari
/// W3-T16'da eklenecek; o zaman FAB uc secenekli bir alt sayfa acacak.
class CalorieScreen extends ConsumerStatefulWidget {
  const CalorieScreen({super.key});

  @override
  ConsumerState<CalorieScreen> createState() => _CalorieScreenState();
}

class _CalorieScreenState extends ConsumerState<CalorieScreen> {
  final ImagePicker _secici = ImagePicker();
  bool _tahminAliniyor = false;

  static const Map<String, String> _grupBasliklari = {
    'kahvalti': 'Kahvaltı',
    'ogle': 'Öğle',
    'aksam': 'Akşam',
    'atistirma': 'Atıştırma',
  };

  // ---------------------------------------------------------------
  // Fotografla ogun ekleme (W3-T15)
  // ---------------------------------------------------------------

  Future<void> _fotograflaEkle() async {
    final kaynak = await _kaynakSec();
    if (kaynak == null) return;

    try {
      final XFile? secilen = await _secici.pickImage(
        source: kaynak,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (secilen == null || !mounted) return;

      setState(() => _tahminAliniyor = true);
      final tahmin =
          await ref.read(mealPhotoServiceProvider).tahminEt(File(secilen.path));
      if (!mounted) return;
      setState(() => _tahminAliniyor = false);

      final String gun = ref.read(selectedDateProvider);
      final eklendi =
          await showMealConfirmSheet(context, tahmin: tahmin, date: gun);
      if (eklendi == true && mounted) {
        // Halka ve barlar aninda guncellensin.
        ref.invalidate(dailySummaryProvider(gun));
        _bilgi('${tahmin.dishName} günlüğe eklendi.');
      }
    } catch (hata) {
      if (!mounted) return;
      setState(() => _tahminAliniyor = false);
      _bilgi('Fotoğraf işlenemedi: ${friendlyErrorMessage(hata)}');
    }
  }

  Future<ImageSource?> _kaynakSec() {
    FocusScope.of(context).unfocus();
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 4),
              child: ShotGuide(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                'Tabağın yanına çatal veya bıçak koy — porsiyonu böylece '
                'daha doğru tahmin edebiliyoruz',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Kamera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden seç'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _bilgi(String mesaj) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mesaj), duration: const Duration(seconds: 2)),
      );
  }

  // ---------------------------------------------------------------
  // Gorunum
  // ---------------------------------------------------------------

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
        onPressed: _tahminAliniyor ? null : () => unawaited(_fotograflaEkle()),
        icon: _tahminAliniyor
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Icon(Icons.photo_camera_outlined),
        label: Text(_tahminAliniyor ? 'İşleniyor...' : 'Öğün ekle'),
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
    final doluGruplar = _grupBasliklari.entries
        .map((e) => (baslik: e.value, meals: veri.meals[e.key] ?? const <MealLog>[]))
        .where((g) => g.meals.isNotEmpty)
        .toList();

    return ListView(
      // FAB'in altta icerigi ortmemesi icin ekstra bosluk.
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
            message: 'Sağ alttaki butonla fotoğraftan öğün ekleyebilirsin.',
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