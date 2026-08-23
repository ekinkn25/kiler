import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/pantry_item.dart';
import '../status_chip.dart';

/// Kiler listesindeki tek satir.
///
/// 'Emin degiliz' bolumundeki satirlarda [Var] / [Bitti] hizli butonlari
/// gorunur; 'Kesin var' bolumunde bunlar YOK - kullanici zaten dogrulanmis
/// bir seyi tekrar dogrulamaz.
class PantryItemTile extends StatelessWidget {
  const PantryItemTile({
    required this.item,
    super.key,
    this.onStillHave,
    this.onFinished,
    this.busy = false,
  });

  final PantryItem item;

  /// null ise hizli butonlar cizilmez ('Kesin var' bolumu).
  final VoidCallback? onStillHave;
  final VoidCallback? onFinished;

  /// Istek suruyor: butonlar pasif, cift dokunus engellenir.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;
    final bool hizliButonlarVar = onStillHave != null && onFinished != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.ingredient.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _KaynakRozeti(source: item.source),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                StatusChip(
                  type: item.availability == Availability.available
                      ? StatusChipType.available
                      : StatusChipType.unknown,
                  label: item.availability == Availability.available
                      ? 'Kesin var'
                      : 'Emin değiliz',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _sureMetni(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: renkler.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (hizliButonlarVar) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onStillHave,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Var'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onFinished,
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      label: const Text('Bitti'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 'Kesin var' satirinda kalan gun, 'Emin degiliz'de aciklama.
  String _sureMetni() {
    if (item.availability != Availability.available) {
      return 'Hâlâ var mı?';
    }
    final int? kalan = item.daysRemaining;
    if (kalan == null) return '';
    if (kalan <= 0) return 'Bugün soracağız';
    return '$kalan gün sonra soracağız';
  }
}

class _KaynakRozeti extends StatelessWidget {
  const _KaynakRozeti({required this.source});

  final PantrySource source;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;
    final (IconData ikon, String etiket) = switch (source) {
      PantrySource.barkod => (Icons.qr_code_scanner, 'Barkod'),
      PantrySource.foto => (Icons.photo_camera_outlined, 'Fotoğraf'),
      PantrySource.tarif => (Icons.restaurant_menu, 'Tarif'),
      PantrySource.sistem => (Icons.settings_outlined, 'Sistem'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: renkler.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 13, color: renkler.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            etiket,
            style: TextStyle(fontSize: 11, color: renkler.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}