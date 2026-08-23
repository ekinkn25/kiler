import 'package:flutter/material.dart';

import '../../models/daily_summary.dart';

/// Protein / karbonhidrat / yag barlari.
///
/// KUCUK ve IKINCIL: halka ana gosterge, bunlar destekleyici. Bu yuzden
/// ince barlar ve kucuk yazi kullaniliyor.
///
/// JARGON YASAGI (W4-T09): 'makro' kelimesi arayuzde GECMEZ; basliklar
/// dogrudan 'Protein', 'Karbonhidrat', 'Yağ'.
class MacroBars extends StatelessWidget {
  const MacroBars({
    required this.consumed,
    required this.target,
    super.key,
  });

  final MacroBreakdown consumed;
  final MacroBreakdown target;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Bar(
            baslik: 'Protein',
            alinan: consumed.proteinG,
            hedef: target.proteinG,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Bar(
            baslik: 'Karbonhidrat',
            alinan: consumed.carbG,
            hedef: target.carbG,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Bar(baslik: 'Yağ', alinan: consumed.fatG, hedef: target.fatG),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.baslik, required this.alinan, required this.hedef});

  final String baslik;
  final double alinan;
  final double hedef;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;
    final double bolen = hedef <= 0 ? 1 : hedef;
    final double oran = (alinan / bolen).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          baslik,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: renkler.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: oran,
            minHeight: 6,
            backgroundColor: renkler.surfaceContainerHighest,
            // Asim burada da suclamiyor: bar dolar, renk degismez.
            color: renkler.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${alinan.round()} / ${hedef.round()} g',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}