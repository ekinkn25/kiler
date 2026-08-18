import 'package:flutter/material.dart';

import '../../../models/enums.dart';

class OnboardingStep2Hedef extends StatelessWidget {
  const OnboardingStep2Hedef({
    required this.hedef, required this.haneBuyuklugu,
    required this.onHedefChanged, required this.onHaneBuyuklugu, super.key,
  });

  final Goal hedef;
  final int haneBuyuklugu;
  final ValueChanged<Goal> onHedefChanged;
  final ValueChanged<int> onHaneBuyuklugu;

  static const _hedefEtiketleri = {
    Goal.kiloVerme: 'Kilo vermek',
    Goal.koruma: 'Kilomu korumak',
    Goal.kiloAlma: 'Kilo almak',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Hedefin ne?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            children: Goal.values.map((g) => ChoiceChip(
              label: Text(_hedefEtiketleri[g]!),
              selected: hedef == g,
              onSelected: (_) => onHedefChanged(g),
            )).toList(),
          ),
          const SizedBox(height: 24),
          Text('Kaç kişilik hane için yemek planlıyorsun?',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: haneBuyuklugu > 1 ? () => onHaneBuyuklugu(haneBuyuklugu - 1) : null,
              ),
              SizedBox(
                width: 48,
                child: Text('$haneBuyuklugu',
                    textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: haneBuyuklugu < 20 ? () => onHaneBuyuklugu(haneBuyuklugu + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}