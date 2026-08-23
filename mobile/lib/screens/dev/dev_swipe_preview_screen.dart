import 'package:flutter/material.dart';

import '../../models/recipe_card.dart';
import '../../widgets/swipe/swipe_deck.dart';

/// GECICI: W3-T06 icin 10 sahte kartla gorsel + performans testi.
/// Backend/login gerektirmez. Gercek ekranlar gelince silinebilir.
class DevSwipePreviewScreen extends StatelessWidget {
  const DevSwipePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<RecipeCard> kartlar = List.generate(10, _sahteKart);

    return Scaffold(
      appBar: AppBar(title: const Text('Swipe Önizleme (10 kart)')),
      body: SwipeDeck(cards: kartlar),
    );
  }

  RecipeCard _sahteKart(int i) {
    return RecipeCard(
      id: 'mock-$i',
      title: 'Mercimek Çorbası #$i',
      slug: 'mercimek-corbasi-$i',
      imageUrl: 'https://picsum.photos/seed/kalori-$i/800/1200',
      caloriesPerServing: (250 + i * 15).toDouble(),
      servings: 2,
      prepTime: 10,
      cookTime: 20,
      difficulty: ['kolay', 'orta', 'zor'][i % 3],
      dietTags: i.isEven ? const ['vejetaryen'] : const [],
      finalScore: 0.8,
      scoreBreakdown: ScoreBreakdown(
        pantry: 0.5 + (i % 5) / 10,
        calorie: 0.7,
        taste: 0.6,
        time: 0.9,
        weights: const ScoreWeights(pantry: 0.4, calorie: 0.3, taste: 0.2, time: 0.1),
      ),
    );
  }
}