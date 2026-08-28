import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../hata/hata_kaydi.dart';
import '../storage/secure_storage.dart';

/// Kullanicinin tema tercihi. MaterialApp.themeMode'u besler.
///
/// NEDEN AsyncNotifier DEGIL: tercih okumasi diskten milisaniyeler suruyor
/// ve uygulama o sirada TEMASIZ kalamaz. Bu yuzden build() aninda
/// 'sistem' donuluyor, kayitli deger arkadan gelince state guncelleniyor.
/// Pratikte ilk kareden sonra oturuyor; AsyncNotifier olsaydi butun
/// MaterialApp'i bir yukleme durumuna sarmak gerekirdi.
class TemaNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    unawaited(_yukle());
    return ThemeMode.system;
  }

  Future<void> _yukle() async {
    try {
      final kayitli = await ref.read(secureStorageProvider).temaModu;
      state = temaModuCoz(kayitli);
    } catch (hata, iz) {
      // Tema okunamadi diye uygulama acilmamazlik etmesin: sistem temasi
      // zaten gecerli varsayilan.
      HataKaydi.yaz(hata, iz, kaynak: 'tema.yukle');
    }
  }

  Future<void> ayarla(ThemeMode mod) async {
    if (mod == state) return;
    // ONCE ekran degissin: kullanici dokunusun karsiligini aninda gorsun,
    // diske yazma islemi arkadan tamamlansin.
    state = mod;
    try {
      await ref.read(secureStorageProvider).temaModuYaz(temaModuKodla(mod));
    } catch (hata, iz) {
      // Yazma basarisiz olduysa tema bu oturumda calisir, sonrakinde
      // varsayilana doner. Kullaniciya hata gostermeye degmez.
      HataKaydi.yaz(hata, iz, kaynak: 'tema.kaydet');
    }
  }
}

final temaProvider = NotifierProvider<TemaNotifier, ThemeMode>(TemaNotifier.new);

// ------------------------------------------------------------------ kodlama
// Depoda ThemeMode.name ('light'/'dark'/'system') yerine kendi
// anahtarlarimiz duruyor: enum adlarini degistirirsek diskteki eski
// degerler anlamsizlasmasin.

String temaModuKodla(ThemeMode mod) => switch (mod) {
  ThemeMode.light => 'acik',
  ThemeMode.dark => 'koyu',
  ThemeMode.system => 'sistem',
};

/// Bilinmeyen/bozuk deger -> sistem. COKMEZ.
ThemeMode temaModuCoz(String? deger) => switch (deger) {
  'acik' => ThemeMode.light,
  'koyu' => ThemeMode.dark,
  _ => ThemeMode.system,
};

extension TemaModuGosterim on ThemeMode {
  String get etiket => switch (this) {
    ThemeMode.light => 'Açık',
    ThemeMode.dark => 'Koyu',
    ThemeMode.system => 'Sistem',
  };

  String get aciklama => switch (this) {
    ThemeMode.light => 'Her zaman açık tema',
    ThemeMode.dark => 'Her zaman koyu tema',
    ThemeMode.system => 'Telefonunun ayarını izler',
  };

  IconData get ikon => switch (this) {
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
    ThemeMode.system => Icons.brightness_auto_outlined,
  };
}
