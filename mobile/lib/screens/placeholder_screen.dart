import 'package:flutter/material.dart';

/// Henuz gercek ekrani yazilmamis rotalar icin GECICI govde.
///
/// NEDEN: her yeni rota icin ayri bos ekran dosyasi acmak yerine, tek bir
/// yer tutucu tum 'yapim asamasinda' rotalarda kullanilir. Gercek ekran
/// yazildiginda ilgili GoRoute'un builder'i degistirilir, bu widget'a
/// dokunulmaz.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, super.key, this.detail});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction, size: 48, color: colors.outline),
              const SizedBox(height: 16),
              Text('Yapım aşamasında', style: Theme.of(context).textTheme.titleMedium),
              if (detail != null) ...[
                const SizedBox(height: 8),
                Text(detail!, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}