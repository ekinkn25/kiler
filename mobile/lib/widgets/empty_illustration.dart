import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Bos durum ekranlarinin BUYUK GORSELI.
///
/// Neden hazir bir resim dosyasi degil:
///   - projede assets/ klasoru ve tasarim varligi yok; pubspec'teki
///     assets bolumu hic acilmamis,
///   - raster gorsel tek renk semasina baglidir, acik/koyu temada ya
///     soluk ya patlak durur,
///   - flutter_svg eklemek tek bir ekran icin yeni bagimlilik demek.
///
/// Bu yuzden gorsel CANVAS'A CIZILIYOR: tema renklerini okur, her
/// olcude keskin kalir, uygulama boyutunu buyutmez, internet istemez.
///
/// Ileride gercek bir illustrasyon gelirse YALNIZCA bu dosya degisir;
/// cagiran ekranlar etkilenmez.
class EmptyIllustration extends StatelessWidget {
  const EmptyIllustration({
    required this.icon,
    super.key,
    this.size = 180,
    this.color,
  });

  /// Ortadaki sembol. Bos durumun KONUSUNU anlatir:
  /// tarif -> restaurant_menu, kiler -> kitchen, ogun -> local_fire_department.
  final IconData icon;

  /// Gorselin kenar uzunlugu (kare cizim alani).
  final double size;

  /// Ana renk. Verilmezse temanin primary'si kullanilir; boylece acik ve
  /// koyu temada kendiliginden dogru kontrasta oturur.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color anaRenk = color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      // RepaintBoundary: cizim STATIK. Cevresindeki metin/butonlar
      // degistiginde tabagin yeniden cizilmesine gerek yok.
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _TabakPainter(anaRenk),
          // CustomPaint once painter'i, SONRA child'i cizer -> ikon
          // tabagin ustunde kalir.
          child: Center(
            child: Icon(icon, size: size * 0.34, color: anaRenk),
          ),
        ),
      ),
    );
  }
}

/// Bos tabak cizimi.
///
/// Tum olculer yaricapin ORANI olarak yazildi (r * 0.78 gibi); boylece
/// [EmptyIllustration.size] degistiginde cizim orantili buyur/kucultur,
/// elle yeniden ayar gerekmez.
class _TabakPainter extends CustomPainter {
  const _TabakPainter(this.renk);

  final Color renk;

  /// Tabagin cevresine serpistirilen noktalar.
  /// (aci: radyan, uzaklik: yaricapin orani, yaricap: noktanin buyuklugu)
  static const List<({double aci, double uzaklik, double yaricap})> _noktalar = [
    (aci: -0.45, uzaklik: 0.93, yaricap: 0.055),
    (aci: 0.85, uzaklik: 0.88, yaricap: 0.035),
    (aci: 2.05, uzaklik: 0.95, yaricap: 0.045),
    (aci: 3.55, uzaklik: 0.90, yaricap: 0.030),
    (aci: 4.60, uzaklik: 0.94, yaricap: 0.050),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Offset merkez = Offset(size.width / 2, size.height / 2);
    final double r = size.shortestSide / 2;

    // 1) Dis halka - tabagin kenari.
    canvas.drawCircle(
      merkez,
      r * 0.78,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.045
        ..color = renk.withValues(alpha: 0.35),
    );

    // 2) Ic dolgu - tabagin yuzeyi. Cok hafif: ustundeki ikon okunur kalmali.
    canvas.drawCircle(
      merkez,
      r * 0.62,
      Paint()..color = renk.withValues(alpha: 0.08),
    );

    // 3) Ic cember - tabaklarin klasik ic hattı, derinlik hissi verir.
    canvas.drawCircle(
      merkez,
      r * 0.62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.02
        ..color = renk.withValues(alpha: 0.25),
    );

    // 4) Cevredeki noktalar - cizimi 'ikon' olmaktan cikarip
    //    'illustrasyon'a yaklastirir, bos alani dengeler.
    final Paint noktaBoya = Paint()..color = renk.withValues(alpha: 0.30);
    for (final nokta in _noktalar) {
      canvas.drawCircle(
        merkez +
            Offset(math.cos(nokta.aci), math.sin(nokta.aci)) *
                (r * nokta.uzaklik),
        r * nokta.yaricap,
        noktaBoya,
      );
    }
  }

  // Yalnizca renk degisirse yeniden ciz. Tema gecisinde otomatik calisir.
  @override
  bool shouldRepaint(covariant _TabakPainter oldDelegate) =>
      oldDelegate.renk != renk;
}