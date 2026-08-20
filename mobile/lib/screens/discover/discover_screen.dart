import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../models/enums.dart';
import '../../models/recipe_card.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/swipe_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/swipe/dislike_reason_sheet.dart';
import '../../widgets/swipe/swipe_deck.dart';

/// KESFET sekmesi: 'Bugun ne yesen?' + swipe destesi.
///
/// Bu ekran SADECE destenin GORUNTULENMESINDEN sorumlu (W3-T06). Kaydirma
/// yonune gore etiket/geri bildirim gonderme W3-T07'de eklenecek.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}
  class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  /// Kaydirma ANINDA true doner (kart ucar), POST arka planda gider.
  /// Kullaniciyi agin hizina mahkum etmemek icin bilincli bir tercih:
  /// burada await edilseydi her kaydirmada kart havada donardi.
  Future<bool> _kaydirildi(RecipeCard kart, CardSwiperDirection yon) async {
    if (yon == CardSwiperDirection.right) {
      unawaited(_gonder(kart: kart, action: FeedbackAction.yapacagim));
    } else if (yon == CardSwiperDirection.top) {
      unawaited(_gonder(kart: kart, action: FeedbackAction.kaydetti));
    } else if (yon == CardSwiperDirection.left) {
      unawaited(_solaKaydirildi(kart));
    }
    return true;
  }

  Future<void> _solaKaydirildi(RecipeCard kart) async {
    // Kart ZATEN ucup gitti; soru ondan SONRA soruluyor.
    final sonuc = await showDislikeReasonDialog(context, card: kart);
    if (!mounted) return;

    // sonuc == null -> kullanici hicbir seye dokunmadi.
    // KABUL KRITERI: bu durumda da SEBEPSIZ 'begenmedim' yazilir.
    await _gonder(
      kart: kart,
      action: FeedbackAction.begenmedim,
      reason: sonuc?.reason,
      missingIngredientId: sonuc?.missingIngredientId,
    );

    // Bu iki sebep OTURUM FILTRESINI degistirir: elimizdeki kartlar artik
    // gecersiz olabilir (uzun sureli ya da o malzemeyi iceren kartlar),
    // desteyi AYNI oturumla yeniden kur.
    final bool filtreDegisti = sonuc?.reason == FeedbackReason.cokUzun ||
        (sonuc?.reason == FeedbackReason.malzemeYok &&
            sonuc?.missingIngredientId != null);

    if (filtreDegisti && mounted) {
      await ref.read(swipeDeckProvider.notifier).yenile();
    }
  }

  Future<void> _gonder({
    required RecipeCard kart,
    required FeedbackAction action,
    FeedbackReason? reason,
    int? missingIngredientId,
  }) async {
    final servis = ref.read(swipeFeedbackServiceProvider);
    final oturum = ref.read(swipeDeckProvider.notifier).sessionId;

    try {
      final etki = await servis.gonder(
        recipeId: kart.id,
        action: action,
        reason: reason,
        sessionId: oturum,
        missingIngredientId: missingIngredientId,
      );
      if (!mounted) return;
      _bilgi(etki);
    } catch (hata) {
      if (!mounted) return;
      _bilgi('Kaydedilemedi: ${friendlyErrorMessage(hata)}');
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
    final deste = ref.watch(swipeDeckProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bugün ne yesen?'), centerTitle: false),
      body: deste.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              LoadingSkeleton.card(),
              SizedBox(height: 12),
              LoadingSkeleton.card(),
            ],
          ),
        ),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Deste yüklenemedi',
          message: friendlyErrorMessage(error),
          actionLabel: 'Tekrar dene',
          onAction: () => ref.invalidate(swipeDeckProvider),
        ),
        data: (veri) => veri.items.isEmpty
            ? EmptyState(
                icon: Icons.restaurant_outlined,
                title: 'Şu an önerilecek tarif yok',
                message: veri.sessionFilters.isEmpty
                    ? 'Kilerine malzeme ekleyince öneriler burada görünecek.'
                    : 'Filtreler iyice daraldı. Sıfırlayıp yeniden bakalım mı?',
                actionLabel: 'Filtreleri sıfırla',
                onAction: () {
                  unawaited(ref.read(swipeDeckProvider.notifier).oturumuSifirla());
                },
              )
            : SwipeDeck(
                // Deste yenilendiginde CardSwiper'in IC SAYACI sifirlansin;
                // yoksa eski indeks yeni (kisa) listede tasabilir.
                key: ValueKey('deste-${veri.items.first.id}'),
                cards: veri.items,
                onSwipe: (previousIndex, currentIndex, direction) =>
                    _kaydirildi(veri.items[previousIndex], direction),
                onEnd: () => ref.read(swipeDeckProvider.notifier).yenile(),
              ),
      ),
    );
  }
}