import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/core/theme/tema_provider.dart';

void main() {
  test('kodla ve coz birbirinin tersi', () {
    for (final mod in ThemeMode.values) {
      expect(temaModuCoz(temaModuKodla(mod)), mod);
    }
  });

  test('bilinmeyen deger sisteme duser', () {
    // Diskteki deger bozulursa veya eski bir surumden kalirsa uygulama
    // acilmali; ArgumentError firlatan bir cozum splash ekraninda
    // kilitlenirdi.
    expect(temaModuCoz(null), ThemeMode.system);
    expect(temaModuCoz(''), ThemeMode.system);
    expect(temaModuCoz('mavi'), ThemeMode.system);
  });

  test('disk anahtarlari enum adlarindan BAGIMSIZ', () {
    // Anahtarlar degisirse kayitli tercihler anlamsizlasir; bu test
    // onlari sabitliyor.
    expect(temaModuKodla(ThemeMode.light), 'acik');
    expect(temaModuKodla(ThemeMode.dark), 'koyu');
    expect(temaModuKodla(ThemeMode.system), 'sistem');
  });

  test('her mod icin etiket ve ikon tanimli', () {
    for (final mod in ThemeMode.values) {
      expect(mod.etiket, isNotEmpty);
      expect(mod.aciklama, isNotEmpty);
    }
  });
}
