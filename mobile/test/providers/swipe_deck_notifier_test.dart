import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/core/network/dio_client.dart';
import 'package:kalori/providers/recipe_provider.dart';

/// Aga CIKMAYAN sahte adapter.
///
/// mockito/mocktail eklemiyoruz: Dio'nun HttpClientAdapter arayuzu iki
/// metottan olusuyor, elle yazmak yeni bir bagimlilik eklemekten ucuz.
class _SahteAdapter implements HttpClientAdapter {
  _SahteAdapter(this.yanitlar);

  /// Sirayla donulecek govdeler; her istek bir sonrakini tuketir.
  /// Liste bitince sonuncusu tekrar edilir.
  final List<Map<String, dynamic>> yanitlar;

  int istekSayisi = 0;
  final List<Map<String, dynamic>> gelenSorgular = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    gelenSorgular.add(Map<String, dynamic>.from(options.queryParameters));
    final govde = yanitlar[istekSayisi.clamp(0, yanitlar.length - 1)];
    istekSayisi++;
    return ResponseBody.fromString(
      jsonEncode(govde),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _kartJson(String id) => {
      'id': id,
      'title': 'Tarif $id',
      'slug': 'tarif-$id',
      'calories_per_serving': 400.0,
      'servings': 2,
      'final_score': 0.5,
      'score_breakdown': {
        'pantry': 0.5,
        'calorie': 0.5,
        'taste': 0.5,
        'time': 0.5,
        'weights': {'pantry': 0.5, 'calorie': 0.2, 'taste': 0.2, 'time': 0.1},
      },
    };

Map<String, dynamic> _desteJson({
  required int sessionId,
  required int adet,
  required int baslangic,
  bool exhausted = false,
}) =>
    {
      'session_id': sessionId,
      'items': [
        for (var i = 0; i < adet; i++) _kartJson('k${baslangic + i}'),
      ],
      'returned': adet,
      'requested': 10,
      'exhausted': exhausted,
      'session_filters': <String, dynamic>{},
    };

void main() {
  ProviderContainer kur(_SahteAdapter adapter) {
    // dioProvider'i BUTUNUYLE degistiriyoruz: gercek olan
    // AuthInterceptor uzerinden secure_storage eklentisine uzanir,
    // testte eklenti katmani yoktur.
    final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'))
      ..httpClientAdapter = adapter;
    final container = ProviderContainer(
      overrides: [dioProvider.overrideWithValue(dio)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('ilk parti kartlari ve oturum kimligini getirir', () async {
    final adapter =
        _SahteAdapter([_desteJson(sessionId: 7, adet: 10, baslangic: 0)]);
    final container = kur(adapter);

    final deste = await container.read(swipeDeckProvider.future);

    expect(deste.cards, hasLength(10));
    expect(deste.sessionId, 7);
    expect(container.read(swipeDeckProvider.notifier).sessionId, 7);
    expect(adapter.istekSayisi, 1);
    // Ilk istekte oturum kimligi HENUZ yok.
    expect(adapter.gelenSorgular.first.containsKey('session_id'), isFalse);
  });

  test('esigin ustunde on yukleme yapilmaz', () async {
    final adapter =
        _SahteAdapter([_desteJson(sessionId: 7, adet: 10, baslangic: 0)]);
    final container = kur(adapter);
    await container.read(swipeDeckProvider.future);

    await container.read(swipeDeckProvider.notifier).gerekirseOnYukle(4);

    expect(adapter.istekSayisi, 1); // ek istek YOK
  });

  test('esige inince yeni parti SONA eklenir, liste sifirlanmaz', () async {
    final adapter = _SahteAdapter([
      _desteJson(sessionId: 7, adet: 10, baslangic: 0),
      _desteJson(sessionId: 7, adet: 10, baslangic: 100),
    ]);
    final container = kur(adapter);
    final ilk = await container.read(swipeDeckProvider.future);
    expect(ilk.cards.first.id, 'k0');

    await container.read(swipeDeckProvider.notifier).gerekirseOnYukle(3);

    final sonra = container.read(swipeDeckProvider).requireValue;
    expect(adapter.istekSayisi, 2);
    expect(sonra.cards, hasLength(20));
    expect(sonra.cards.first.id, 'k0'); // eskiler duruyor
    expect(sonra.cards.last.id, 'k109'); // yeniler sona eklendi
    expect(sonra.loadingMore, isFalse);
  });

  test('ikinci istekte AYNI oturum kimligi gonderilir', () async {
    final adapter = _SahteAdapter([
      _desteJson(sessionId: 7, adet: 10, baslangic: 0),
      _desteJson(sessionId: 7, adet: 10, baslangic: 100),
    ]);
    final container = kur(adapter);
    await container.read(swipeDeckProvider.future);

    await container.read(swipeDeckProvider.notifier).gerekirseOnYukle(2);

    expect(adapter.gelenSorgular[1]['session_id'], 7);
  });

  test('on yukleme sirasinda deste EKRANDAN KAYBOLMAZ', () async {
    final adapter = _SahteAdapter([
      _desteJson(sessionId: 7, adet: 10, baslangic: 0),
      _desteJson(sessionId: 7, adet: 10, baslangic: 100),
    ]);
    final container = kur(adapter);
    await container.read(swipeDeckProvider.future);

    final durumlar = <AsyncValue<SwipeDeckState>>[];
    container.listen<AsyncValue<SwipeDeckState>>(
      swipeDeckProvider,
      (_, next) => durumlar.add(next),
    );

    await container.read(swipeDeckProvider.notifier).gerekirseOnYukle(3);

    // KABUL KRITERI: hicbir ara durumda veri kaybolmadi (loading'e
    // dusseydi SwipeDeck agactan sokulurdu).
    expect(durumlar, isNotEmpty);
    expect(durumlar.every((d) => d.hasValue), isTrue);
    // Ama 'arka planda calisiyorum' bayragi kalkip inmis olmali.
    expect(durumlar.any((d) => d.requireValue.loadingMore), isTrue);
  });

  test('exhausted iken bir daha istek atilmaz', () async {
    final adapter = _SahteAdapter([
      _desteJson(sessionId: 7, adet: 4, baslangic: 0, exhausted: true),
    ]);
    final container = kur(adapter);
    await container.read(swipeDeckProvider.future);

    await container.read(swipeDeckProvider.notifier).gerekirseOnYukle(1);

    expect(adapter.istekSayisi, 1);
  });

  test('deste bitince exhausted ise finished isaretlenir', () async {
    final adapter = _SahteAdapter([
      _desteJson(sessionId: 7, adet: 3, baslangic: 0, exhausted: true),
    ]);
    final container = kur(adapter);
    await container.read(swipeDeckProvider.future);

    final bitti = await container.read(swipeDeckProvider.notifier).desteBitti();

    expect(bitti, isTrue);
    expect(container.read(swipeDeckProvider).requireValue.finished, isTrue);
  });

  test('son karta gelinse de yeni kart varsa finished isaretlenmez',
      () async {
    final adapter = _SahteAdapter([
      _desteJson(sessionId: 7, adet: 10, baslangic: 0),
      _desteJson(sessionId: 7, adet: 10, baslangic: 100),
    ]);
    final container = kur(adapter);
    await container.read(swipeDeckProvider.future);

    final bitti = await container.read(swipeDeckProvider.notifier).desteBitti();

    final son = container.read(swipeDeckProvider).requireValue;
    expect(bitti, isFalse); // ekran swiper'i canlandiracak
    expect(son.finished, isFalse);
    expect(son.cards, hasLength(20));
  });
}