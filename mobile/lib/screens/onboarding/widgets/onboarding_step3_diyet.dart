import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/onboarding_provider.dart';
import '../../../widgets/hata_gorunumu.dart';

class OnboardingStep3Diyet extends ConsumerWidget {
  const OnboardingStep3Diyet({
    required this.seciliDiyetKodlari, required this.seciliAlerjenKodlari,
    required this.onDiyetToggle, required this.onAlerjenToggle, super.key,
  });

  final Set<String> seciliDiyetKodlari;
  final Set<String> seciliAlerjenKodlari;
  final ValueChanged<String> onDiyetToggle;
  final ValueChanged<String> onAlerjenToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diyetler = ref.watch(dietTagsProvider);
    final alerjenler = ref.watch(allergensProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Diyet tercihlerin var mı?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          diyetler.when(
            loading: () => const CircularProgressIndicator(),
            // W4-T15: 'Yeniden dene' SART. Bu liste yuklenmezse kullanici
            // onboarding adiminda kilitli kalir - uygulamaya hic giremez.
            error: (e, _) => HataSatiriKucuk(
              mesaj: 'Diyet listesi yüklenemedi.',
              onTekrar: () => ref.invalidate(dietTagsProvider),
            ),
            data: (liste) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: liste.map((t) => FilterChip(
                label: Text(t.displayName),
                selected: seciliDiyetKodlari.contains(t.code),
                onSelected: (_) => onDiyetToggle(t.code),
              )).toList(),
            ),
          ),
          const SizedBox(height: 32),
          Text('Alerjin var mı?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          alerjenler.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => HataSatiriKucuk(
              mesaj: 'Alerjen listesi yüklenemedi.',
              onTekrar: () => ref.invalidate(allergensProvider),
            ),
            data: (liste) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: liste.map((a) => FilterChip(
                label: Text(a.displayName),
                selected: seciliAlerjenKodlari.contains(a.code),
                selectedColor: Theme.of(context).colorScheme.errorContainer,
                onSelected: (_) => onAlerjenToggle(a.code),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}