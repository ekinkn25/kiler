import 'package:flutter/material.dart';

import '../../models/meal_log.dart';

/// Tek bir ogun grubu (Kahvalti / Ogle / Aksam / Atistirma).
///
/// Basliktaki '+' butonu BILEREK yok: ogun ekleme yollari W3-T15 ve
/// W3-T16'da geliyor. Islevsiz bir buton koymak kullaniciyi yaniltir.
class MealGroupCard extends StatelessWidget {
  const MealGroupCard({
    required this.baslik,
    required this.meals,
    super.key,
  });

  final String baslik;
  final List<MealLog> meals;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;
    final double toplam = meals.fold(0, (t, m) => t + m.calories);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    baslik,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${toplam.round()} kcal',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: renkler.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            for (final ogun in meals)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ogun.itemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${ogun.calories.round()} kcal',
                      style: TextStyle(color: renkler.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}