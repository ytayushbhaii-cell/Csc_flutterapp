import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Material 3 theme builder for CSC Smart Toolkit.
/// Matches the Expo app's light and dark palettes exactly.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;

    final Color background =
        isLight ? AppColors.lightBackground : AppColors.darkBackground;
    final Color card = isLight ? AppColors.lightCard : AppColors.darkCard;
    final Color border = isLight ? AppColors.lightBorder : AppColors.darkBorder;
    final Color foreground =
        isLight ? AppColors.lightForeground : AppColors.darkForeground;
    final Color primary =
        isLight ? AppColors.lightPrimary : AppColors.darkPrimary;
    final Color primaryFg = isLight
        ? AppColors.lightPrimaryForeground
        : AppColors.darkPrimaryForeground;
    final Color muted = isLight ? AppColors.lightMuted : AppColors.darkMuted;
    final Color mutedFg = isLight
        ? AppColors.lightMutedForeground
        : AppColors.darkMutedForeground;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: primaryFg,
      primaryContainer: isLight ? AppColors.lightAccent : AppColors.darkAccent,
      onPrimaryContainer: isLight
          ? AppColors.lightAccentForeground
          : AppColors.darkAccentForeground,
      secondary: primary,
      onSecondary: primaryFg,
      secondaryContainer: muted,
      onSecondaryContainer: mutedFg,
      error: AppColors.error,
      onError: Colors.white,
      surface: card,
      onSurface: foreground,
      surfaceContainerHighest: muted,
      outline: border,
      outlineVariant: border,
      scrim: Colors.black54,
      inverseSurface: foreground,
      onInverseSurface: background,
      inversePrimary: isLight ? AppColors.darkPrimary : AppColors.lightPrimary,
    );

    final textTheme = GoogleFonts.interTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).apply(
      bodyColor: foreground,
      displayColor: foreground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        iconTheme: IconThemeData(color: foreground),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: isLight ? AppColors.lightAccent : AppColors.darkAccent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 24);
          }
          return IconThemeData(color: mutedFg, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final style = GoogleFonts.inter(fontSize: 12);
          if (states.contains(WidgetState.selected)) {
            return style.copyWith(
                color: primary, fontWeight: FontWeight.w600);
          }
          return style.copyWith(color: mutedFg);
        }),
        surfaceTintColor: Colors.transparent,
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryFg,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        labelStyle: TextStyle(color: mutedFg),
        hintStyle: TextStyle(color: mutedFg),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      iconTheme: IconThemeData(color: foreground),
      listTileTheme: ListTileThemeData(
        tileColor: card,
        textColor: foreground,
        iconColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
