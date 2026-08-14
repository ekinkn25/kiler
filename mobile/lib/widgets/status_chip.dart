import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

//status chip in temsil edebileceği anlamlar

enum StatusChipType {
  available,
  missing,
  unknown,
  warning,
}

class StatusChip extends StatelessWidget {
  const StatusChip({required this.type, super.key, this.label});

  final StatusChipType type;
  final String? label;

  static const Map<StatusChipType, IconData> _icons = {
    StatusChipType.available: Icons. check_circle,
    StatusChipType.missing: Icons.cancel,
    StatusChipType.unknown: Icons.help,
    StatusChipType.warning: Icons.warning_amber_rounded,
  };

  static const Map<StatusChipType, String> _defaultLabels = {
    StatusChipType.available: 'Var',
    StatusChipType.missing: 'Yok',
    StatusChipType.unknown: 'Bilinmiyor',
    StatusChipType.warning: 'Uyarı',
  };

  Color _colorFor(AppColors colors) {
    switch (type) {
      case StatusChipType.available:
        return colors.available;
      case StatusChipType.missing:
        return colors.missing;
      case StatusChipType.unknown:
        return colors.unknown;
      case StatusChipType.warning:
        return colors.warning;
    }
  }
   @override
  Widget build(BuildContext context) {
    final Color color = _colorFor(context.appColors);
    final String text = label ?? _defaultLabels[type]!;
    // "Ekranda göstereceğim nihai metin (text), eğer yazılımcı bana dışarıdan özel bir label verdiyse odur. Ama eğer vermediyse (??), git varsayılan etiketler sözlüğüne bak, bu durum tipinin (type) Türkçe karşılığını bul ve oradan kesinlikle dolu bir kelime geleceğine garanti vererek (!) onu kullan."

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icons[type], size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
