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
/// Yon -> aksiyon esleme (W3-T07):
///   SAG    -> yapacagim
///   YUKARI -> kaydetti ('sonra')
///   SOL    -> begenmedim (+ bulanik ekranda secilen sebep)
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  /// Desteyi disaridan surmek icin. TEK kullanim yeri: son kart
  /// kaydirildiktan SONRA yeni parti gelirse swiper'i canlandirmak
  /// (bkz. [_desteBitti]).
  final CardSwiperController _kumanda = CardSwiperController();

  @override
  void dispose() {
    unawaited(_kumanda.dispose());
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Kaydirma
  // ---------------------------------------------------------------

  /// Kaydirma ANINDA true doner (kart ucar), POST arka planda gider.
  /// Kullaniciyi agin hizina mahkum etmemek icin bilincli tercih:
  /// burada await edilseydi her kaydirmada kart havada donardi.
  Future<bool> _kaydirildi(
    SwipeDeckState deste,
    int oncekiIndex,
    int? mevcutIndex,
    CardSwiperDirection yon,
  ) async {
    final RecipeCard kart = deste.cards[oncekiIndex];

    if (yon == CardSwiperDirection.right) {
      unawaited(_gonder(kart: kart, action: FeedbackAction.yapacagim));
    } else if (yon == CardSwiperDirection.top) {
      unawaited(_gonder(kart: kart, action: FeedbackAction.kaydetti));
    } else if (yon == CardSwiperDirection.left) {
      unawaited(_solaKaydirildi(kart));
    }

    // ON YUKLEME TETIGI (W3-T08).
    // await EDILMIYOR: kaydirma animasyonunun agi beklemesi gereksiz;
    // istek arka planda kosar, kullanici kaydirmaya devam eder.
    if (mevcutIndex != null) {
      final int kalan = deste.cards.length - mevcutIndex;
      unawaited(ref.read(swipeDeckProvider.notifier).gerekirseOnYukle(kalan));
    }

    return true;
  }

  /// Son kart da kaydirildi.
  ///
  /// [eskiUzunluk] son kart kaydirilmadan onceki kart sayisi = yeni
  /// gelecek ilk kartin indeksi.
  Future<void> _desteBitti(int eskiUzunluk) async {
    final bool bitti = await ref.read(swipeDeckProvider.notifier).desteBitti();
    if (bitti || !mounted) return;

    // Yeni kartlar geldi ama CardSwiper 'olu' kaldi: paket dongusuz
    // modda son karttan sonra ic indeksini null yapiyor ve cardsCount
    // buyuse bile kendiliginden canlanmiyor. Yeni gelen ilk karta elle
    // atliyoruz.
    //
    // addPostFrameCallback SART: moveTo, indeksi widget.cardsCount ile
    // dogruluyor; once yeni sayinin agaca islenmesi gerekiyor.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _kumanda.moveTo(eskiUzunluk);
    });
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
    // desteyi AYNI oturumla bastan kur.
    final bool filtreDegisti = sonuc?.reason == FeedbackReason.cokUzun ||
        (sonuc?.reason == FeedbackReason.malzemeYok &&
            sonuc?.missingIngredientId != null);

    if (filtreDegisti && mounted) {
      await ref.read(swipeDeckProvider.notifier).yenile();
    }
  }

  // ---------------------------------------------------------------
  // Geri bildirim
  // ---------------------------------------------------------------

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

  // ---------------------------------------------------------------
  // Gorunum
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final deste = ref.watch(swipeDeckProvider);
    final bool onYukleniyor = deste.valueOrNull?.loadingMore ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bugün ne yesen?'),
        centerTitle: false,
        // On yukleme gostergesi: 2 piksel, kaydirmayi ENGELLEMEZ.
        // Kullanici fark etmese de olur - amac gelistirici icin
        // gorunurluk ve yavas agda 'donmadi, calisiyor' hissi.
        bottom: onYukleniyor
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
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
        data: _govde,
      ),
    );
  }

  Widget _govde(SwipeDeckState veri) {
    // Hic kart gelmedi: kiler bos ya da filtreler cok darald.
    if (veri.cards.isEmpty) {
      return EmptyState(
        icon: Icons.restaurant_outlined,
        title: 'Şu an önerilecek tarif yok',
        message: veri.sessionFilters.isEmpty
            ? 'Kilerine malzeme ekleyince öneriler burada görünecek.'
            : 'Filtreler iyice daraldı. Sıfırlayıp yeniden bakalım mı?',
        actionLabel: 'Filtreleri sıfırla',
        onAction: () {
          unawaited(ref.read(swipeDeckProvider.notifier).oturumuSifirla());
        },
      );
    }

    // Kullanici hepsini tuketti.
    // GECICI: buyuk gorsel + iki butonlu (Fotograf cek / Barkod okut)
    // tasarim W3-T08'in kalan maddelerinde yazilacak.
    if (veri.finished) {
      return EmptyState(
        icon: Icons.check_circle_outline,
        title: 'Bugünlük bu kadar!',
        message: 'Kilerine bir şeyler ekle ya da yarın tekrar bak.',
        actionLabel: 'Baştan bak',
        onAction: () {
          unawaited(ref.read(swipeDeckProvider.notifier).oturumuSifirla());
        },
      );
    }

    return SwipeDeck(
      // Anahtar ilk kartin kimligine bagli: on yukleme SONA ekleme
      // yaptigi icin ilk kart degismez -> CardSwiper'in State'i ve ic
      // indeksi KORUNUR. yenile()/oturumuSifirla() listeyi bastan
      // kurunca ilk kart degisir -> swiper sifirdan baslar. Tam istenen.
      key: ValueKey('deste-${veri.cards.first.id}'),
      controller: _kumanda,
      cards: veri.cards,
      onSwipe: (oncekiIndex, mevcutIndex, yon) =>
          _kaydirildi(veri, oncekiIndex, mevcutIndex, yon),
      onEnd: () => _desteBitti(veri.cards.length),
    );
  }
}