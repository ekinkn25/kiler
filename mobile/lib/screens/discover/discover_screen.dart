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
import '../../widgets/hata_gorunumu.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/swipe/dislike_reason_sheet.dart';
import '../../widgets/swipe/swipe_deck.dart';
import 'package:go_router/go_router.dart';
import '../../models/ingredient_lite.dart';
import '../../providers/shopping_provider.dart';
import '../../widgets/chat/recipe_mini_card.dart';

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
      unawaited(
        _gonder(kart: kart, action: FeedbackAction.yapacagim).then((_) {
          if (mounted) ref.invalidate(plannedProvider);
        }),
      );
    } else if (yon == CardSwiperDirection.top) {
      unawaited(_gonder(kart: kart, action: FeedbackAction.kaydetti));
    } else if (yon == CardSwiperDirection.left) {
      unawaited(_solaKaydirildi(kart, mevcutIndex ?? deste.cards.length));
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

  Future<void> _solaKaydirildi(RecipeCard kart, int gecerliIndex) async {
    // Kart ZATEN ucup gitti; soru ondan SONRA soruluyor.
    final sonuc = await showDislikeReasonDialog(context, card: kart);
    if (!mounted) return;

    final List<IngredientLite> eksikler =
        sonuc?.missingIngredients ?? const <IngredientLite>[];

    // sonuc == null -> kullanici hicbir seye dokunmadi.
    // KABUL KRITERI: bu durumda da SEBEPSIZ 'begenmedim' yazilir.
    final SwipeResult? yanit = await _gonder(
      kart: kart,
      action: FeedbackAction.begenmedim,
      reason: sonuc?.reason,
      missingIngredientIds: [for (final malzeme in eksikler) malzeme.id],
    );
    if (!mounted || yanit == null) return;

    // Oturum filtresi degistiyse ELDEKI kartlari yerel olarak suz.
    if (yanit.sessionFilters.isNotEmpty) {
      ref.read(swipeDeckProvider.notifier).filtreleriUygula(
            yanit.sessionFilters,
            gecerliIndex: gecerliIndex,
          );
    }

    // Alisveris listesine yazma, swipe kaydindan SONRA ve AYRI:
    // oncelik ogrenme sinyalinde. Liste yazimi basarisiz olsa bile geri
    // bildirim ve oturum filtresi kaybolmamali.
    if (eksikler.isNotEmpty) {
      unawaited(_alisverisListesineEkle(kart, eksikler));
    }
  }

  Future<void> _alisverisListesineEkle(
    RecipeCard kart,
    List<IngredientLite> malzemeler,
  ) async {
    try {
      final adet = await ref.read(shoppingServiceProvider).tariftenEkle(
            recipeId: kart.id,
            ingredientIds: [for (final malzeme in malzemeler) malzeme.id],
          );
      if (!mounted) return;
      // Alisveris ekrani ve tarif detayindaki 'yok' durumu ANINDA
      // guncellensin: bu servis /shopping/bulk'a yaziyor ama
      // shoppingListProvider'in onbellegine dokunmuyor.
      ref.invalidate(shoppingListProvider);
      if (adet == 0) return;
      final adlar = malzemeler.map((m) => m.displayName).join(', ');
      _bilgi('$adlar alışveriş listene eklendi.');
    } catch (hata) {
      if (!mounted) return;
      _bilgi('Alışveriş listesine eklenemedi: ${friendlyErrorMessage(hata)}');
    }
  }

  // ---------------------------------------------------------------
  // Geri bildirim
  // ---------------------------------------------------------------

  Future<SwipeResult?> _gonder({
    required RecipeCard kart,
    required FeedbackAction action,
    FeedbackReason? reason,
    List<int> missingIngredientIds = const [],
  }) async {
    final servis = ref.read(swipeFeedbackServiceProvider);
    final oturum = ref.read(swipeDeckProvider.notifier).sessionId;

    try {
      final yanit = await servis.gonder(
        recipeId: kart.id,
        action: action,
        reason: reason,
        sessionId: oturum,
        missingIngredientIds: missingIngredientIds,
      );
      // Ekran kapandiysa SnackBar gosterilemez ama yanit yine de
      // dondurulur: cagiran taraf filtreleri uygulamak isteyebilir.
      if (mounted) _bilgi(yanit.effect);
      return yanit;
    } catch (hata) {
      if (mounted) _bilgi('Kaydedilemedi: ${friendlyErrorMessage(hata)}');
      return null;
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Keşfet'),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: 'Yeni oturum başlat',
              icon: const Icon(Icons.refresh),
              onPressed: () {
                unawaited(ref.read(swipeDeckProvider.notifier).oturumuSifirla());
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(onYukleniyor ? 50 : 48),
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Bugün ne yesen?'),
                    Tab(text: 'Yapacaklarım'),
                  ],
                ),
                if (onYukleniyor) const LinearProgressIndicator(minHeight: 2),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _swipeSekmesi(deste),
            _yapacaklarimSekmesi(),
          ],
        ),
      ),
    );
  }

  Widget _swipeSekmesi(AsyncValue<SwipeDeckState> deste) {
    return deste.when(
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
      error: (error, _) => HataDurumu(
        hata: error,
        baslik: 'Deste yüklenemedi',
        onTekrar: () => ref.invalidate(swipeDeckProvider),
      ),
      data: _govde,
    );
  }

  Widget _yapacaklarimSekmesi() {
    final planned = ref.watch(plannedProvider);
    return planned.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Column(children: [LoadingSkeleton.card(), SizedBox(height: 8), LoadingSkeleton.card()]),
      ),
      error: (error, _) => HataDurumu(
        hata: error,
        baslik: 'Yapacaklarım yüklenemedi',
        onTekrar: () => ref.invalidate(plannedProvider),
      ),
      data: (liste) => liste.isEmpty
          ? const EmptyState(
              icon: Icons.playlist_add_check,
              illustrated: true,
              title: 'Henüz yapacağın tarif yok',
              message: 'Bir tarifi sağa kaydırınca ("Yapacağım") burada birikir.',
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(plannedProvider),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final tarif in liste) RecipeMiniCard(recipe: tarif),
                ],
              ),
            ),
    );
  }
  
  Widget _govde(SwipeDeckState veri) {
    // Hic kart gelmedi: kiler bos ya da filtreler cok darald.
    if (veri.cards.isEmpty) {
      return EmptyState(
        icon: Icons.restaurant_outlined,
        illustrated: true,
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
        icon: Icons.restaurant_menu,
        illustrated: true,
        title: 'Bugünlük bu kadar!',
        message: 'Kilerine bir şeyler ekle ya da yarın tekrar bak.',
        actionLabel: 'Fotoğraf çek',
        actionIcon: Icons.photo_camera_outlined,
        onAction: () => context.push('/foto'),
        secondaryActionLabel: 'Barkod okut',
        secondaryActionIcon: Icons.qr_code_scanner,
        onSecondaryAction: () => context.push('/tara'),
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