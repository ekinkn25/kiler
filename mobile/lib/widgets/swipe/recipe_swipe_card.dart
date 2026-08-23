import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/recipe_card.dart';

/// Swipe destesindeki TEK karti cizer. Saf/stateless: CardSwiper'in
/// cardBuilder'i icinde her seferinde yeniden kurulabilir olmali, bu
/// yuzden disaridan sadece [card] alir, hicbir provider dinlemez.
class RecipeSwipeCard extends StatelessWidget {
  const RecipeSwipeCard({required this.card, super.key});

  final RecipeCard card;

  @override
  Widget build(BuildContext context) {
    final int uyumYuzdesi = (card.scoreBreakdown.pantry * 100).round();
    final int toplamSure = (card.prepTime ?? 0) + (card.cookTime ?? 0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _kartGorseli(context),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.5, 1],
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _UyumEtiketi(yuzde: uyumYuzdesi),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Rozet(
                      icon: Icons.local_fire_department,
                      label: '${card.caloriesPerServing.round()} kcal',
                    ),
                    if (toplamSure > 0)
                      _Rozet(icon: Icons.timer_outlined, label: '$toplamSure dk'),
                    if (card.difficulty != null)
                      _Rozet(icon: Icons.bar_chart, label: _zorlukEtiketi(card.difficulty!)),
                  ],
                ),
                if (card.dietTags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final etiket in card.dietTags) _DiyetCipi(etiket: etiket),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartGorseli(BuildContext context) {
    if (card.imageUrl == null) {
      return Container(color: const Color(0xFFE0E0E0));
    }

    final MediaQueryData ekran = MediaQuery.of(context);
    final int hedefGenislik = (ekran.size.width * ekran.devicePixelRatio).round().clamp(320, 1080);
    return CachedNetworkImage(
      imageUrl: card.imageUrl!,
      fit: BoxFit.cover,
      // 60fps hedefi: orijinal cozunurlukte decode etmek jank'e sebep olur.
      memCacheWidth: hedefGenislik,
      placeholder: (context, url) => Container(color: const Color(0xFFE0E0E0)),
      errorWidget: (context, url, error) => Container(
        color: const Color(0xFFE0E0E0),
        child: const Icon(Icons.image_not_supported_outlined, color: Colors.white70),
      ),
    );
  }

  String _zorlukEtiketi(String kod) => switch (kod) {
    'kolay' => 'Kolay',
    'orta' => 'Orta',
    'zor' => 'Zor',
    _ => kod,
  };
}

class _UyumEtiketi extends StatelessWidget {
  const _UyumEtiketi({required this.yuzde});

  final int yuzde;

  @override
  Widget build(BuildContext context) {
    final Color renk = context.appColors.available;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(20)),
      child: Text(
        'Kilerinle %$yuzde uyumlu',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _Rozet extends StatelessWidget {
  const _Rozet({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _DiyetCipi extends StatelessWidget {
  const _DiyetCipi({required this.etiket});

  final String etiket;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        etiket,
        style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}