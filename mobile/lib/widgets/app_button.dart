import 'package:flutter/material.dart';

//[AppButton]'un görsel biçimi | enum belirli ve kısıtlı seçenekler sunan bir menü gibi 
// primaru: ekranda kullanıcının yapmasını en çok istediğimiz en dikkat çekici ana eylemler   örn giriş yap kayıt ol
// secondary: ana eylemin yanında duran daha az dikkat çekmesi gereken alternatif eylem   örn iptal geri dön
enum AppButtonVariant {primary, secondary}

//uygulamanın standart butonu 
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.loading = false,
    this.variant = AppButtonVariant.primary,
  });

  static const double height = 56;

  final String label;
  final VoidCallback ? onPressed;
  final IconData? icon;
  final bool loading;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final Widget child = loading
        ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5,),
          )
        : icon == null
          ? Text(label)
          : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Text(label),
            ],
          );
  
  final VoidCallback? efectiveOnPressed = loading ? null : onPressed;

  return SizedBox(
    height: height,
    width: double.infinity,
    child: variant == AppButtonVariant.secondary
      ? OutlinedButton(onPressed: efectiveOnPressed, child: child)
      : FilledButton(onPressed: efectiveOnPressed, child: child),
  );
  }
}