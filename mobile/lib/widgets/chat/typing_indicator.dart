import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 'yaziyor...' gostergesi: sirayla ziplayan uc nokta.
///
/// Asistan baloncugunun aynisi gibi solda durur ki kullanici cevabin
/// nereden gelecegini gorsun.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _kontrol = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    // SART: repeat() eden controller dispose edilmezse widget agactan
    // ciktiktan sonra da tik atmaya devam eder (bellek + pil sizintisi).
    _kontrol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: renkler.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: AnimatedBuilder(
          animation: _kontrol,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) _nokta(i, renkler.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nokta(int sira, Color renk) {
    // Her nokta 1/3 faz kaymasiyla ziplar; sin egrisi yumusak inis-cikis
    // verir, dogrusal olsaydi mekanik gorunurdu.
    final double faz = (_kontrol.value + sira / 3) % 1.0;
    final double guc = math.sin(faz * math.pi).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Transform.translate(
        offset: Offset(0, -3 * guc),
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: renk.withValues(alpha: 0.35 + 0.55 * guc),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}