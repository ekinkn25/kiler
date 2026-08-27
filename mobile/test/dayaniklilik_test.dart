// W4-T15 mobil dayaniklilik testleri.
//
// KABUL KRITERI A3: beklenmeyen bir istisna kirmizi ekran / cokme uretmez;
// notr bir hata karti + 'Yeniden dene' gosterilir.
//
// Ag GEREKTIRMEZ: hata yollarini yerel olarak tetikliyoruz.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/core/hata/guvenli.dart';
import 'package:kalori/core/hata/hata_kaydi.dart';
import 'package:kalori/core/network/api_exception.dart';
import 'package:kalori/models/chat_reply.dart';
import 'package:kalori/models/meal_estimate.dart';
import 'package:kalori/widgets/hata_gorunumu.dart';

void main() {
  // ================================================================
  // 1) ErrorWidget.builder - cizim coktugunde ne gorunuyor
  // ================================================================
  group('ErrorWidget.builder', () {
    testWidgets('cizim hatasi notr kart gosterir, kirmizi ekran degil', (
      tester,
    ) async {
      // DIKKAT: geri alma addTearDown'a BIRAKILAMAZ. Test cercevesi
      // ErrorWidget.builder'in degistirilmedigini test GOVDESI biter bitmez
      // dogruluyor; tearDown ondan sonra kosuyor ve test yine patliyor.
      final ErrorWidgetBuilder oncekiKurucu = ErrorWidget.builder;
      ErrorWidget.builder = (details) => HataGorunumu(details: details);

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (_) => throw StateError('bilerek firlatildi'),
            ),
          ),
        );

        // Istisna yakalandi (test cercevesi tutuyor)...
        expect(tester.takeException(), isA<StateError>());
        // ...ve yerine bizim notr govdemiz cizildi.
        expect(find.byType(HataGorunumu), findsOneWidget);
      } finally {
        ErrorWidget.builder = oncekiKurucu;
      }
    });
  });

  // ================================================================
  // 2) HataDurumu - ekranlarin ortak hata govdesi
  // ================================================================
  group('HataDurumu', () {
    testWidgets('baslik, mesaj ve yeniden dene gosterir', (tester) async {
      var tiklandi = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HataDurumu(
              hata: const ApiException(
                code: 'network_error',
                message: 'İnternet bağlantısı yok görünüyor.',
              ),
              baslik: 'Kiler yüklenemedi',
              onTekrar: () => tiklandi++,
            ),
          ),
        ),
      );

      expect(find.text('Kiler yüklenemedi'), findsOneWidget);
      expect(find.text('İnternet bağlantısı yok görünüyor.'), findsOneWidget);

      await tester.tap(find.text('Yeniden dene'));
      expect(tiklandi, 1);
    });

    testWidgets('onTekrar verilmezse buton cizilmez', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HataDurumu(hata: 'bir sey oldu'),
          ),
        ),
      );

      expect(find.text('Yeniden dene'), findsNothing);
      // Baslik verilmediginde notr varsayilan kullanilir.
      expect(find.text('Şu an bağlanamadık'), findsOneWidget);
    });
  });

  // ================================================================
  // 3) guvenliCalistir - ates-et-unut cagrilari
  // ================================================================
  group('guvenliCalistir', () {
    setUp(HataKaydi.temizle);

    test('basarili islemde sonucu aynen doner', () async {
      final sonuc = await guvenliCalistir(
        () async => 42,
        etiket: 'test.basarili',
      );
      expect(sonuc, 42);
      expect(HataKaydi.sonHatalar, isEmpty);
    });

    test('hatayi yutar, null doner ve KAYDEDER', () async {
      final sonuc = await guvenliCalistir(
        () async => throw StateError('patladi'),
        etiket: 'test.hatali',
      );

      // Cagiran taraf cokmedi...
      expect(sonuc, isNull);
      // ...ama hata sessizce KAYBOLMADI.
      expect(HataKaydi.sonHatalar, hasLength(1));
      expect(HataKaydi.sonHatalar.first.kaynak, 'test.hatali');
      expect(HataKaydi.sonHatalar.first.mesaj, contains('patladi'));
    });

    testWidgets('context verilirse kullaniciya mesaj gosterir', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => guvenliCalistir(
                  () async => throw const ApiException(
                    code: 'timeout',
                    message: 'Sunucuya ulaşılamadı.',
                  ),
                  etiket: 'test.snackbar',
                  context: context,
                  onEk: 'Kaydedilemedi:',
                ),
                child: const Text('dokun'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('dokun'));
      await tester.pump();          // async islem
      await tester.pump();          // SnackBar animasyonu

      expect(find.text('Kaydedilemedi: Sunucuya ulaşılamadı.'), findsOneWidget);
    });
  });

  // ================================================================
  // 4) HataKaydi - kapasite siniri
  // ================================================================
  group('HataKaydi', () {
    test('en fazla 50 kayit tutar, en yeni basta gelir', () {
      HataKaydi.temizle();
      for (var i = 0; i < 60; i++) {
        HataKaydi.yaz('hata-$i', StackTrace.current, kaynak: 'test');
      }

      // Sinirsiz buyuyen bir liste uzun oturumda bellegi sisirirdi.
      expect(HataKaydi.sonHatalar, hasLength(50));
      expect(HataKaydi.sonHatalar.first.mesaj, 'hata-59');
      expect(HataKaydi.sonHatalar.last.mesaj, 'hata-10');
    });
  });

  // ================================================================
  // 5) Dusus bayraginin modellere dogru oturmasi
  // ================================================================
  group('degraded alani', () {
    test('MealEstimate: gorme modeli coktugunde elle girise hazir', () {
      final tahmin = MealEstimate.fromJson(const {
        'dish_name': '',
        'portion': 'orta',
        'estimated_grams': 350,
        'calories': null,
        'portion_options': [
          {'portion': 'kucuk', 'grams': 200, 'calories': null},
          {'portion': 'orta', 'grams': 350, 'calories': null},
          {'portion': 'buyuk', 'grams': 500, 'calories': null},
        ],
        'needs_manual_entry': true,
        'degraded': true,
        'image_hash': 'abc',
      });

      expect(tahmin.degraded, isTrue);
      expect(tahmin.calories, isNull);
      // Porsiyon secenekleri dolu gelmeli: kullanici boyu degistirebilsin.
      expect(tahmin.portionOptions, hasLength(3));
    });

    test('MealEstimate: alan yoksa degraded false (eski sunucu uyumu)', () {
      final tahmin = MealEstimate.fromJson(const {
        'dish_name': 'menemen',
        'portion': 'orta',
        'estimated_grams': 300,
        'image_hash': 'abc',
      });
      expect(tahmin.degraded, isFalse);
    });

    test('ChatReply: kural tabanli yanit rozet icin isaretli gelir', () {
      final yanit = ChatReply.fromJson(const {
        'conversation_id': 7,
        'mesaj': 'Kilerine ve hedefine en yakın 3 tarifi seçtim.',
        'onerilen_tarif_idleri': ['a1', 'a2', 'a3'],
        'degraded': true,
        'degraded_reason': 'chat_timeout',
      });

      expect(yanit.degraded, isTrue);
      expect(yanit.onerilenTarifIdleri, hasLength(3));
      // Mesaj NOTR olmali: altyapi arizasi kullaniciya anlatilmaz.
      expect(yanit.mesaj.toLowerCase(), isNot(contains('hata')));
    });
  });

  // ================================================================
  // 6) friendlyErrorMessage - kullaniciya giden metin
  // ================================================================
  group('friendlyErrorMessage', () {
    test('ApiException mesajini aynen kullanir', () {
      const hata = ApiException(
        code: 'vision_timeout',
        message: 'Fotograf isleme zaman asimina ugradi.',
      );
      expect(friendlyErrorMessage(hata), 'Fotograf isleme zaman asimina ugradi.');
    });

    test('DioException icindeki ApiException cikarilir', () {
      final hata = DioException(
        requestOptions: RequestOptions(path: '/chat'),
        error: const ApiException(code: 'network_error', message: 'Bağlantı yok.'),
      );
      expect(friendlyErrorMessage(hata), 'Bağlantı yok.');
    });

    test('taninmayan hata icin notr varsayilan doner', () {
      expect(friendlyErrorMessage(StateError('x')), 'Beklenmeyen bir hata oluştu.');
    });
  });
}
