import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/deck_response.dart';
import '../models/recipe_card.dart';
import 'dart:async';
import '../models/recipe.dart';
import '../models/recipe_mini.dart';

/// Kesfet sekmesindeki destenin EKRAN durumu.
///
/// Neden DeckResponse dogrudan state olarak tutulmuyor: DeckResponse TEK
/// bir istegin yanitidir (returned/requested/exhausted o partiye aittir).
/// Deste ise BIRIKEN bir sey - arka planda gelen partiler mevcut listenin
/// SONUNA eklenir. Ikisi ayni nesne olamaz.
@immutable
class SwipeDeckState {
  const SwipeDeckState({
    required this.sessionId,
    required this.cards,
    this.exhausted = false,
    this.loadingMore = false,
    this.finished = false,
    this.sessionFilters = const {},
  });

  /// Oturum kimligi. POST /recipes/{id}/swipe govdesine gider.
  final int sessionId;

  /// Oturum basindan beri biriken kartlar. Asla kisalmaz; yalnizca
  /// filtre degistiginde (yenile) bastan kurulur.
  final List<RecipeCard> cards;

  /// Backend son partide istenen sayida kart uretemedi -> bu oturumda
  /// daha fazla kart YOK. On yuklemenin durma kosulu budur.
  final bool exhausted;

  /// Arka planda yeni parti cekiliyor. Kaydirmayi ENGELLEMEZ; ekranda
  /// yalnizca ince bir gosterge cikarir.
  final bool loadingMore;

  /// Kullanici eldeki TUM kartlari tuketti -> bos durum gosterilir.
  final bool finished;

  final Map<String, dynamic> sessionFilters;

  SwipeDeckState copyWith({
    List<RecipeCard>? cards,
    bool? exhausted,
    bool? loadingMore,
    bool? finished,
    Map<String, dynamic>? sessionFilters,
  }) {
    return SwipeDeckState(
      sessionId: sessionId,
      cards: cards ?? this.cards,
      exhausted: exhausted ?? this.exhausted,
      loadingMore: loadingMore ?? this.loadingMore,
      finished: finished ?? this.finished,
      sessionFilters: sessionFilters ?? this.sessionFilters,
    );
  }
}

/// Deste yonetimi: oturum kimligi, on yukleme, tukenme.
///
/// autoDispose DEGIL (bilincli): oturum kimligi uygulama omru boyunca
/// korunmali. autoDispose olsaydi Kesfet sekmesi bellekten dustugu anda
/// yeni oturum acilir, daha once gorulen kartlar geri gelir ve daralmis
/// filtreler ('zamani fazla' / 'malzemem yok') sifirlanirdi.
class SwipeDeckNotifier extends AsyncNotifier<SwipeDeckState> {
  /// Her istekte kac kart isteniyor.
  static const int _partiBoyutu = 10;

  /// Kac kart kalinca arka planda yeni parti istenir.
  ///
  /// 3 bilincli bir sayi: kullanici saniyede en fazla ~1 kart kaydirir,
  /// yani agin yetismesi icin ~3 saniye var. Daha kucuk esik yavas agda
  /// kartin bitmesine, daha buyugu gereksiz erken istege yol acar.
  static const int _onYuklemeEsigi = 3;

  int? _sessionId;

  /// Ayni anda iki istek gitmesini engeller: kullanici esigin altinda
  /// birkac kez daha kaydirirsa gerekirseOnYukle tekrar tekrar cagrilir.
  // bool _istekSuruyor = false;
  Future<void>? _bekleyenIstek;

  int? get sessionId => _sessionId;

  @override
  Future<SwipeDeckState> build() => _ilkParti();

  Future<SwipeDeckState> _ilkParti() async {
    final deste = await _cek();
    return SwipeDeckState(
      sessionId: deste.sessionId,
      cards: deste.items,
      exhausted: deste.exhausted,
      sessionFilters: deste.sessionFilters,
    );
  }

  Future<DeckResponse> _cek() async {
    final dio = ref.read(dioProvider);
    final response = await dio.get<Map<String, dynamic>>(
      '/recipes/deck',
      queryParameters: {
        'limit': _partiBoyutu,
        if (_sessionId != null) 'session_id': _sessionId,
      },
    );
    final deste = DeckResponse.fromJson(response.data!);
    _sessionId = deste.sessionId;
    return deste;
  }

  /// Her kaydirmadan sonra cagirilir.
  ///
  /// [kalanKart] = ustteki kart dahil, elde kalan kart sayisi.
  Future<void> gerekirseOnYukle(int kalanKart) async {
    if (kalanKart > _onYuklemeEsigi) return;
    await _dahaFazlaYukle();
  }

    Future<void> _dahaFazlaYukle() {
    return _bekleyenIstek ??= _partiCek().whenComplete(() {
      _bekleyenIstek = null;
    });
  }

  /// Yeni partiyi cekip mevcut listenin SONUNA ekler.
  Future<void> _partiCek() async {
    final mevcut = state.valueOrNull;
    if (mevcut == null || mevcut.exhausted) return;

    // DIKKAT: state = AsyncLoading() YOK.
    // Ekranda kart varken loading'e dusmek SwipeDeck'i widget agacindan
    // sokerdi; CardSwiper'in State'i yok olur ve kullanicinin parmagi
    // kartin uzerindeyken kaydirma jesti ortada kesilirdi.
    state = AsyncData(mevcut.copyWith(loadingMore: true));

    try {
      final yeni = await _cek();
      final oncekiler = state.valueOrNull ?? mevcut;
      state = AsyncData(
        oncekiler.copyWith(
          cards: [...oncekiler.cards, ...yeni.items],
          exhausted: yeni.exhausted,
          loadingMore: false,
        ),
      );
    } catch (_) {
      // On yukleme SESSIZ basarisiz olur: kullanici hala eldeki kartlari
      // kaydirabiliyor, ekrana hata basmak akisi bozardi.
      final oncekiler = state.valueOrNull ?? mevcut;
      state = AsyncData(oncekiler.copyWith(loadingMore: false));
    }
  }

  /// Oturum filtresi degistiginde ELDEKI kartlari YEREL olarak suzer.
  ///
  /// Neden yeni deste istemiyoruz: backend, desteyi dondugu ANDA butun
  /// kartlari 'gordu' isaretliyor (mark_shown). Yeniden istemek,
  /// kullanicinin hic gormedigi kartlari KALICI olarak cope atmak
  /// demek - filtreye uyanlar dahil. Onceki surumde 'zamani fazla'
  /// dendiginde elde 8 kart varken deste bir anda bosaliyor ve
  /// cikissiz bos ekrana dusuluyordu.
  ///
  /// [gecerliIndex] o an ustte duran kartin indeksi. Ondan ONCEKI
  /// kartlar (zaten kaydirilmis olanlar) listeden dusurulur; boylece
  /// CardSwiper'in anahtari degisir ve swiper sifirdan baslar.
  void filtreleriUygula(
    Map<String, dynamic> filtreler, {
    required int gecerliIndex,
  }) {
    final mevcut = state.valueOrNull;
    if (mevcut == null) return;

    final int? sureTavani = (filtreler['max_total_time'] as num?)?.toInt();
    final Set<String> olmayanlar =
        ((filtreler['missing_ingredients'] as List<dynamic>?) ?? const [])
            .cast<String>()
            .toSet();

    if (sureTavani == null && olmayanlar.isEmpty) return;

    final int baslangic = gecerliIndex.clamp(0, mevcut.cards.length);
    final List<RecipeCard> kalan = mevcut.cards
        .sublist(baslangic)
        .where((kart) => _filtreyeUyuyor(kart, sureTavani, olmayanlar))
        .toList();

    state = AsyncData(
      mevcut.copyWith(
        cards: kalan,
        sessionFilters: filtreler,
        finished: false,
      ),
    );

    // Suzgecten az kart gectiyse arka planda takviye iste.
    unawaited(gerekirseOnYukle(kalan.length));
  }

  bool _filtreyeUyuyor(
    RecipeCard kart,
    int? sureTavani,
    Set<String> olmayanlar,
  ) {
    if (sureTavani != null) {
      final int sure = (kart.prepTime ?? 0) + (kart.cookTime ?? 0);
      if (sure > sureTavani) return false;
    }
    if (olmayanlar.isNotEmpty) {
      // matched + unknown + missing = tarifin ZORUNLU malzeme kumesi.
      // Backend skorlamada da tam bu kumeyi kullaniyor (_zorunlu).
      final Set<String> gerekli = {
        ...kart.matchedIngredients,
        ...kart.unknownIngredients,
        ...kart.missingIngredients,
      };
      if (gerekli.intersection(olmayanlar).isNotEmpty) return false;
    }
    return true;
  }

  

  /// Kullanici SON karti da kaydirdi.
  ///
  /// Buraya normalde HIC gelinmemeli - on yukleme 3 kart kala devreye
  /// girdigi icin deste kullanici yetismeden buyur. Gelinmisse ya
  /// backend'de kart kalmamistir ya da ag cok yavastir.
  ///
  /// Doner: deste GERCEKTEN bitti mi (false ise ekran swiper'i
  /// canlandirmali - paket son karttan sonra kendini kilitler).
  Future<bool> desteBitti() async {
    final mevcut = state.valueOrNull;
    if (mevcut == null) return true;

    if (!mevcut.exhausted) {
      final int oncekiSayi = mevcut.cards.length;
      await _dahaFazlaYukle();
      final sonra = state.valueOrNull;
      if (sonra != null && sonra.cards.length > oncekiSayi) return false;
    }

    state = AsyncData((state.valueOrNull ?? mevcut).copyWith(finished: true));
    return true;
  }

  /// Desteyi AYNI oturumla BASTAN kurar.
  ///
  /// Oturum filtresi degistiginde ('zamani fazla' / 'malzemem yok')
  /// cagirilir: eldeki kartlar artik gecersizdir, uzerine EKLEMEK yanlis
  /// olur. Burada loading'e dusmek DOGRU - kullanici az once bir soruya
  /// cevap verdi, kisa bir iskelet 'filtreni uyguluyorum' demektir.
  Future<void> yenile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_ilkParti);
  }

  /// Oturumu SIFIRDAN baslatir; daralmis filtreler de sifirlanir.
  Future<void> oturumuSifirla() async {
    _sessionId = null;
    await yenile();
  }
}

final swipeDeckProvider =
    AsyncNotifierProvider<SwipeDeckNotifier, SwipeDeckState>(
  SwipeDeckNotifier.new,
);

// ==================================================================
// Tarif detayi ve Yapacaklarim (W4-T01)
// ==================================================================
/// Tam tarif detayi. GET /recipes/{id}.
final recipeDetailProvider =
    FutureProvider.autoDispose.family<Recipe, String>((ref, id) async {
  ref.keepAlive(); // detaydan cikip girince tekrar cekilmesin
  final dio = ref.read(dioProvider);
  final response = await dio.get<Map<String, dynamic>>('/recipes/$id');
  return Recipe.fromJson(response.data!);
});

/// 'Yapacaklarim' listesi. GET /recipes/planned.
final plannedProvider =
    FutureProvider.autoDispose<List<RecipeMini>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get<List<dynamic>>('/recipes/planned');
  return response.data!
      .map((e) => RecipeMini.fromJson(e as Map<String, dynamic>))
      .toList();
});