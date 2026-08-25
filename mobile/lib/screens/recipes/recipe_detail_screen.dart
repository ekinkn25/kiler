import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../models/enums.dart';
import '../../models/recipe.dart';
import '../../providers/meal_provider.dart';
import '../../providers/pantry_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../widgets/calories/meal_add_flow.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';

/// Tam tarif detayi (W4-T01 + W4-T02 + W4-T03 girisi).
///
/// Malzemeler kiler ile capraz eslestirilip RENKLENDIRILIR:
///   yesil=var, kirmizi=yok, sari=belki (kilerde 'bilinmiyor'),
///   gri=sozlukte tanimsiz. Renk TEK BASINA degil; ikon+yazi da eslik eder.
class RecipeDetailScreen extends ConsumerStatefulWidget {
  const RecipeDetailScreen({required this.recipeId, super.key});

  final String recipeId;

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  int? _kisi; // porsiyon (null iken tarifin kendi servings'i kullanilir)

  Future<void> _yaptim() async {
    // 'Bu Tarifi Yaptim' -> tanidik ogun ekleme akisi (kamera/galeri/yazi).
    final gun = ref.read(selectedDateProvider);
    final eklendi = await baslatOgunEkle(context, ref, date: gun);
    if (eklendi && mounted) {
      ref.invalidate(dailySummaryProvider(gun));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Afiyet olsun! Günlüğe eklendi.')));
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tarif = ref.watch(recipeDetailProvider(widget.recipeId));

    return Scaffold(
      appBar: AppBar(title: const Text('Tarif')),
      body: tarif.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              LoadingSkeleton.card(),
              SizedBox(height: 12),
              LoadingSkeleton(width: 220),
            ],
          ),
        ),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Tarif yüklenemedi',
          message: friendlyErrorMessage(error),
          actionLabel: 'Tekrar dene',
          onAction: () => ref.invalidate(recipeDetailProvider(widget.recipeId)),
        ),
        data: _govde,
      ),
    );
  }

  Widget _govde(Recipe tarif) {
    // Kiler haritasi: canonical_name -> availability.
    final kilerList = ref.watch(pantryProvider).valueOrNull ?? const [];
    final Map<String, Availability> kiler = {
      for (final k in kilerList) k.ingredient.canonicalName: k.availability,
    };

    final int kisi = _kisi ?? tarif.servings;
    final double olcek = tarif.servings == 0 ? 1 : kisi / tarif.servings;
    final int toplamKcal = (tarif.caloriesPerServing * kisi).round();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            _gorsel(tarif),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tarif.title,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _porsiyonSecici(tarif, kisi, toplamKcal),
                  const SizedBox(height: 20),
                  _lejant(),
                  const SizedBox(height: 8),
                  Text('Malzemeler',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  for (final m in tarif.ingredients)
                    _malzemeSatiri(m, kiler, olcek),
                  const SizedBox(height: 20),
                  Text('Adımlar',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  for (var i = 0; i < tarif.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            child: Text('${i + 1}',
                                style: const TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(tarif.steps[i])),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        // Alt sabit butonlar: Yaptim / Vazgec.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _altButonlar(),
        ),
      ],
    );
  }

  Widget _gorsel(Recipe tarif) {
    final renkler = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: tarif.imageUrl == null
          ? Container(
              color: renkler.surfaceContainerHighest,
              child: Icon(Icons.restaurant_menu, size: 64, color: renkler.outline),
            )
          : CachedNetworkImage(
              imageUrl: tarif.imageUrl!,
              fit: BoxFit.cover,
              memCacheWidth: 900,
              placeholder: (c, u) =>
                  Container(color: renkler.surfaceContainerHighest),
              errorWidget: (c, u, e) =>
                  Container(color: renkler.surfaceContainerHighest),
            ),
    );
  }

  Widget _porsiyonSecici(Recipe tarif, int kisi, int toplamKcal) {
    return Row(
      children: [
        const Text('Kaç kişilik?', style: TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: kisi <= 1 ? null : () => setState(() => _kisi = kisi - 1),
        ),
        Text('$kisi', style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: kisi >= 10 ? null : () => setState(() => _kisi = kisi + 1),
        ),
        const SizedBox(width: 8),
        Text('$toplamKcal kcal',
            style: TextStyle(color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _lejant() {
    final c = context.appColors;
    Widget nokta(Color renk, String ad) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: renk, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(ad, style: const TextStyle(fontSize: 11)),
          ],
        );
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        nokta(c.available, 'Var'),
        nokta(c.missing, 'Yok'),
        nokta(c.warning, 'Belki'),
        nokta(c.unknown, 'Bilinmiyor'),
      ],
    );
  }

  Widget _malzemeSatiri(
    RecipeIngredient m,
    Map<String, Availability> kiler,
    double olcek,
  ) {
    final c = context.appColors;
    // Durum + renk + ikon + yazi (renk tek basina degil).
    final (Color renk, IconData ikon, String durum) = () {
      final cn = m.canonicalName;
      if (cn == null) return (c.unknown, Icons.help_outline, 'bilinmiyor');
      final av = kiler[cn];
      if (av == Availability.available) return (c.available, Icons.check_circle, 'var');
      if (av == Availability.unknown) return (c.warning, Icons.help, 'belki');
      return (c.missing, Icons.cancel, 'yok');
    }();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(ikon, size: 18, color: renk),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: m.name),
              if (m.quantity != null)
                TextSpan(
                  text: '  ${_miktar(m.quantity!, m.unit, olcek)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              if (m.optional)
                const TextSpan(
                  text: '  (isteğe bağlı)',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                ),
            ])),
          ),
          Text(durum, style: TextStyle(color: renk, fontSize: 12)),
        ],
      ),
    );
  }

  String _miktar(double q, UnitCode? u, double olcek) {
    final v = q * olcek;
    final s = (v % 1 == 0) ? v.toInt().toString() : v.toStringAsFixed(1);
    return u == null ? s : '$s ${unitCodeToJson(u)}';
  }

  Widget _altButonlar() {
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('Vazgeç'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => unawaited(_yaptim()),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: const Icon(Icons.restaurant),
                  label: const Text('Bu Tarifi Yaptım'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}