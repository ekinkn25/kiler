import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import '../../models/recipe_card.dart';
import '../../providers/swipe_provider.dart';
import '../../models/ingredient_lite.dart';
import '../app_button.dart';

class DislikeResult {
  const DislikeResult({
    required this.reason, 
    this.missingIngredients = const [],
  });
  final FeedbackReason reason;
  final List<IngredientLite> missingIngredients;
}

//sola kaydıırnca bulanık tam ekran ve sorular
//kabul kriteri: cevaplamak zorunlu değil null dönebilir 
Future<DislikeResult?> showDislikeReasonDialog(
  BuildContext context, {
  required RecipeCard card,
}) {
  return showGeneralDialog<DislikeResult>(
    context: context, 
    barrierDismissible: true,
    barrierLabel: 'Kapat',
    barrierColor: Colors.black.withValues(alpha: 0.2),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder:(context, animation, secondaryAnimation) => _SebepGovdesi(card: card),
    transitionBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

class _SebepGovdesi extends ConsumerStatefulWidget {
  const _SebepGovdesi({required this.card});
  final RecipeCard card;
  @override
  ConsumerState<_SebepGovdesi> createState() => _SebepGovdesiState();
}

class _SebepGovdesiState extends ConsumerState<_SebepGovdesi> {
  bool _malzemeAdimi = false;
  final Set<int> _secilenKimlikler = <int>{};
  void _kapat(DislikeResult? sonuc) => Navigator.of(context).pop(sonuc);
  void _malzemeAdiminiAc(){
    if (widget.card.missingIngredients.isEmpty){
      _kapat(const DislikeResult(reason: FeedbackReason.malzemeYok));
      return;
    }
    setState(() => _malzemeAdimi = true);
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _malzemeAdimi ? _malzemeSecimi() : _sebepSecimi(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ADIM 1 : neden yapmıyorsun ? 
  Widget _sebepSecimi(){
    final TextTheme yazi = Theme.of(context).textTheme;
    return Column(
      key: const ValueKey('sebep'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.card.title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: yazi.bodyMedium,
        ),
        const SizedBox(height: 6,),
        Text(
          'Neden yapmıyorsun?',
          textAlign: TextAlign.center,
          style: yazi.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6,),
        Text(
          'İstersen boş geç. Ama yine de not alacağım!',
          textAlign: TextAlign.center,
          style: yazi.bodySmall,
        ),
        const SizedBox(height: 24,),
        _SecenekButonu(
          icon: Icons.thumb_down_alt_outlined,
          label: 'Beğenmedim',
          aciklama: 'Bu tarif bir daha hiç önerilmesin',
          onTap: () => _kapat(const DislikeResult(reason: FeedbackReason.sevmedim)),
        ),
        const SizedBox(height: 12,),
        _SecenekButonu(
          icon: Icons.remove_shopping_cart_outlined,
          label: 'Malzemem yok',
          aciklama: 'Hangi malzeme eksik lütfen seç',
          onTap: _malzemeAdiminiAc,
        ),
        const SizedBox(height: 12,),
        _SecenekButonu(
          icon: Icons.timer_off_outlined,
          label: 'Zamanı fazla geldi',
          aciklama: 'Daha kısa sürede yapılabilecek olan yemekleri önerir.',
          onTap: () => _kapat(const DislikeResult(reason: FeedbackReason.cokUzun)),
        ),
        const SizedBox(height: 16,),
        TextButton(onPressed: () => _kapat(null), child: const Text('Geç')),
      ],
    );
  }

  // ADIM 2: hangi malzemen yok ? 
    // ADIM 2: hangi malzemelerin yok ? (COKLU secim)
  Widget _malzemeSecimi() {
    final TextTheme yazi = Theme.of(context).textTheme;
    final String anahtar = widget.card.missingIngredients.join(',');
    final malzemeler = ref.watch(missingIngredientsProvider(anahtar));

    return Column(
      key: const ValueKey('malzeme'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Hangi malzemelerin yok?',
          textAlign: TextAlign.center,
          style: yazi.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Birden fazla seçebilirsin, alışveriş listene eklerim.',
          textAlign: TextAlign.center,
          style: yazi.bodySmall,
        ),
        const SizedBox(height: 20),
        malzemeler.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          // Sozluk cekilemezse kullaniciyi tikamayiz: sebep yine yazilir,
          // sadece hangi malzeme oldugu bilinmez.
          error: (error, _) => Text(
            'Malzeme listesi alınamadı, sebebi yine de kaydedeceğim.',
            textAlign: TextAlign.center,
            style: yazi.bodySmall,
          ),
          data: (liste) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final malzeme in liste)
                    FilterChip(
                      label: Text(malzeme.displayName),
                      selected: _secilenKimlikler.contains(malzeme.id),
                      onSelected: (secildi) => setState(() {
                        if (secildi) {
                          _secilenKimlikler.add(malzeme.id);
                        } else {
                          _secilenKimlikler.remove(malzeme.id);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              AppButton(
                label: _secilenKimlikler.isEmpty
                    ? 'Malzeme seç'
                    : '${_secilenKimlikler.length} malzemeyi listeme ekle',
                icon: Icons.add_shopping_cart,
                // Hicbir sey secilmemisken buton PASIF: bos gonderim
                // backend'de 422 doner (items min_length=1).
                onPressed: _secilenKimlikler.isEmpty
                    ? null
                    : () => _kapat(
                          DislikeResult(
                            reason: FeedbackReason.malzemeYok,
                            missingIngredients: liste
                                .where((m) => _secilenKimlikler.contains(m.id))
                                .toList(),
                          ),
                        ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          // Sebep yazilir ama malzeme secilmez: liste de olusmaz.
          onPressed: () =>
              _kapat(const DislikeResult(reason: FeedbackReason.malzemeYok)),
          child: const Text('Seçmeden geç'),
        ),
        TextButton(
          onPressed: () => setState(() => _malzemeAdimi = false),
          child: const Text('Geri'),
        ),
      ],
    );
  }
}

class _SecenekButonu extends StatelessWidget {
  const _SecenekButonu({
    required this.icon,
    required this.label,
    required this.onTap,
    this.aciklama,
  });

  final IconData icon;
  final String label;
  final String? aciklama;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;

    return Material(
      color: renkler.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: renkler.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    if (aciklama != null)
                      Text(
                        aciklama!,
                        style: TextStyle(fontSize: 12, color: renkler.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: renkler.outline),
            ],
          ),
        ),
      ),
    );
  }
}