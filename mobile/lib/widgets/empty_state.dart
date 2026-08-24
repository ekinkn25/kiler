import 'package:flutter/material.dart';
import 'package:kalori/widgets/empty_illustration.dart';

import 'app_button.dart';

/// Bos liste/veri olmadigi zaman gosterilen standart ekran govdesi.
/// Kiler bossa, tarif onerisi kalmayinca, sohbet gecmisi yoksa vb. HER yerde ayni gorsel dil: ikon + baslik + aciklama + (opsiyonel) aksiyon.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    super.key,
    this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.secondaryActionLabel,
    this.secondaryActionIcon,
    this.onSecondaryAction,
    this.illustrated = false,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;
  final VoidCallback? onSecondaryAction;
  final bool illustrated; // true ise büyük görsel çizilir
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool birincilVar = actionLabel != null && onAction != null;
    final bool ikincilVar = secondaryActionLabel != null && onSecondaryAction != null;

    return Center(
      child : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (illustrated)
                EmptyIllustration(icon: icon)
              else
                Icon(icon, size: 64, color: colors.outline),
              SizedBox(height: illustrated? 24 : 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (footer != null ) ...[
                const SizedBox(height: 24,),
                footer!,
              ],
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
              if (birincilVar) ... [
                const SizedBox(height: 24),
                AppButton(label: actionLabel!, icon:actionIcon, onPressed: onAction,),
              ],
              if (ikincilVar) ... [
                SizedBox(height: birincilVar? 12: 24),
                AppButton(label: secondaryActionLabel!, icon:secondaryActionIcon, variant:AppButtonVariant.secondary, onPressed: onSecondaryAction,),
              ],
            ],
          ),
        ),
      ),
    );
  }
}