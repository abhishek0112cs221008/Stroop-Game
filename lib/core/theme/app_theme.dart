import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      error: AppColors.incorrect,
      onError: Colors.white,
      surface: isDark ? AppColors.bgDark : AppColors.bgLight,
      onSurface: isDark ? Colors.white : const Color(0xFF0D1117),
      surfaceContainerHighest: isDark
          ? AppColors.card2Dark
          : const Color(0xFFEAECF0),
      primaryContainer: isDark ? AppColors.cardDark : const Color(0xFFE8F0FE),
      onPrimaryContainer: isDark ? AppColors.primary : AppColors.secondary,
    );

    final textTheme = GoogleFonts.dancingScriptTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      cardTheme: CardThemeData(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dancingScript(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF0D1117),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
        thickness: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
