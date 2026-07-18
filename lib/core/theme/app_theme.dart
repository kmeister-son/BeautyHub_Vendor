import 'package:flutter/material.dart';

/// Brand palette and Material 3 theme for BeautyHub.
abstract final class AppColors {
  static const seed = Color(0xFF7C3AED); // deep violet
  static const surface = Color(0xFFFAF8F5); // warm off-white
  static const ink = Color(0xFF1E1B22);
  static const inkSoft = Color(0xFF6E6879);
  static const gold = Color(0xFFE0A94E);

  // Dark-mode counterparts (violet-tinted neutrals).
  static const surfaceDark = Color(0xFF141118);
  static const cardDark = Color(0xFF211D28);
  static const inkDark = Color(0xFFF1EDF6);
  static const inkSoftDark = Color(0xFFA79FB4);

  /// Cover gradients keyed by `Salon.coverSeed` — stand-ins for vendor
  /// photos until real imagery is wired in.
  static const coverGradients = <List<Color>>[
    [Color(0xFF9F7AEA), Color(0xFF5B21B6)],
    [Color(0xFF3B4B66), Color(0xFF16202F)],
    [Color(0xFF6EC6B5), Color(0xFF2A7D6D)],
    [Color(0xFFF29BB6), Color(0xFFC2477C)],
    [Color(0xFF7FB5E8), Color(0xFF3468A5)],
    [Color(0xFFE8A87C), Color(0xFFB4562F)],
    [Color(0xFFE9B8D4), Color(0xFF9D5A9B)],
    [Color(0xFF8A8FA3), Color(0xFF3D4152)],
  ];

  static List<Color> coverGradient(int seed) =>
      coverGradients[seed % coverGradients.length];
}

/// Widgets rely on two scheme tokens both themes must set: `onSurfaceVariant`
/// for secondary text and `surfaceContainerLowest` for elevated surfaces
/// (cards, chips, nav bar, inputs).
abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      surface: AppColors.surface,
    ).copyWith(
      onSurfaceVariant: AppColors.inkSoft,
      surfaceContainerLowest: Colors.white,
    );
    return _themed(
      scheme,
      ink: AppColors.ink,
      hairline: Colors.black.withValues(alpha: 0.06),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
      surface: AppColors.surfaceDark,
    ).copyWith(
      onSurfaceVariant: AppColors.inkSoftDark,
      surfaceContainerLowest: AppColors.cardDark,
    );
    return _themed(
      scheme,
      ink: AppColors.inkDark,
      hairline: Colors.white.withValues(alpha: 0.08),
    );
  }

  static ThemeData _themed(
    ColorScheme scheme, {
    required Color ink,
    required Color hairline,
  }) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: base.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: hairline),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primary.withValues(alpha: 0.12),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      dividerTheme: DividerThemeData(color: hairline, space: 1),
    );
  }
}
