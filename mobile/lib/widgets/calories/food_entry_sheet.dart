import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../models/ingredient_lite.dart';
import '../../providers/meal_provider.dart';
import '../../providers/pantry_provider.dart';
import '../app_button.dart';
import '../hata_gorunumu.dart';

/// Yiyecek arayip miktar girerek ogun ekleme (W3-T16 cekirdegi).
///
/// Kalori OTOMATIK: yiyecek secilir, gram veya ADET girilir, backend
/// hesaplar. Doner: 'eklendi' | 'elle' | null.
Future<String?> showFoodEntrySheet(
  BuildContext context, {
  required String date,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _FoodEntryBody(date: date),
    ),
  );
}

class _FoodEntryBody extends ConsumerStatefulWidget {
  const _FoodEntryBody({required this.date});
  final String date;

  @override
  ConsumerState<_FoodEntryBody> createState() => _FoodEntryBodyState();
}

class _FoodEntryBodyState extends ConsumerState<_FoodEntryBody> {
  final TextEditingController _arama = TextEditingController();
  final TextEditingController _miktar = TextEditingController(text: '100');
  Timer? _debounce;
  String _sorgu = '';

  IngredientLite? _secili;
  bool _adetMi = false;
  late String _ogun = _varsayilanOgun();
  bool _kaydediyor = false;

  static String _varsayilanOgun() {
    final s = DateTime.now().hour;
    if (s < 11) return 'kahvalti';
    if (s < 15) return 'ogle';
    if (s < 21) return 'aksam';
    return 'atistirma';
  }

  static const Map<String, String> _ogunAdlari = {
    'kahvalti': 'Kahvaltı',
    'ogle': 'Öğle',
    'aksam': 'Akşam',
    'atistirma': 'Atıştırma',
  };

  void _aramaDegisti(String metin) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _sorgu = metin);
    });
  }

  void _sec(IngredientLite m) {
    setState(() {
      _secili = m;
      _arama.clear();
      // Adet ile eklenebiliyorsa varsayilan 'adet' modu daha dogal (1 elma).
      _adetMi = m.adetSecilebilir;
      _miktar.text = _adetMi ? '1' : '100';
    });
  }

  void _birimDegistir(bool adet) {
    setState(() {
      _adetMi = adet;
      _miktar.text = adet ? '1' : '100';
    });
  }

  /// Girilen miktara gore canli kalori onizlemesi.
  double? get _onizlemeKcal {
    final c100 = _secili?.caloriesPer100g;
    if (c100 == null) return null;
    final n = double.tryParse(_miktar.text.trim());
    if (n == null) return null;
    if (_adetMi) {
      final gpp = _secili?.gramsPerPiece;
      if (gpp == null) return null;
      return c100 * gpp * n / 100;
    }
    return c100 * n / 100;
  }

  Future<void> _kaydet() async {
    final n = double.tryParse(_miktar.text.trim());
    if (_secili == null) return;
    if (n == null || n <= 0) {
      _uyar('Geçerli bir miktar gir.');
      return;
    }
    setState(() => _kaydediyor = true);
    try {
      final servis = ref.read(mealPhotoServiceProvider);
      if (_adetMi) {
        await servis.malzemeyleYaz(
          date: widget.date,
          mealType: _ogun,
          ingredientId: _secili!.id,
          adet: n.round(),
        );
      } else {
        await servis.malzemeyleYaz(
          date: widget.date,
          mealType: _ogun,
          ingredientId: _secili!.id,
          grams: n,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop('eklendi');
    } catch (hata) {
      if (!mounted) return;
      setState(() => _kaydediyor = false);
      _uyar('Eklenemedi: ${friendlyErrorMessage(hata)}');
    }
  }

  void _uyar(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _arama.dispose();
    _miktar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final yazi = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: _secili == null ? _aramaGorunumu(yazi) : _miktarGorunumu(yazi),
      ),
    );
  }

  // ----- Adim 1: yiyecek ara -----
  Widget _aramaGorunumu(TextTheme yazi) {
    final sonuc = ref.watch(ingredientSearchProvider(_sorgu));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Ne yedin?', style: yazi.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: _arama,
          autofocus: true,
          onChanged: _aramaDegisti,
          decoration: const InputDecoration(
            hintText: 'Örn: elma, süt, pilav',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: _sorgu.trim().length < 2
              ? const Center(child: Text('En az 2 harf yaz'))
              : sonuc.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  // Arama coktuyse kullanici 'elle gir' yoluna gecebilmeli;
                  // bu tabakada zaten o buton var, o yuzden notr tek satir.
                  error: (e, _) => Center(
                    child: HataSatiriKucuk(
                      mesaj: 'Arama şu an çalışmıyor.',
                      onTekrar: () =>
                          ref.invalidate(ingredientSearchProvider(_sorgu)),
                    ),
                  ),
                  data: (liste) => liste.isEmpty
                      ? const Center(child: Text('Sonuç yok'))
                      : ListView.builder(
                          itemCount: liste.length,
                          itemBuilder: (context, i) {
                            final m = liste[i];
                            return ListTile(
                              title: Text(m.displayName),
                              subtitle: m.caloriesPer100g == null
                                  ? null
                                  : Text('${m.caloriesPer100g!.round()} kcal / 100 g'),
                              onTap: () => _sec(m),
                            );
                          },
                        ),
                ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop('elle'),
          child: const Text('Listede yok, kendim gireyim'),
        ),
      ],
    );
  }

  // ----- Adim 2: miktar (gram/adet) + ogun -----
  Widget _miktarGorunumu(TextTheme yazi) {
    final kcal = _onizlemeKcal;
    final bool adetVar = _secili!.adetSecilebilir;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _secili!.displayName,
                style: yazi.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _secili = null),
              child: const Text('Değiştir'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Birim secimi: yalnizca adet ile eklenebilen yiyeceklerde.
        if (adetVar) ...[
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Gram')),
              ButtonSegment(value: true, label: Text('Adet')),
            ],
            selected: {_adetMi},
            showSelectedIcon: false,
            onSelectionChanged: (s) => _birimDegistir(s.first),
          ),
          const SizedBox(height: 12),
        ],

        TextField(
          controller: _miktar,
          keyboardType: TextInputType.number,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Miktar',
            suffixText: _adetMi ? 'adet' : 'gram',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          kcal == null ? '—' : '≈ ${kcal.round()} kcal',
          style: yazi.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text('Hangi öğün?', style: yazi.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final t in _ogunAdlari.keys)
              ChoiceChip(
                label: Text(_ogunAdlari[t]!),
                selected: _ogun == t,
                onSelected: (_) => setState(() => _ogun = t),
              ),
          ],
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Günlüğe ekle',
          icon: Icons.check,
          loading: _kaydediyor,
          onPressed: _kaydediyor ? null : _kaydet,
        ),
      ],
    );
  }
}