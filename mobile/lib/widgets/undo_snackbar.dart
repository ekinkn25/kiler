import 'package:flutter/material.dart';

/// 'Geri Al' aksiyonlu standart SnackBar. kalici silme islemlerinde (kiler kaydi, tarif favorisi vb.) HER yerde ayni sure/gorunumle tekrar SnackBar kurmak yerine tek bir çağrı yeterli olsun.
class UndoSnackBar {
  const UndoSnackBar._();

  static const Duration _duration = Duration(seconds: 4);

  /// SnackBar'i gosterir. Kullanici 'Geri Al'a basarsa [onUndo] cagrilir.
  static void show(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: _duration,
          action: SnackBarAction(label: 'Geri Al', onPressed: onUndo),
        ),
      );
  }
}