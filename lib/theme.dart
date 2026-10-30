import 'package:flutter/material.dart';

/// Warna khas Ngaji, sama dengan logo: hijau toska, emas, dan krem.
abstract final class AppColors {
  static const teal = Color(0xFF0F766E);
  static const tealDark = Color(0xFF0B4F4A);
  static const gold = Color(0xFFF4C152);
  static const goldDeep = Color(0xFFB7862A);
  static const cream = Color(0xFFFAF6EE);
  static const night = Color(0xFF0F1A19);

  /// Gradasi untuk kartu utama (beranda, header surat).
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF13897F), tealDark],
  );
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.teal,
    brightness: brightness,
  ).copyWith(
    primary: dark ? const Color(0xFF5ECBBE) : AppColors.teal,
    secondary: dark ? AppColors.gold : AppColors.goldDeep,
    surface: dark ? AppColors.night : AppColors.cream,
    surfaceContainerLowest: dark ? const Color(0xFF142321) : Colors.white,
  );
  final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0.5,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      shape: rounded.copyWith(side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
    ),
    listTileTheme: ListTileThemeData(shape: rounded),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: scheme.onSurface),
      ),
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerLowest),
      side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
      shape: WidgetStatePropertyAll(rounded),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
    ),
    tabBarTheme: TabBarThemeData(
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      indicatorColor: scheme.primary,
      dividerColor: scheme.outlineVariant.withValues(alpha: 0.5),
    ),
  );
}
