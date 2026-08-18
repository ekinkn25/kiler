import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/recipe_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/swipe/swipe_deck.dart';

/// KESFET sekmesi: 'Bugun ne yesen?' + swipe destesi.
///
/// Bu ekran SADECE destenin GORUNTULENMESINDEN sorumlu (W3-T06). Kaydirma
/// yonune gore etiket/geri bildirim gonderme W3-T07'de eklenecek.
class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deste = ref.watch(swipeDeckProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bugün ne yesen?'), centerTitle: false),
      body: deste.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              LoadingSkeleton.card(),
              SizedBox(height: 12),
              LoadingSkeleton.card(),
            ],
          ),
        ),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Deste yüklenemedi',
          message: '$error',
          actionLabel: 'Tekrar dene',
          onAction: () => ref.invalidate(swipeDeckProvider),
        ),
        data: (veri) => veri.items.isEmpty
            ? const EmptyState(
                icon: Icons.restaurant_outlined,
                title: 'Şu an önerilecek tarif yok',
                message: 'Kilerine malzeme ekleyince öneriler burada görünecek.',
              )
            : SwipeDeck(cards: veri.items),
      ),
    );
  }
}