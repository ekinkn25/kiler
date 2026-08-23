import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/recipe_mini.dart';

/// Asistan yanitinin altinda beliren tarif karti.
///
/// Dokununca `/tarif/:id` derin baglantisina gider. Rota disaridan
/// (kalori://app/tarif/...) da acilabildigi icin kart verisi `extra` ile
/// TASINMAZ - hedef ekran veriyi kimlikten kendisi ceker.
class RecipeMiniCard extends StatelessWidget {
  const RecipeMiniCard({required this.recipe, super.key});

  final RecipeMini recipe;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(top: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => context.push('/tarif/${recipe.id}'),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _kucukGorsel(renkler),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _altBilgi(),
                      style: TextStyle(
                        fontSize: 12,
                        color: renkler.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: renkler.outline),
            ],
          ),
        ),
      ),
    );
  }

  String _altBilgi() {
    final parcalar = <String>['${recipe.caloriesPerServing.round()} kcal'];
    if (recipe.toplamSure > 0) parcalar.add('${recipe.toplamSure} dk');
    parcalar.add(_zorluk(recipe.difficulty));
    return parcalar.join(' · ');
  }

  String _zorluk(String kod) => switch (kod) {
    'kolay' => 'Kolay',
    'orta' => 'Orta',
    'zor' => 'Zor',
    _ => kod,
  };

  Widget _kucukGorsel(ColorScheme renkler) {
    const double olcu = 56;

    // NOT: seed'deki 110 tarifin TAMAMINDA image_url null. Bu dal
    // pratikte her zaman calisiyor; gorseller eklenince digeri devreye
    // girer.
    if (recipe.imageUrl == null) {
      return Container(
        width: olcu,
        height: olcu,
        decoration: BoxDecoration(
          color: renkler.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.restaurant_menu, color: renkler.outline),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: recipe.imageUrl!,
        width: olcu,
        height: olcu,
        fit: BoxFit.cover,
        memCacheWidth: 160,
        placeholder: (context, url) => Container(
          width: olcu,
          height: olcu,
          color: renkler.surfaceContainerHighest,
        ),
        errorWidget: (context, url, error) => Container(
          width: olcu,
          height: olcu,
          color: renkler.surfaceContainerHighest,
          child: Icon(Icons.restaurant_menu, color: renkler.outline),
        ),
      ),
    );
  }
}