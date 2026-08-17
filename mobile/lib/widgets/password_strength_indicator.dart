import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/validators.dart';

class PasswordStrengthIndicator extends StatelessWidget{
  const PasswordStrengthIndicator ({
    required this.password, 
    super.key,
  });
  
  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final guc = calculatePasswordStength(password);
    final colors = context.appColors;
    final (renk, etiket, oran) = switch (guc) {
      PasswordStrength.weak => (colors.missing, 'Zayıf', 1 / 3),
      PasswordStrength.medium => (colors.warning, 'Orta', 2 / 3),
      PasswordStrength.strong => (colors.available, 'Güçlü', 1.0),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8,),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: oran,
            minHeight: 6,
            backgroundColor: renk.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(renk)
          ),
        ),
        const SizedBox(height: 4,),
        Text(etiket, style: TextStyle(color: renk, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}