import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ingredient_lite.dart';
import '../providers/pantry_provider.dart';

/// Yazarak malzeme aratip SECMEK icin diyalog (W3-T21).
///
/// Kilere elle ekleme akisi bunu kullanir: sozlukten gecerli bir malzeme
/// secilmeli (kilere yazmak ingredient_id ister). Doner: secilen malzeme
/// ya da null.
Future<IngredientLite?> showIngredientSearchDialog(BuildContext context) {
  return showDialog<IngredientLite>(
    context: context,
    builder: (context) => const _AramaDiyalogu(),
  );
}

class _AramaDiyalogu extends ConsumerStatefulWidget {
  const _AramaDiyalogu();

  @override
  ConsumerState<_AramaDiyalogu> createState() => _AramaDiyaloguState();
}

class _AramaDiyaloguState extends ConsumerState<_AramaDiyalogu> {
  final TextEditingController _controller = TextEditingController();
  String _sorgu = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _degisti(String metin) {
    // 300 ms debounce: her tusta istek atmayalim.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _sorgu = metin);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sonuc = ref.watch(ingredientSearchProvider(_sorgu));

    return AlertDialog(
      title: const Text('Malzeme ara'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _degisti,
              decoration: const InputDecoration(
                hintText: 'Örn: elma',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: _sorgu.trim().length < 2
                  ? const Center(child: Text('En az 2 harf yaz'))
                  : sonuc.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (hata, iz) =>
                          const Center(child: Text('Arama başarısız')),
                      data: (liste) => liste.isEmpty
                          ? const Center(child: Text('Sonuç yok'))
                          : ListView.builder(
                              itemCount: liste.length,
                              itemBuilder: (context, i) => ListTile(
                                title: Text(liste[i].displayName),
                                onTap: () => Navigator.of(context).pop(liste[i]),
                              ),
                            ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
      ],
    );
  }
}