import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/pantry_item.dart';
import '../status_chip.dart';

/// Kiler listesindeki tek satir (W3-T18 + W3-T21).
///
/// Durum rozeti artik DOKUNULABILIR: uzerine basinca uc secenekli menu
/// acilir (Var / Emin degilim / Yok). 'Yok' secilince kayit kilerden
/// duser ve alisveris listesine gider (yonlendirme cagiran ekranda).
class PantryItemTile extends StatelessWidget {
  const PantryItemTile({
    required this.item,
    required this.onStatusChange,
    super.key,
    this.busy = false,
  });

  final PantryItem item;

  /// Secilen yeni durum ile cagirilir.
  final void Function(Availability hedef) onStatusChange;

  /// Istek suruyor: menu pasif.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.ingredient.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _sureMetni(),
                    style: TextStyle(
                      fontSize: 12,
                      color: renkler.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _KaynakRozeti(source: item.source),
            const SizedBox(width: 4),
            // Durum menusu: rozete basinca uc secenek acilir.
            PopupMenuButton<Availability>(
              enabled: !busy,
              tooltip: 'Durumu değiştir',
              onSelected: onStatusChange,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: Availability.available,
                  child: Text('Var'),
                ),
                PopupMenuItem(
                  value: Availability.unknown,
                  child: Text('Emin değilim'),
                ),
                PopupMenuItem(
                  value: Availability.finished,
                  child: Text('Yok (alışverişe ekle)'),
                ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusChip(
                    type: item.availability == Availability.available
                        ? StatusChipType.available
                        : StatusChipType.unknown,
                    label: item.availability == Availability.available
                        ? 'Kesin var'
                        : 'Emin değiliz',
                  ),
                  Icon(Icons.arrow_drop_down, color: renkler.outline),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      PantrySource.manuel => (Icons.edit_outlined, 'Elle'),
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