import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../models/meal_estimate.dart';
import '../../providers/meal_provider.dart';
import '../app_button.dart';
import 'portion_selector.dart';

/// Tabak tahmininin DUZENLENEBILIR onay karti (W3-T15).
///
/// 'Tahmindir, duzeltebilirsin': yemek adi, porsiyon ve kalori hepsi
/// degistirilebilir. Onaylaninca POST /meals ile gunluge yazilir.
///
/// Doner: true (eklendi) / null (vazgecildi).
Future<bool?> showMealConfirmSheet(
  BuildContext context, {
  required MealEstimate tahmin,
  required String date,
  bool manuel = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      // Klavye acilinca alan yukari itilsin.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _OnayGovdesi(tahmin: tahmin, date: date, manuel: manuel),
    ),
  );
}

class _OnayGovdesi extends ConsumerStatefulWidget {
  const _OnayGovdesi({required this.tahmin, required this.date, this.manuel = false});

  final MealEstimate tahmin;
  final String date;
  final bool manuel;

  @override
  ConsumerState<_OnayGovdesi> createState() => _OnayGovdesiState();
}

class _OnayGovdesiState extends ConsumerState<_OnayGovdesi> {
  late final TextEditingController _adController =
      TextEditingController(text: widget.tahmin.dishName);
  late final TextEditingController _kaloriController = TextEditingController(
    text: _kaloriFor(_porsiyon)?.round().toString() ?? '',
  );

  late String _porsiyon = widget.tahmin.portion;
  late String _ogunTipi = _varsayilanOgun();
  bool _kaydediyor = false;

  /// Kalori/gram alanini gorunur yapan bayrak. VARSAYILAN GIZLI: kullanici
  /// hic gram gormeden porsiyon secip ekleyebilsin (W3-T17 kabul kriteri).
  late bool _gramGoster = _kaloriFor(_porsiyon) == null;

  /// Porsiyon carpanlari (referans = orta). portion_options yoksa fallback.
  static const Map<String, double> _carpan = {
    'kucuk': 0.72,
    'orta': 1.0,
    'buyuk': 1.4,
  };

  /// Tahminin kendi porsiyonundan turetilen 'orta' referansi.
  double get _ortaGram =>
      widget.tahmin.estimatedGrams / (_carpan[widget.tahmin.portion] ?? 1.0);

  double? get _ortaKalori {
    final b = widget.tahmin.calories;
    if (b == null) return null;
    return b / (_carpan[widget.tahmin.portion] ?? 1.0);
  }

  /// Bir boy icin gram: once portion_options, yoksa carpanla turet.
  double _gramFor(String boy) {
    for (final s in widget.tahmin.portionOptions) {
      if (s.portion == boy) return s.grams;
    }
    return _ortaGram * (_carpan[boy] ?? 1.0);
  }

  /// Bir boy icin kalori: once portion_options, yoksa carpanla turet.
  double? _kaloriFor(String boy) {
    for (final s in widget.tahmin.portionOptions) {
      if (s.portion == boy && s.calories != null) return s.calories;
    }
    final o = _ortaKalori;
    return o == null ? null : o * (_carpan[boy] ?? 1.0);
  }

  /// Gunun saatine gore mantikli varsayilan.
  static String _varsayilanOgun() {
    final int saat = DateTime.now().hour;
    if (saat < 11) return 'kahvalti';
    if (saat < 15) return 'ogle';
    if (saat < 21) return 'aksam';
    return 'atistirma';
  }

  static const Map<String, String> _ogunAdlari = {
    'kahvalti': 'Kahvaltı',
    'ogle': 'Öğle',
    'aksam': 'Akşam',
    'atistirma': 'Atıştırma',
  };

  // static const Map<String, String> _porsiyonAdlari = {
  //   'kucuk': 'Küçük',
  //   'orta': 'Orta',
  //   'buyuk': 'Büyük',
  // };

  /// Secili porsiyona karsilik gelen secenek (gram+kalori hazir).
  // PortionOption? get _seciliSecenek {
  //   for (final s in widget.tahmin.portionOptions) {
  //     if (s.portion == _porsiyon) return s;
  //   }
  //   return null;
  // }

  /// Sunulacak porsiyon boylari: backend secenek verdiyse onlar, yoksa
  /// yalnizca tahminin kendi boyu.
  // List<String> get _porsiyonBoylari {
  //   if (widget.tahmin.portionOptions.isEmpty) return [widget.tahmin.portion];
  //   return widget.tahmin.portionOptions.map((s) => s.portion).toList();
  // }

  void _porsiyonSec(String yeni) {
    setState(() {
      _porsiyon = yeni;
      final kcal = _kaloriFor(yeni);
      // Porsiyon degisince kaloriyi guncelle - ama kullanici elle
      // degistirdiyse ustune yazmamak icin yalnizca secenek varsa.
      if (kcal != null) _kaloriController.text = kcal.round().toString();
    });
  }

  Future<void> _kaydet() async {
    final ad = _adController.text.trim();
    // Alan gizliyse porsiyondan turetilen kaloriyi kullan; acıksa yazılanı.
    final double? kcal = _gramGoster
        ? double.tryParse(_kaloriController.text.trim())
        : _kaloriFor(_porsiyon);

    if (ad.isEmpty) {
      _uyar('Yemek adı boş olamaz.');
      return;
    }
    if (kcal == null || kcal <= 0) {
      _uyar('Kalori tahmini bulunamadı; "Gram gireyim" ile elle girebilirsin.');
      setState(() => _gramGoster = true);
      return;
    }

    setState(() => _kaydediyor = true);
    try {
      // Porsiyon oranina gore makrolari da olcekle: backend makrolari
      // tahminin KENDI porsiyonuna gore verdi, boy degistiyse kaydir.
      final double olcek = widget.tahmin.calories != null &&
              widget.tahmin.calories! > 0
          ? kcal / widget.tahmin.calories!
          : 1;

      await ref.read(mealPhotoServiceProvider).gunlugeYaz(
            date: widget.date,
            mealType: _ogunTipi,
            dishName: ad,
            calories: kcal,
            grams: _gramFor(_porsiyon),
            proteinG: _olcekli(widget.tahmin.proteinG, olcek),
            carbG: _olcekli(widget.tahmin.carbG, olcek),
            fatG: _olcekli(widget.tahmin.fatG, olcek),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (hata) {
      if (!mounted) return;
      setState(() => _kaydediyor = false);
      _uyar('Eklenemedi: ${friendlyErrorMessage(hata)}');
    }
  }

  double? _olcekli(double? deger, double olcek) =>
      deger == null ? null : deger * olcek;

  void _uyar(String mesaj) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mesaj)));
  }

  @override
  void dispose() {
    _adController.dispose();
    _kaloriController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;
    final TextTheme yazi = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fotograftan geldiyse 'tahmindir' uyarisi; elle girişte gerek yok.
            if (!widget.manuel) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: renkler.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: renkler.onSecondaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bu bir tahmin; düzeltebilirsin.',
                        style: yazi.bodySmall?.copyWith(
                          color: renkler.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _adController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Yemek adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            Text('Ne kadar yedin?', style: yazi.labelLarge),
            const SizedBox(height: 8),
            PortionSelector(secili: _porsiyon, onSec: _porsiyonSec),
            const SizedBox(height: 12),

            // Kalori alani VARSAYILAN GIZLI: kullanici gram/kalori gormeden
            // porsiyon secip ekleyebilir. Isteyen bu baglantiyla acar.
            if (_gramGoster)
              TextField(
                controller: _kaloriController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kalori',
                  suffixText: 'kcal',
                  border: OutlineInputBorder(),
                ),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _gramGoster = true),
                  icon: const Icon(Icons.tune, size: 18),
                  label: Text(
                    'Kalori gireyim (${_kaloriFor(_porsiyon)?.round() ?? '?'} kcal)',
                  ),
                ),
              ),
            const SizedBox(height: 16),

            Text('Hangi öğün?', style: yazi.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final tip in _ogunAdlari.keys)
                  ChoiceChip(
                    label: Text(_ogunAdlari[tip]!),
                    selected: _ogunTipi == tip,
                    onSelected: (_) => setState(() => _ogunTipi = tip),
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
        ),
      ),
    );
  }
}