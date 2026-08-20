import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../models/recipe_mini.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';

/// Tarif detay ekraninin ISKELETI.
///
/// Veriyi KIMLIKTEN ceker, disaridan `extra` ile almaz: rota derin
/// baglantiyla da (kalori://app/tarif/...) acilabiliyor ve o durumda
/// `extra` bos gelir.
///
/// W4-T01 bu ekrani genisletecek: malzeme listesi yesil/kirmizi/gri
/// (GET /recipes/{id}/ingredient-status), porsiyon olcekleme (W4-T02),
/// 'Bu Tarifi Yaptim' (W4-T03). Iskelet aynen kalir.
class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({required this.recipeId, super.key});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ayni uc, tek kimlikle. Yeni bir saglayici gerekmiyor.
    final kart = ref.watch(recipeCardsProvider(recipeId));

    return Scaffold(
      appBar: AppBar(title: const Text('Tarif')),
      body: kart.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              LoadingSkeleton.card(),
              SizedBox(height: 12),
              LoadingSkeleton(width: 220),
            ],
          ),
        ),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Tarif yüklenemedi',
          message: friendlyErrorMessage(error),
          actionLabel: 'Tekrar dene',
          onAction: () => ref.invalidate(recipeCardsProvider(recipeId)),
        ),
        data: (liste) => liste.isEmpty
            ? const EmptyState(
                icon: Icons.search_off,
                illustrated: true,
                title: 'Tarif bulunamadı',
                message: 'Bu tarif kaldırılmış olabilir.',
              )
            : _govde(context, liste.first),
      ),
    );
  }

  Widget _govde(BuildContext context, RecipeMini tarif) {
    final ColorScheme renkler = Theme.of(context).colorScheme;

    return ListView(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: tarif.imageUrl == null
              ? Container(
                  color: renkler.surfaceContainerHighest,
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: renkler.outline,
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: tarif.imageUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: 900,
                  placeholder: (context, url) =>
                      Container(color: renkler.surfaceContainerHighest),
                  errorWidget: (context, url, error) =>
                      Container(color: renkler.surfaceContainerHighest),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tarif.title,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Rozet(
                    icon: Icons.local_fire_department,
                    label: '${tarif.caloriesPerServing.round()} kcal',
                  ),
                  if (tarif.toplamSure > 0)
                    _Rozet(
                      icon: Icons.timer_outlined,
                      label: '${tarif.toplamSure} dk',
                    ),
                  _Rozet(icon: Icons.bar_chart, label: _zorluk(tarif.difficulty)),
                ],
              ),
              if (tarif.dietTags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final etiket in tarif.dietTags)
                      Chip(
                        label: Text(etiket),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 28),
              // GECICI: malzeme listesi, adimlar ve 'Bu Tarifi Yaptim'
              // W4-T01/T02/T03'te gelecek.
              Text(
                'Malzeme listesi ve adımlar yakında burada olacak.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

  // Mini kartla ayni cevirici. Ham kod ('orta') ekranda gorunmemeli.
  String _zorluk(String kod) => switch (kod) {
    'kolay' => 'Kolay',
    'orta' => 'Orta',
    'zor' => 'Zor',
    _ => kod,
  };

class _Rozet extends StatelessWidget {
  const _Rozet({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: renkler.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: renkler.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}