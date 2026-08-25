import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_exception.dart';
import '../../models/meal_estimate.dart';
import '../../providers/meal_provider.dart';
import '../chat/shot_guide.dart';
import 'food_entry_sheet.dart';
import 'meal_confirm_sheet.dart';

/// Ogun ekleme akisi: kamera / galeri / yazarak.
///
/// Hem Kalori ekranindaki FAB hem tarif detayindaki 'Bu Tarifi Yaptim'
/// bunu kullanir. Doner: bir ogun EKLENDIYSE true.
Future<bool> baslatOgunEkle(
  BuildContext context,
  WidgetRef ref, {
  required String date,
  MealEstimate? hazir,
}) async {
  final secim = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 4),
            child: ShotGuide(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              'Tabağın yanına çatal veya bıçak koy — porsiyonu böylece '
              'daha doğru tahmin edebiliyoruz',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Kamera'),
            onTap: () => Navigator.of(context).pop('kamera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Galeriden seç'),
            onTap: () => Navigator.of(context).pop('galeri'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Yazarak ekle'),
            subtitle: const Text('Fotoğrafsız, kendin doldur'),
            onTap: () => Navigator.of(context).pop('yazi'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (secim == null || !context.mounted) return false;

  switch (secim) {
    case 'kamera':
      return _fotoAkis(context, ref, ImageSource.camera, date);
    case 'galeri':
      return _fotoAkis(context, ref, ImageSource.gallery, date);
    case 'yazi':
      return _elleAkis(context, ref, date, hazir);
  }
  return false;
}

Future<bool> _fotoAkis(
  BuildContext context,
  WidgetRef ref,
  ImageSource kaynak,
  String date,
) async {
  final XFile? secilen = await ImagePicker().pickImage(
    source: kaynak,
    maxWidth: 1600,
    imageQuality: 80,
  );
  if (secilen == null || !context.mounted) return false;

  // Gorme modeli cagrisi surerken engelleyici gosterge.
  unawaited(showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  ));

  MealEstimate tahmin;
  try {
    tahmin = await ref.read(mealPhotoServiceProvider).tahminEt(File(secilen.path));
  } catch (hata) {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (context.mounted) _uyar(context, 'Fotoğraf işlenemedi: ${friendlyErrorMessage(hata)}');
    return false;
  }
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  if (!context.mounted) return false;

  final eklendi = await showMealConfirmSheet(context, tahmin: tahmin, date: date);
  return eklendi == true;
}

Future<bool> _elleAkis(
  BuildContext context,
  WidgetRef ref,
  String date,
  MealEstimate? hazir,
) async {
  // Tarif onceden secili geldiyse (Bu Tarifi Yaptim): arama adimini
  // atla, onay kartini dogrudan tarifle dolu ac.
  if (hazir != null) {
    final eklendi = await showMealConfirmSheet(
      context,
      tahmin: hazir,
      date: date,
      manuel: true,
    );
    return eklendi == true;
  }

  final sonuc = await showFoodEntrySheet(context, date: date);
  if (sonuc == 'eklendi') return true;
  if (sonuc == 'elle' && context.mounted) {
    const bosTahmin = MealEstimate(
      dishName: '',
      portion: 'orta',
      estimatedGrams: 0,
      imageHash: '',
    );
    final eklendi = await showMealConfirmSheet(
      context,
      tahmin: bosTahmin,
      date: date,
      manuel: true,
    );
    return eklendi == true;
  }
  return false;
}

void _uyar(BuildContext context, String mesaj) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mesaj)));
}