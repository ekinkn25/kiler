import 'package:flutter/material.dart';

import '../../widgets/widgets.dart';
import 'package:go_router/go_router.dart';

/// Tasarim sistemi vitrin ekrani.
///
/// GECICI: gercek ekranlar geldikce widget'lar oraya tasinacak, bu ekran
/// gelistirme boyunca 'hepsi dogru gorunuyor mu' kontrolu icin kalacak.
class WidgetShowcaseScreen extends StatefulWidget {
  const WidgetShowcaseScreen({super.key});

  @override
  State<WidgetShowcaseScreen> createState() => _WidgetShowcaseScreenState();
}

class _WidgetShowcaseScreenState extends State<WidgetShowcaseScreen> {
  bool _loadingButton = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasarım Sistemi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _baslik(context, 'AppButton'),
          AppButton(label: 'Birincil Buton', icon: Icons.check, onPressed: () {}),
          const SizedBox(height: 8),
          AppButton(
            label: 'İkincil Buton',
            variant: AppButtonVariant.secondary,
            onPressed: () {},
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Yükleniyor',
            loading: _loadingButton,
            onPressed: () {
              setState(() => _loadingButton = true);
              Future<void>.delayed(const Duration(seconds: 2), () {
                if (mounted) setState(() => _loadingButton = false);
              });
            },
          ),
          const SizedBox(height: 24),
          _baslik(context, 'AppCard'),
          const AppCard(child: Text('Sıradan bir kart içeriği.')),
          const SizedBox(height: 8),
          AppCard(
            onTap: () {},
            child: const Text('Dokunulabilir kart (min 48dp).'),
          ),
          const SizedBox(height: 24),
          _baslik(context, 'StatusChip'),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(type: StatusChipType.available),
              StatusChip(type: StatusChipType.missing),
              StatusChip(type: StatusChipType.unknown),
              StatusChip(type: StatusChipType.warning),
              StatusChip(
                type: StatusChipType.available,
                label: 'Kırmızı Mercimek: Var',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _baslik(context, 'EmptyState'),
          const EmptyIllustration(icon: Icons.restaurant_menu),
          const SizedBox(height: 16),
          const EmptyState(
            icon: Icons.restaurant_menu,
            illustrated: true,
            title: 'Kilerin boş',
            message: 'Fotoğraf çekerek veya barkod tarayarak ekleyebilirsin.',
            // actionLabel: 'Malzeme Ekle',
            // onAction: () {},
          ),
          
          const SizedBox(height: 24),
          EmptyState(
            icon: Icons.restaurant_menu,
            illustrated: true,
            title: 'Bugünlük bu kadar!',
            message: 'Kilerine bir şeyler ekle ya da yarın tekrar bak.',
            actionLabel: 'Fotoğraf çek',
            actionIcon: Icons.photo_camera_outlined,
            onAction: () => context.push('/foto'),
            secondaryActionLabel: 'Barkod okut',
            secondaryActionIcon: Icons.qr_code_scanner,
            onSecondaryAction: () => context.push('/tara'),
          ),

          const SizedBox(height: 24),
          _baslik(context, 'LoadingSkeleton'),
          const LoadingSkeleton(width: 200),
          const SizedBox(height: 8),
          const LoadingSkeleton.card(),
          const SizedBox(height: 24),
          _baslik(context, 'UndoSnackBar'),
          AppButton(
            label: 'Sil ve Geri Al Göster',
            variant: AppButtonVariant.secondary,
            onPressed: () {
              UndoSnackBar.show(
                context,
                message: 'Domates silindi.',
                onUndo: () {},
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _baslik(BuildContext context, String metin) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        metin,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
} 