import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import 'hata_kaydi.dart';

/// Ates-et-unut cagrilarini guvenli hale getirir (W4-T15).
///
/// unawaited(...) ile baslatilan bir Future icinde hata dogarsa hicbir yerde
/// yakalanmaz: runZonedGuarded onu loglar ama KULLANICI hicbir sey gormez -
/// dokundugu buton sessizce hicbir sey yapmamis olur. Bu yardimci hem
/// loglar hem de kullaniciya notr bir mesaj gosterir.
///
/// Doner: islem basariliysa sonucu, hata olduysa null. Cagiran taraf
/// `== null` ile basarisizligi anlayabilir.
Future<T?> guvenliCalistir<T>(
  Future<T> Function() islem, {
  required String etiket,
  BuildContext? context,
  String? onEk,
}) async {
  try {
    return await islem();
  } catch (hata, iz) {
    HataKaydi.yaz(hata, iz, kaynak: etiket);
    if (context != null && context.mounted) {
      final metin = friendlyErrorMessage(hata);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(onEk == null ? metin : '$onEk $metin')),
        );
    }
    return null;
  }
}
