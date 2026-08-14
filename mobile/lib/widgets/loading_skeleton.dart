import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Veri yuklenirken gosterilen 'iskelet' kutusu.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  /// Bir kart gorunumu icin hazır ölçü
  const LoadingSkeleton.card({super.key})
    : width = double.infinity,
      height = 96,
      borderRadius = 16;

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}