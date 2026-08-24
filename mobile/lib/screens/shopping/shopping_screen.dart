import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../models/shopping_item.dart';
import '../../providers/pantry_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';

/// Alisveris listesi alt ekrani (W3-T21).
///
/// Kiler sekmesinin ust barindan acilir (sekme DEGIL). Kategoriye gore
/// gruplu, checkbox'li. '+' ile elle ekleme, 'Kilere Aktar' ile isaretli
/// ogeler kilere gecer.
class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  bool _aktariliyor = false;

  Future<void> _elleEkle() async {
    final ad = await showDialog<String>(
      context: context,
      builder: (context) => const _EkleDiyalogu(),
    );
    if (ad == null || ad.trim().isEmpty || !mounted) return;
    try {
      await ref.read(shoppingListProvider.notifier).elleEkle(ad.trim());
    } catch (hata) {
      if (!mounted) return;
      _bilgi('Eklenemedi: ${friendlyErrorMessage(hata)}');
    }
  }

  Future<void> _kilereAktar() async {
    setState(() => _aktariliyor = true);
    try {
      final sonuc = await ref.read(shoppingListProvider.notifier).kilereAktar();
      if (!mounted) return;
      // Kiler ekrani da tazelensin.
      ref.invalidate(pantryProvider);

      if (sonuc.transferred.isEmpty) {
        _bilgi('Aktarılacak işaretli öğe yok.');
      } else {
        _bilgi('${sonuc.transferred.length} malzeme kilerine aktarıldı.');
      }
    } catch (hata) {
      if (!mounted) return;
      _bilgi('Aktarılamadı: ${friendlyErrorMessage(hata)}');
    } finally {
      if (mounted) setState(() => _aktariliyor = false);
    }
  }

  void _bilgi(String mesaj) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mesaj), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final liste = ref.watch(shoppingListProvider);
    final int isaretliSayisi =
        liste.valueOrNull?.where((o) => o.isChecked).length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alışveriş Listesi'),
        actions: [
          IconButton(
            tooltip: 'Ekle',
            icon: const Icon(Icons.add),
            onPressed: () => unawaited(_elleEkle()),
          ),
        ],
      ),
      body: liste.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [LoadingSkeleton.card(), SizedBox(height: 8), LoadingSkeleton.card()],
          ),
        ),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Liste yüklenemedi',
          message: friendlyErrorMessage(error),
          actionLabel: 'Tekrar dene',
          onAction: () =>
              unawaited(ref.read(shoppingListProvider.notifier).yenile()),
        ),
        data: (ogeler) => ogeler.isEmpty
            ? EmptyState(
                icon: Icons.shopping_cart_outlined,
                illustrated: true,
                title: 'Alışveriş listen boş',
                message: 'Sağ üstteki + ile ekleyebilir, ya da bir tarifte '
                    '"malzemem yok" diyerek doldurabilirsin.',
                actionLabel: 'Malzeme ekle',
                actionIcon: Icons.add,
                onAction: () => unawaited(_elleEkle()),
              )
            : _liste(ogeler),
      ),
      bottomNavigationBar: isaretliSayisi == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: _aktariliyor ? null : () => unawaited(_kilereAktar()),
                  icon: _aktariliyor
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.kitchen_outlined),
                  label: Text('$isaretliSayisi işaretliyi kilere aktar'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _liste(List<ShoppingItem> ogeler) {
    // Kategoriye gore grupla.
    final Map<String, List<ShoppingItem>> gruplar = {};
    for (final oge in ogeler) {
      (gruplar[oge.categoryName ?? 'Diğer'] ??= []).add(oge);
    }
    final kategoriler = gruplar.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final kategori in kategoriler) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
            child: Text(
              kategori,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final oge in gruplar[kategori]!)
            CheckboxListTile(
              value: oge.isChecked,
              onChanged: (v) => unawaited(
                ref.read(shoppingListProvider.notifier).isaretle(oge.id, v ?? false),
              ),
              title: Text(
                oge.name,
                style: TextStyle(
                  decoration: oge.isChecked ? TextDecoration.lineThrough : null,
                ),
              ),
              secondary: _KaynakRozeti(source: oge.source),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
        ],
      ],
    );
  }
}

class _KaynakRozeti extends StatelessWidget {
  const _KaynakRozeti({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final (String etiket, IconData ikon) = switch (source) {
      'tarif' => ('Tarif', Icons.restaurant_menu),
      'manuel' => ('Elle', Icons.edit_outlined),
      _ => (source, Icons.circle_outlined),
    };
    final renkler = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(ikon, size: 14, color: renkler.onSurfaceVariant),
      label: Text(etiket, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: renkler.surfaceContainerHighest,
    );
  }
}

/// Elle ekleme diyalogu: serbest metin.
class _EkleDiyalogu extends StatefulWidget {
  const _EkleDiyalogu();

  @override
  State<_EkleDiyalogu> createState() => _EkleDiyaloguState();
}

class _EkleDiyaloguState extends State<_EkleDiyalogu> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Listeye ekle'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Örn: soğan',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}