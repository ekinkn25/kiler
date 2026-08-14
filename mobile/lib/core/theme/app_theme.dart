import 'package:flutter/material.dart';
import 'app_colors.dart';
//uygulamanın tek tema tanımı bu dosyada

class AppTheme{
  const AppTheme._(); 
  //const AppTheme._() bu satır diyor ki bu sınıfı dışarıda yanlışlıkla yeni bir kopyasını (instance) oluşturulmasını engeller = prvate constructer denilir.
  static const Color _seedColor = Color(0xFF2E7D32);


  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
    extensions: const [AppColors.standart],
  );


  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      ),
    extensions: const [AppColors.standart],
  );
}