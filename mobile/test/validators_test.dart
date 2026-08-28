import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/core/validators.dart';

void main() {
  group('kiloValidator', () {
    test('bos deger reddedilir', () {
      expect(kiloValidator(''), isNotNull);
      expect(kiloValidator(null), isNotNull);
    });

    test('sayi olmayan metin reddedilir', () {
      expect(kiloValidator('yetmiş'), isNotNull);
    });

    test('backend siniri disi degerler reddedilir', () {
      // Backend Field(gt=20, lt=400); istemci ayni sinirlari tutuyor ki
      // kullanici 422 yerine anlasilir bir cumle gorsun.
      expect(kiloValidator('20'), isNotNull);
      expect(kiloValidator('400'), isNotNull);
      expect(kiloValidator('-5'), isNotNull);
    });

    test('gecerli degerler kabul edilir', () {
      expect(kiloValidator('78.5'), isNull);
      expect(kiloValidator('  80  '), isNull);
    });

    test('virgullu ondalik kabul edilir', () {
      // Turkce klavyede ondalik ayraci VIRGUL. Reddedilseydi kullanici
      // neden kaydedemedigini anlamazdi.
      expect(kiloValidator('78,5'), isNull);
    });
  });

  group('boyValidator', () {
    test('sinirlar backend ile ayni', () {
      expect(boyValidator('50'), isNotNull);
      expect(boyValidator('260'), isNotNull);
      expect(boyValidator('180'), isNull);
    });
  });

  group('ondalikCoz', () {
    test('virgul noktaya cevrilir', () {
      expect(ondalikCoz('78,5'), 78.5);
      expect(ondalikCoz('78.5'), 78.5);
    });

    test('cozulemeyen metinde null', () {
      expect(ondalikCoz('abc'), isNull);
      expect(ondalikCoz(null), isNull);
    });
  });
}
