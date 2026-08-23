import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

/// Gunluk kalori halkasi.
///
/// SUCLAMA YASAGI (W3-T14): hedef asilinca KIRMIZI alarm YOK. Asim
/// notr bir renkle (tertiary) gosterilir ve metin '120 kcal fazla' der;
/// 'hedefini astin!' gibi yargilayan bir ifade kullanilmaz.
class CalorieRing extends StatelessWidget {
  const CalorieRing({
    required this.consumed,
    required this.target,
    super.key,
  });

  final double consumed;
  final double target;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;
    // Hedef 0 gelirse (profil eksik) sifira bolme olmasin.
    final double hedef = target <= 0 ? 1 : target;
    final double oran = consumed / hedef;
    final bool asildi = oran > 1;
    final int fark = (target - consumed).round();

    return Column(
      children: [
        CircularPercentIndicator(
          radius: 92,
          lineWidth: 16,
          // percent 0..1 disina cikamaz; asimi RENKLE anlatiyoruz.
          percent: oran.clamp(0.0, 1.0),
          circularStrokeCap: CircularStrokeCap.round,
          animation: true,
          animationDuration: 600,
          animateFromLastPercent: true,
          backgroundColor: renkler.surfaceContainerHighest,
          progressColor: asildi ? renkler.tertiary : renkler.primary,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Halka BUYUK, sayi IKINCIL: bu yuzden displayLarge degil
              // headlineMedium.
              Text(
                '${consumed.round()}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'kcal',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: renkler.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          asildi
              ? '${fark.abs()} kcal fazla · hedef ${target.round()} kcal'
              : '$fark kcal kaldı · hedef ${target.round()} kcal',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: renkler.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}