import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';

/// Minimal profil ekrani. NEDEN BASIT: bu ekranin asil amaci CIKIS
/// YAPMA noktasi olmak (W3-T01 kabul kriteri) - profil duzenleme ayri
/// bir mobil gorevde genisletilir.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kullanici = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('E-posta', style: Theme.of(context).textTheme.labelMedium),
                  Text(kullanici?.email ?? '—'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Çıkış Yap',
              variant: AppButtonVariant.secondary,
              onPressed: () => ref.read(authProvider.notifier).logout(),
            ),
          ],
        ),
      ),
    );
  }
}