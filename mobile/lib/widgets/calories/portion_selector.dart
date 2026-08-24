import 'package:flutter/material.dart';

/// Gorsel porsiyon secimi (W3-T17).
///
/// Gram yerine kucuk/orta/buyuk kase ikonlari + avuc ici karsilastirmasi.
/// Kaseler canvas'a cizilir (asset/SVG yok, tema renklerini okur).
class PortionSelector extends StatelessWidget {
  const PortionSelector({
    required this.secili,
    required this.onSec,
    super.key,
  });

  /// 'kucuk' | 'orta' | 'buyuk'
  final String secili;
  final ValueChanged<String> onSec;

  static const List<({String kod, String ad, String avuc, double olcek})> _boylar = [
    (kod: 'kucuk', ad: 'Küçük', avuc: '≈ yarım avuç', olcek: 0.72),
    (kod: 'orta', ad: 'Orta', avuc: '≈ bir avuç', olcek: 1.0),
    (kod: 'buyuk', ad: 'Büyük', avuc: '≈ iki avuç', olcek: 1.4),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final b in _boylar)
          Expanded(
            child: _Kase(
              ad: b.ad,
              avuc: b.avuc,
              olcek: b.olcek,
              secili: secili == b.kod,
              onTap: () => onSec(b.kod),
            ),
          ),
      ],
    );
  }
}

class _Kase extends StatelessWidget {
  const _Kase({
    required this.ad,
    required this.avuc,
    required this.olcek,
    required this.secili,
    required this.onTap,
  });

  final String ad;
  final String avuc;
  final double olcek;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;
    final Color renk = secili ? renkler.primary : renkler.outline;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: secili ? renkler.primaryContainer.withValues(alpha: 0.4) : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: secili ? renkler.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Kaseler ortak 56 px alan icinde; olcek ile buyuklukleri
            // farklilasir - kucuk kase kucuk, buyuk kase buyuk gorunur.
            SizedBox(
              height: 52,
              child: Center(
                child: CustomPaint(
                  size: Size(48 * olcek, 40 * olcek),
                  painter: _KasePainter(renk),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ad,
              style: TextStyle(
                fontWeight: secili ? FontWeight.bold : FontWeight.normal,
                color: secili ? renkler.primary : renkler.onSurface,
              ),
            ),
            Text(
              avuc,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: renkler.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Basit kase silueti: ust kenar elipsi + kavisli govde.
class _KasePainter extends CustomPainter {
  const _KasePainter(this.renk);

  final Color renk;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint hat = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = renk;
    final Paint dolgu = Paint()..color = renk.withValues(alpha: 0.12);

    // Govde: ust genis, alta daralan kavis (kase).
    final Path govde = Path()
      ..moveTo(w * 0.08, h * 0.22)
      ..quadraticBezierTo(w * 0.5, h * 1.15, w * 0.92, h * 0.22);
    canvas.drawPath(govde, dolgu..style = PaintingStyle.fill);
    canvas.drawPath(govde, hat);

    // Ust kenar elipsi (kasenin agzi).
    final Rect agiz = Rect.fromLTWH(w * 0.08, h * 0.02, w * 0.84, h * 0.34);
    canvas.drawOval(agiz, hat);
  }

  @override
  bool shouldRepaint(covariant _KasePainter oldDelegate) =>
      oldDelegate.renk != renk;
}