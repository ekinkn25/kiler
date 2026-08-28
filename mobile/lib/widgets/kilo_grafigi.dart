import 'package:flutter/material.dart';

import '../models/kilo_kaydi.dart';

/// Kilo gecmisi cizgi grafigi.
///
/// NEDEN PAKET DEGIL (fl_chart vb.): ihtiyacimiz TEK bir cizgi. Bunun icin
/// yuz kilobaytlik bir grafik kutuphanesi eklemek, uygulamaya baska hicbir
/// yerde kullanilmayacak bir bagimlilik ve bir surum bakim yuku bindirirdi.
/// CustomPainter zaten Flutter'in icinde.
///
/// X EKSENI GUNE GORE: noktalar dizideki SIRAYA gore degil, GERCEK TARIH
/// farkina gore yerlestiriliyor. Kullanici bir ay tartilmadiysa grafikte
/// o bosluk gorunmeli - aksi halde duzenli olcuyormus gibi yanlis bir
/// izlenim olusur.
class KiloGrafigi extends StatelessWidget {
  const KiloGrafigi({required this.kayitlar, this.yukseklik = 190, super.key});

  final List<KiloKaydi> kayitlar;
  final double yukseklik;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;

    return SizedBox(
      height: yukseklik,
      width: double.infinity,
      child: CustomPaint(
        painter: _KiloBoyaci(
          kayitlar: kayitlar,
          cizgi: renkler.primary,
          nokta: renkler.surface,
          izgara: renkler.outlineVariant,
          yazi: renkler.onSurfaceVariant,
          // Alan dolgusu: cizginin altini yumusak bir gecisle boyar.
          // Tek basina cizgiden daha okunakli, cunku goz yonelimi alandan
          // daha hizli aliyor.
          dolgu: renkler.primary.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}

class _KiloBoyaci extends CustomPainter {
  const _KiloBoyaci({
    required this.kayitlar,
    required this.cizgi,
    required this.dolgu,
    required this.nokta,
    required this.izgara,
    required this.yazi,
  });

  final List<KiloKaydi> kayitlar;
  final Color cizgi;
  final Color dolgu;
  final Color nokta;
  final Color izgara;
  final Color yazi;

  static const double _sol = 42;   // y ekseni etiketleri
  static const double _sag = 10;
  static const double _ust = 10;
  static const double _alt = 22;   // tarih etiketleri

  @override
  void paint(Canvas canvas, Size size) {
    if (kayitlar.isEmpty) return;

    final double genislik = size.width - _sol - _sag;
    final double yukseklik = size.height - _ust - _alt;
    if (genislik <= 0 || yukseklik <= 0) return;

    // ---------------- olcek ----------------
    final kilolar = kayitlar.map((k) => k.kiloKg).toList();
    double enAz = kilolar.reduce((a, b) => a < b ? a : b);
    double enCok = kilolar.reduce((a, b) => a > b ? a : b);

    // Tek kayit ya da hic degismemis kilo: aralik sifir olurdu ve tum
    // noktalar ust kenara yapisirdi. Yapay olarak +-1 kg aciyoruz.
    if (enCok - enAz < 0.5) {
      enAz -= 1;
      enCok += 1;
    } else {
      final pay = (enCok - enAz) * 0.15;
      enAz -= pay;
      enCok += pay;
    }

    final ilkGun = kayitlar.first.gun;
    final toplamGun = kayitlar.last.gun.difference(ilkGun).inDays;

    double x(KiloKaydi k) {
      if (toplamGun <= 0) return _sol + genislik / 2;
      return _sol + (k.gun.difference(ilkGun).inDays / toplamGun) * genislik;
    }

    double y(double kilo) =>
        _ust + (1 - (kilo - enAz) / (enCok - enAz)) * yukseklik;

    // ---------------- izgara + y etiketleri ----------------
    final izgaraFircasi = Paint()
      ..color = izgara
      ..strokeWidth = 1;

    for (var i = 0; i <= 2; i++) {
      final deger = enCok - (enCok - enAz) * i / 2;
      final cy = y(deger);
      canvas.drawLine(Offset(_sol, cy), Offset(size.width - _sag, cy), izgaraFircasi);
      _yaz(canvas, deger.toStringAsFixed(1), Offset(_sol - 6, cy - 6), sagaYasli: true);
    }

    // ---------------- alan + cizgi ----------------
    final noktalar = [for (final k in kayitlar) Offset(x(k), y(k.kiloKg))];

    if (noktalar.length > 1) {
      final alan = Path()..moveTo(noktalar.first.dx, _ust + yukseklik);
      for (final n in noktalar) {
        alan.lineTo(n.dx, n.dy);
      }
      alan
        ..lineTo(noktalar.last.dx, _ust + yukseklik)
        ..close();
      canvas.drawPath(alan, Paint()..color = dolgu);

      final yol = Path()..moveTo(noktalar.first.dx, noktalar.first.dy);
      for (final n in noktalar.skip(1)) {
        yol.lineTo(n.dx, n.dy);
      }
      canvas.drawPath(
        yol,
        Paint()
          ..color = cizgi
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          // round: kirilma noktalarinda sivri koseler olusmasin.
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    // ---------------- noktalar ----------------
    // Cok kayitta her noktayi cizmek gorseli kirletiyor; ilk, son ve
    // (az sayidaysa) aradakiler isaretleniyor.
    final iciFircasi = Paint()..color = nokta;
    final kenarFircasi = Paint()
      ..color = cizgi
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final gosterilecek = noktalar.length <= 20
        ? noktalar
        : [noktalar.first, noktalar.last];

    for (final n in gosterilecek) {
      canvas.drawCircle(n, 4, iciFircasi);
      canvas.drawCircle(n, 4, kenarFircasi);
    }

    // ---------------- tarih etiketleri ----------------
    final altY = size.height - _alt + 4;
    _yaz(canvas, _kisaTarih(kayitlar.first.gun), Offset(_sol, altY));
    if (toplamGun > 0) {
      _yaz(
        canvas,
        _kisaTarih(kayitlar.last.gun),
        Offset(size.width - _sag, altY),
        sagaYasli: true,
      );
    }
  }

  void _yaz(Canvas canvas, String metin, Offset konum, {bool sagaYasli = false}) {
    final boyaci = TextPainter(
      text: TextSpan(
        text: metin,
        style: TextStyle(color: yazi, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    boyaci.paint(
      canvas,
      sagaYasli ? Offset(konum.dx - boyaci.width, konum.dy) : konum,
    );
  }

  static String _kisaTarih(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}';

  @override
  bool shouldRepaint(_KiloBoyaci eski) {
    // Kayit listesi degismediyse yeniden cizmek bosuna is. Uzunluk ve son
    // kaydin degeri pratikte yeterli bir imza; tema degisiminde renk
    // karsilastirmasi devreye giriyor.
    if (eski.kayitlar.length != kayitlar.length || eski.cizgi != cizgi) {
      return true;
    }
    if (kayitlar.isEmpty) return false;
    return eski.kayitlar.last.kiloKg != kayitlar.last.kiloKg;
  }
}
