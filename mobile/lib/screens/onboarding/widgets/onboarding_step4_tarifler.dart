import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/onboarding_provider.dart';
import '../../../widgets/hata_gorunumu.dart';

class OnboardingStep4Tarifler extends ConsumerWidget {
  const OnboardingStep4Tarifler({
    required this.seciliTarifIdleri, required this.maxSecim, required this.onToggle, super.key,
  });

  final Set<String> seciliTarifIdleri;
  final int maxSecim;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tarifler = ref.watch(onboardingRecipeChoicesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sevdiğin 5 yemeği seç', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('${seciliTarifIdleri.length}/$maxSecim seçildi',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        Expanded(
          child: tarifler.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => HataDurumu(
              hata: e,
              baslik: 'Tarifler yüklenemedi',
              onTekrar: () => ref.invalidate(onboardingRecipeChoicesProvider),
            ),
            data: (liste) => GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85,
              ),
              itemCount: liste.length,
              itemBuilder: (context, i) {
                final tarif = liste[i];
                final secili = seciliTarifIdleri.contains(tarif.id);
                return GestureDetector(
                  onTap: () => onToggle(tarif.id),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: tarif.imageUrl == null
                            ? Container(color: Theme.of(context).colorScheme.surfaceContainerHighest)
                            : CachedNetworkImage(imageUrl: tarif.imageUrl!, fit: BoxFit.cover),
                      ),
                      Positioned(
                        left: 0, right: 0, bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                          child: Text(tarif.title,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      if (secili)
                        Positioned(
                          top: 8, right: 8,
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: const Icon(Icons.check, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}