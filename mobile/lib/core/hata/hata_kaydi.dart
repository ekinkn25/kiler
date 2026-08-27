import 'package:flutter/foundation.dart';

/// Tek hata kayit noktasi (W4-T15).
///
/// NEDEN TEK NOKTA: bugun sadece konsola yaziyoruz, yarin Sentry/Crashlytics
/// eklenecegi zaman DEGISECEK TEK YER burasi olsun. Ayrica son hatalari
/// bellekte tutuyoruz: geliştirici ekranindan bakip hata ayiklayabilelim.
class HataKaydi {
  static const int _kapasite = 50;
  static final List<HataSatiri> _son = <HataSatiri>[];

  static List<HataSatiri> get sonHatalar => List.unmodifiable(_son.reversed);

  static void yaz(Object hata, StackTrace? iz, {String kaynak = 'bilinmiyor'}) {
    final satir = HataSatiri(
      an: DateTime.now(),
      kaynak: kaynak,
      mesaj: hata.toString(),
      iz: iz?.toString(),
    );
    _son.add(satir);
    if (_son.length > _kapasite) _son.removeAt(0);

    // debugPrint: cok uzun ciktiyi parcalayarak basar, Android logcat
    // satir sinirinda kesilmesini onler.
    debugPrint('[$kaynak] $hata');
    if (iz != null && kDebugMode) debugPrint(iz.toString());
  }

  static void temizle() => _son.clear();
}

@immutable
class HataSatiri {
  const HataSatiri({
    required this.an,
    required this.kaynak,
    required this.mesaj,
    this.iz,
  });

  final DateTime an;
  final String kaynak;
  final String mesaj;
  final String? iz;
}