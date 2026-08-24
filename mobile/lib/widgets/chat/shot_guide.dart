import 'package:flutter/material.dart';

/// 'Malzemeleri tezgaha yay, ustten cek' cekim rehberi gorseli (W3-T12).
///
/// Asset/SVG DEGIL, canvas'a cizilir: projede gorsel varligi ve
/// flutter_svg yok; cizim tema renklerini okur, her olcude keskin kalir.
/// EmptyIllustration ile ayni gerekce.
///
/// Anlatilan sey: tepeden gorunum bir tezgah, uzerine serpistirilmis
/// malzemeler ve yukaridan asagi bir 'ustten cekim' oku.
class ShotGuide extends StatelessWidget {
  const ShotGuide({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final Color renk = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: RepaintBoundary(
        child: CustomPaint(painter: _RehberPainter(renk)),
      ),
    );
  }
}

class _RehberPainter extends CustomPainter {
  const _RehberPainter(this.renk);

  final Color renk;

  /// Tezgaha serpistirilen malzemeler: (x, y, yaricap) - hepsi 0..1 orani.
  static const List<({double x, double y, double r})> _malzemeler = [
    (x: 0.34, y: 0.52, r: 0.09),
    (x: 0.58, y: 0.46, r: 0.11),
    (x: 0.46, y: 0.68, r: 0.07),
    (x: 0.68, y: 0.66, r: 0.06),
    (x: 0.30, y: 0.70, r: 0.05),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1) Tezgah yuzeyi - alt kisimda yuvarlak kosemli dikdortgen.
    final Rect tezgah = Rect.fromLTWH(w * 0.12, h * 0.34, w * 0.76, h * 0.56);
    final RRect tezgahR =
        RRect.fromRectAndRadius(tezgah, Radius.circular(w * 0.06));
    canvas.drawRRect(
      tezgahR,
      Paint()..color = renk.withValues(alpha: 0.10),
    );
    canvas.drawRRect(
      tezgahR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.02
        ..color = renk.withValues(alpha: 0.35),
    );

    // 2) Serpistirilen malzemeler.
    final Paint dolu = Paint()..color = renk.withValues(alpha: 0.30);
    final Paint hat = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.015
      ..color = renk.withValues(alpha: 0.55);
    for (final m in _malzemeler) {
      final Offset merkez = Offset(w * m.x, h * m.y);
      canvas.drawCircle(merkez, w * m.r, dolu);
      canvas.drawCircle(merkez, w * m.r, hat);
    }

    // 3) 'Ustten cekim' oku: yukaridan tezgaha inen dikey ok.
    final double okX = w * 0.5;
    final Paint okBoya = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round
      ..color = renk;
    // Govde
    canvas.drawLine(Offset(okX, h * 0.06), Offset(okX, h * 0.26), okBoya);
    // Ok basi (asagi bakan V)
    final Path ucu = Path()
      ..moveTo(okX - w * 0.05, h * 0.20)
      ..lineTo(okX, h * 0.28)
      ..lineTo(okX + w * 0.05, h * 0.20);
    canvas.drawPath(ucu, okBoya);
  }

  @override
  bool shouldRepaint(covariant _RehberPainter oldDelegate) =>
      oldDelegate.renk != renk;
}