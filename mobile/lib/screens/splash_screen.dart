import 'package:flutter/material.dart';

/// Uygulama acilirken oturum kontrol edilirken gosterilen ekran.
///
/// authProvider.build() (_restoreSession) calisirken router burayi
/// tutar; sonuc gelince (giris var/yok) router OTOMATIK yonlendirir -
/// bu ekran KENDI BASINA hicbir yonlendirme yapmaz.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}