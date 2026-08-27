import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dio/dio.dart';

import '../../core/hata/hata_kaydi.dart';
import '../../core/network/api_exception.dart';
import '../../models/enums.dart';
import '../../models/pantry_item.dart';
import '../../providers/pantry_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../widgets/chat/detected_ingredients_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/hata_gorunumu.dart';
import '../../widgets/ingredient_search_dialog.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/pantry/pantry_item_tile.dart';

/// KILER sekmesi (W3-T18 + W3-T21).
///
/// '+' menusu: Kamera (fotograftan tespit), Barkod (W3-T20 - simdilik
/// placeholder), Yazi ile ekle. Ust barda alisveris listesine kisayol.
class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  final ImagePicker _secici = ImagePicker();
  int? _islemdekiId;
  bool _mesgul = false;

  // ---------------------------------------------------------------
  // Durum degistirme (var / emin degilim / yok)
  // ---------------------------------------------------------------

  Future<void> _durumDegistir(PantryItem kayit, Availability hedef) async {
    setState(() => _islemdekiId = kayit.id);
    try {
      await ref.read(pantryProvider.notifier).durumDegistir(kayit.id, hedef: hedef);
      if (!mounted) return;

      if (hedef == Availability.finished) {
        // 'Yok' -> kilerden dustu, alisveris listesine ekle.
        await ref.read(shoppingListProvider.notifier)
            .elleEkle(kayit.ingredient.displayName);
        if (!mounted) return;
        _bilgi('${kayit.ingredient.displayName} bitti; alışveriş listene eklendi.');
      } else if (hedef == Availability.unknown) {
        _bilgi('${kayit.ingredient.displayName} "emin değiliz"e taşındı.');
      } else {
        _bilgi('${kayit.ingredient.displayName} için 7 gün daha sayacağız.');
      }
    } catch (hata) {
      if (!mounted) return;
      _bilgi('Güncellenemedi: ${friendlyErrorMessage(hata)}');
    } finally {
      if (mounted) setState(() => _islemdekiId = null);
    }
  }

  // ---------------------------------------------------------------
  // '+' menusu: kamera / barkod / yazi
  // ---------------------------------------------------------------

  Future<void> _ekleMenusu() async {
    final secim = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Fotoğraf çek'),
              subtitle: const Text('Malzemeleri tanıyıp ekleyeyim'),
              onTap: () => Navigator.of(context).pop('foto'),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Barkod okut'),
              onTap: () => Navigator.of(context).pop('barkod'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Yazarak ekle'),
              subtitle: const Text('Örn: elma, süt, yumurta'),
              onTap: () => Navigator.of(context).pop('yazi'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (secim == null || !mounted) return;

    switch (secim) {
      case 'foto':
        await _fotoylaEkle();
      case 'barkod':
        // W3-T20 kapsaminda; simdilik placeholder.
        if (mounted) unawaited(context.push('/tara'));
      case 'yazi':
        await _yazarakEkle();
    }
  }

  Future<void> _yazarakEkle() async {
    final malzeme = await showIngredientSearchDialog(context);
    if (malzeme == null || !mounted) return;
    try {
      await ref.read(pantryProvider.notifier).elleEkle(malzeme.id);
      if (!mounted) return;
      _bilgi('${malzeme.displayName} kilerine eklendi.');
    } catch (hata) {
      if (!mounted) return;
      _bilgi('Eklenemedi: ${friendlyErrorMessage(hata)}');
    }
  }

  Future<void> _fotoylaEkle() async {
    try {
      final XFile? secilen = await _secici.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (secilen == null || !mounted) return;

      setState(() => _mesgul = true);
      final tespitler = await ref
          .read(pantryConfirmServiceProvider)
          .fotodanTespit(File(secilen.path));
      if (!mounted) return;
      setState(() => _mesgul = false);

      final secilenCanonical =
          await showDetectedIngredientsSheet(context, tespitler: tespitler);
      if (secilenCanonical == null || secilenCanonical.isEmpty || !mounted) {
        return;
      }

      final adet = await ref
          .read(pantryConfirmServiceProvider)
          .kilereEkle(secilenCanonical);
      if (!mounted) return;
      await ref.read(pantryProvider.notifier).yenile();
      _bilgi('$adet malzeme kilerine eklendi.');
    } catch (hata, iz) {
      if (!mounted) return;
      setState(() => _mesgul = false);
      HataKaydi.yaz(hata, iz, kaynak: 'kiler.fotodanTespit');

      // W4-T15: /vision/ingredients sozlesmesi list[...] oldugu icin
      // sunucu 'degraded' bayragi tasiyamiyor; dusus BURADA yapiliyor.
      // Gorme modeli coktugunde kullaniciyi cikmaza sokmuyoruz: ayni
      // amaca (kilere malzeme eklemek) ELLE ARAMA yoluyla ulasabilir.
      if (_gorunumSaglayiciArizasi(hata)) {
        _bilgi('Fotoğrafı şu an okuyamadık, malzemeyi arayarak ekleyebilirsin.');
        await _yazarakEkle();
        return;
      }
      _bilgi('Fotoğraf işlenemedi: ${friendlyErrorMessage(hata)}');
    }
  }

  /// Hata gorme modelinden mi geliyor, kullanicinin dosyasindan mi?
  ///
  /// 502/504 ve vision_* kodlari saglayici arizasi -> elle arama yoluna
  /// dusulur. 413/415/400 (dosya cok buyuk, desteklenmeyen tur) ve 429
  /// (gunluk kota) KULLANICIYA soylenir; elle aramaya kaydirmak bu
  /// durumlarda kafa karistirici olur.
  bool _gorunumSaglayiciArizasi(Object hata) {
    final ApiException? api = hata is DioException
        ? hata.apiException
        : (hata is ApiException ? hata : null);
    if (api == null) return false;
    if (api.code.startsWith('vision_') && api.code != 'vision_daily_limit') {
      return true;
    }
    return api.statusCode == 502 || api.statusCode == 504;
  }

  void _bilgi(String mesaj) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mesaj), duration: const Duration(seconds: 3)),
      );
  }

  // ---------------------------------------------------------------
  // Gorunum
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final kiler = ref.watch(pantryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiler'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Alışveriş listesi',
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/alisveris'),
          ),
          IconButton(
            tooltip: 'Ekle',
            icon: _mesgul
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.add),
            onPressed: _mesgul ? null : () => unawaited(_ekleMenusu()),
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
        error: (error, _) => HataDurumu(
          hata: error,
          baslik: 'Kiler yüklenemedi',
          onTekrar: () => unawaited(ref.read(pantryProvider.notifier).yenile()),
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
        message: 'Fotoğraf, barkod ya da yazarak ekleyebilirsin.',
        actionLabel: 'Malzeme ekle',
        actionIcon: Icons.add,
        onAction: () => unawaited(_ekleMenusu()),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(pantryProvider.notifier).yenile(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (gruplar.kesinVar.isNotEmpty) ...[
            _BolumBasligi(baslik: 'Kesin var', adet: gruplar.kesinVar.length),
            for (final kayit in gruplar.kesinVar)
              PantryItemTile(
                item: kayit,
                busy: _islemdekiId == kayit.id,
                onStatusChange: (hedef) =>
                    unawaited(_durumDegistir(kayit, hedef)),
              ),
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
                onStatusChange: (hedef) =>
                    unawaited(_durumDegistir(kayit, hedef)),
              ),
          ],
        ],
      ),
    );
  }
}

class _BolumBasligi extends StatelessWidget {
  const _BolumBasligi({required this.baslik, required this.adet, this.aciklama});

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
              Text('($adet)', style: TextStyle(color: renkler.onSurfaceVariant)),
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