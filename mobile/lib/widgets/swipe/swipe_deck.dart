import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../../models/recipe_card.dart';
import 'recipe_swipe_card.dart';

/// flutter_card_swiper sarmalayicisi. Deste mantigina (session, POST
/// /swipe, geri bildirim etiketleri) KARISMAZ - W3-T07'nin isi. Bu
/// widget SADECE kartlarin GORSEL olarak akici surumesinden sorumlu.
class SwipeDeck extends StatelessWidget {
  const SwipeDeck({
    required this.cards,
    super.key,
    this.controller,
    this.onSwipe,
    this.onEnd,
  });

  final List<RecipeCard> cards;
  final CardSwiperController? controller;
  final CardSwiperOnSwipe? onSwipe;
  final CardSwiperOnEnd? onEnd;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const Center(child: Text('Gösterilecek tarif kalmadı.'));
    }

    return CardSwiper(
      controller: controller,
      cardsCount: cards.length,
      numberOfCardsDisplayed: cards.length < 2 ? 1 : 2,
      maxAngle: 15, // GOREV SARTI: max 15 derece donme
      scale: 0.92, // arkadaki kart olceklensin
      backCardOffset: const Offset(0, 24),
      isLoop: false,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      cardBuilder: (context, index, percentX, percentY) => RecipeSwipeCard(card: cards[index]),
      onSwipe: onSwipe ?? (previousIndex, currentIndex, direction) async => true,
      onEnd: onEnd,
    );
  }
}