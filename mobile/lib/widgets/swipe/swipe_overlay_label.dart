import 'package:flutter/material.dart';

/// Kart suruklenirken uzerinde beliren buyuk renkli yon etiketi.
///
/// [percentX] / [percentY] dogrudan CardSwiper'in cardBuilder'indan gelir:

class SwipeOverlayLabel extends StatelessWidget {
  const SwipeOverlayLabel({
    required this.percentX,
    required this.percentY,
    super.key,
  });

  final int percentX;
  final int percentY;

  /// Bu esigin altindaki kucuk kaymalar 'kararsiz dokunus'tur;
  /// etiket titremesin diye yok sayilir.
  static const int _minGorunurYuzde = 8;

  @override
  Widget build(BuildContext context) {
    final int yatay = percentX.abs();
    final int dikey = percentY.abs();
    // Capraz surukleme: hangi eksen BASKINSA o kazanir, iki etiket
    // ayni anda gorunmez.
    final bool dikeyBaskin = dikey > yatay;

    final _EtiketBicimi bicim;
    final int guc;

    if (dikeyBaskin && percentY < 0 && dikey >= _minGorunurYuzde) {
      bicim = _EtiketBicimi.sonra;
      guc = dikey;
    } else if (!dikeyBaskin && percentX > 0 && yatay >= _minGorunurYuzde) {
      bicim = _EtiketBicimi.yapacagim;
      guc = yatay;
    } else if (!dikeyBaskin && percentX < 0 && yatay >= _minGorunurYuzde) {
      bicim = _EtiketBicimi.istemiyorum;
      guc = yatay;
    } else {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: bicim.hizalama,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Opacity(
          opacity: (guc / 100).clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: bicim.aciRadyan,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: bicim.renk, width: 4),
                borderRadius: BorderRadius.circular(12),
                color: bicim.renk.withValues(alpha: 0.22),
              ),
              child: Text(
                bicim.metin,
                style: TextStyle(
                  color: bicim.renk,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Uc yonun metin/renk/konum tanimi tek yerde.
enum _EtiketBicimi {
  istemiyorum('İSTEMİYORUM', Color(0xFFE53935), Alignment.topRight, 0.32),
  yapacagim('YAPACAĞIM', Color(0xFF43A047), Alignment.topLeft, -0.32),
  sonra('SONRA', Color(0xFF1E88E5), Alignment.bottomCenter, 0);

  const _EtiketBicimi(this.metin, this.renk, this.hizalama, this.aciRadyan);

  final String metin;
  final Color renk;
  final Alignment hizalama;
  final double aciRadyan;
}