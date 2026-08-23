import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../models/pantry_item.dart';
import '../../providers/pantry_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/pantry/pantry_item_tile.dart';

/// KILER sekmesi (W3-T18).
///
/// ELLE METIN GIRISI YOK (kapsam karari): kiler yalnizca barkod okutma
/// ve fotograf tanima ile dolar. Bu yuzden ekranda '+ ekle' alani degil,
/// ust barda iki yonlendirme butonu var.
class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  /// Istegi suren satir. Ayni satira cift dokunusu engeller.
  int? _islemdekiId;

  Future<void> _durumDegistir(PantryItem kayit, {required bool stillHave}) async {
    setState(() => _islemdekiId = kayit.id);
    try {
      await ref.read(pantryProvider.notifier).durumDegistir(
            kayit.id,
            stillHave: stillHave,
          );
      if (!mounted) return;
      _bilgi(
        stillHave
            ? '${kayit.ingredient.displayName} için 7 gün daha sayacağız.'
            : '${kayit.ingredient.displayName} listeden çıkarıldı.',
      );
    } catch (hata) {
      if (!mounted) return;
      _bilgi('Güncellenemedi: ${friendlyErrorMessage(hata)}');
    } finally {
      if (mounted) setState(() => _islemdekiId = null);
    }
  }

  void _bilgi(String mesaj) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mesaj), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final kiler = ref.watch(pantryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiler'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Fotoğraf Çek',
            icon: const Icon(Icons.photo_camera_outlined),
            onPressed: () => context.push('/foto'),
          ),
          IconButton(
            tooltip: 'Barkod Okut',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push('/tara'),
          ),
        ],
      ),
      body: kiler.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              LoadingSkeleton(width: 140),
              SizedBox(height: 12),
              LoadingSkeleton.card(),
              SizedBox(height: 8),
              LoadingSkeleton.card(),
            ],
          ),
        ),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Kiler yüklenemedi',
          message: friendlyErrorMessage(error),
          actionLabel: 'Tekrar dene',
          onAction: () => unawaited(ref.read(pantryProvider.notifier).yenile()),
        ),
        data: (_) => _govde(),
      ),
    );
  }

  Widget _govde() {
    final gruplar = ref.watch(pantryGroupsProvider);

    if (gruplar.kesinVar.isEmpty && gruplar.eminDegiliz.isEmpty) {
      return EmptyState(
        icon: Icons.kitchen_outlined,
        illustrated: true,
        title: 'Kilerin henüz boş',
        message: 'Fotoğraf çekerek ya da barkod okutarak doldurabilirsin.',
        actionLabel: 'Fotoğraf çek',
        actionIcon: Icons.photo_camera_outlined,
        onAction: () => context.push('/foto'),
        secondaryActionLabel: 'Barkod okut',
        secondaryActionIcon: Icons.qr_code_scanner,
        onSecondaryAction: () => context.push('/tara'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(pantryProvider.notifier).yenile(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (gruplar.kesinVar.isNotEmpty) ...[
            _BolumBasligi(
              baslik: 'Kesin var',
              adet: gruplar.kesinVar.length,
            ),
            for (final kayit in gruplar.kesinVar)
              PantryItemTile(item: kayit),
            const SizedBox(height: 20),
          ],
          if (gruplar.eminDegiliz.isNotEmpty) ...[
            _BolumBasligi(
              baslik: 'Emin değiliz',
              adet: gruplar.eminDegiliz.length,
              aciklama: 'Bunları en son 7 gün önce gördük.',
            ),
            for (final kayit in gruplar.eminDegiliz)
              PantryItemTile(
                item: kayit,
                busy: _islemdekiId == kayit.id,
                onStillHave: () =>
                    unawaited(_durumDegistir(kayit, stillHave: true)),
                onFinished: () =>
                    unawaited(_durumDegistir(kayit, stillHave: false)),
              ),
          ],
        ],
      ),
    );
  }
}

class _BolumBasligi extends StatelessWidget {
  const _BolumBasligi({
    required this.baslik,
    required this.adet,
    this.aciklama,
  });

  final String baslik;
  final int adet;
  final String? aciklama;

  @override
  Widget build(BuildContext context) {
    final ColorScheme renkler = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                baslik,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                '($adet)',
                style: TextStyle(color: renkler.onSurfaceVariant),
              ),
            ],
          ),
          if (aciklama != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                aciklama!,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: renkler.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}