import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Gradient stand-in for a vendor cover photo, deterministic per salon.
class SalonCover extends StatelessWidget {
  const SalonCover({
    super.key,
    required this.seed,
    required this.emoji,
    this.borderRadius,
    this.emojiSize = 34,
  });

  final int seed;
  final String emoji;
  final BorderRadius? borderRadius;
  final double emojiSize;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.coverGradient(seed);
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: emojiSize)),
      ),
    );
  }
}
