import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'screens/dev/dev_home_screen.dart';

void main() {
  // ProviderScope tum Riverpod saglayicilarinin kokudur; uygulamanin
  // en disinda olmalidir.
  runApp(const ProviderScope(child: KaloriApp()));
}

class KaloriApp extends StatelessWidget {
  const KaloriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      // Tema W1-T15'te, yonlendirme W1-T14'te gelecek.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      home: const DevHomeScreen(),
    );
  }
}