import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kreo Notes - Dark Minimalist Theme
/// Matching the premium dark design from Kreo Calendar
class AppColors {
  AppColors._();

  // Minimalist Colors
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF101010);
  static const Color surfaceVariant = Color(0xFF202020);
  static const Color onBackground = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFF8899A6);

  // Primary is white for high contrast
  static const Color primary = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFFFFFFFF);

  // Semantic Colors
  static const Color success = Color(0xFF4ECDC4);
  static const Color warning = Color(0xFFFFB347);
  static const Color error = Color(0xFFFF3B30);

  // Divider
  static const Color divider = Color(0xFF2D3E50);

  // Glass effect
  // Glass effect
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassSurface = Color(0x1AFFFFFF);

  // Note Background Colors (Keep Style - Dark)
  static const Color noteDefault = Color(0xFF000000);
  static const Color noteRed = Color(0xFF5C2B29);
  static const Color noteOrange = Color(0xFF614A19);
  static const Color noteYellow = Color(0xFF635D19);
  static const Color noteGreen = Color(0xFF345920);
  static const Color noteCyan = Color(0xFF16504B);
  static const Color noteBlue = Color(0xFF2D555E);
  static const Color notePurple = Color(0xFF42275E);
  static const Color notePink = Color(0xFF5B2245);
  static const Color noteBrown = Color(0xFF442F19);
  static const Color noteGrey = Color(0xFF3C3F43);
}

/// Clean Typography using Poppins
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _poppins({
    required double size,
    FontWeight weight = FontWeight.normal,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // Display
  static TextStyle displayLarge({Color? color}) => _poppins(
    size: 42,
    weight: FontWeight.w600,
    color: color,
    letterSpacing: -1.0,
  );
  static TextStyle displayMedium({Color? color}) => _poppins(
    size: 32,
    weight: FontWeight.w600,
    color: color,
    letterSpacing: -0.5,
  );
  static TextStyle displaySmall({Color? color}) =>
      _poppins(size: 24, weight: FontWeight.w500, color: color);

  // Headlines
  static TextStyle headlineLarge({Color? color}) =>
      _poppins(size: 22, weight: FontWeight.w600, color: color);
  static TextStyle headlineMedium({Color? color}) =>
      _poppins(size: 18, weight: FontWeight.w600, color: color);
  static TextStyle headlineSmall({Color? color}) =>
      _poppins(size: 16, weight: FontWeight.w600, color: color);

  // Titles
  static TextStyle titleLarge({Color? color}) =>
      _poppins(size: 17, weight: FontWeight.w500, color: color);
  static TextStyle titleMedium({Color? color}) =>
      _poppins(size: 15, weight: FontWeight.w500, color: color);
  static TextStyle titleSmall({Color? color}) =>
      _poppins(size: 13, weight: FontWeight.w500, color: color);

  // Body
  static TextStyle bodyLarge({Color? color}) =>
      _poppins(size: 15, weight: FontWeight.w400, color: color, height: 1.5);
  static TextStyle bodyMedium({Color? color}) =>
      _poppins(size: 14, weight: FontWeight.w400, color: color, height: 1.5);
  static TextStyle bodySmall({Color? color}) =>
      _poppins(size: 12, weight: FontWeight.w400, color: color, height: 1.4);

  // Labels
  static TextStyle labelLarge({Color? color}) =>
      _poppins(size: 14, weight: FontWeight.w500, color: color);
  static TextStyle labelMedium({Color? color}) =>
      _poppins(size: 12, weight: FontWeight.w500, color: color);
  static TextStyle labelSmall({Color? color}) => _poppins(
    size: 10,
    weight: FontWeight.w500,
    color: color,
    letterSpacing: 0.5,
  );

  // Notes-specific
  static TextStyle pageTitle({Color? color}) =>
      _poppins(size: 28, weight: FontWeight.w600, color: color);
  static TextStyle blockText({Color? color}) =>
      _poppins(size: 16, weight: FontWeight.w400, color: color, height: 1.6);
}

/// Dark Theme Configuration
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: const Color(0xFFF5F5F7),
    colorScheme: const ColorScheme.light(
      primary: Colors.black,
      secondary: Colors.black,
      surface: Colors.white,
      surfaceContainerHighest: Color(0xFFF2F2F7),
      error: AppColors.error,
      onSurface: Colors.black,
      onSurfaceVariant: Colors.black54,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF5F5F7),
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppTextStyles.titleLarge(color: Colors.black),
      iconTheme: const IconThemeData(color: Colors.black),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: Colors.black12, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.transparent,
      border: InputBorder.none,
      focusedBorder: InputBorder.none,
      enabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      hintStyle: AppTextStyles.bodyMedium(color: Colors.black38),
    ),
    textTheme: TextTheme(
      bodyMedium: AppTextStyles.bodyMedium(color: Colors.black),
      bodySmall: AppTextStyles.bodySmall(color: Colors.black54),
      titleMedium: AppTextStyles.titleMedium(color: Colors.black),
      headlineSmall: AppTextStyles.headlineSmall(color: Colors.black),
      headlineMedium: AppTextStyles.headlineMedium(color: Colors.black),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: Colors.white,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: Colors.white,
      surface: AppColors.background,
      surfaceContainerHighest: Color(0xFF202020),
      error: AppColors.error,
      onSurface: Colors.white,
      onSurfaceVariant: Colors.grey,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppTextStyles.titleLarge(color: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: const CardThemeData(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: Colors.white24, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.transparent,
      border: InputBorder.none,
      focusedBorder: InputBorder.none,
      enabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      hintStyle: AppTextStyles.bodyMedium(color: Colors.grey),
    ),
    textTheme: TextTheme(
      bodyMedium: AppTextStyles.bodyMedium(color: Colors.white),
      bodySmall: AppTextStyles.bodySmall(color: Colors.grey),
      titleMedium: AppTextStyles.titleMedium(color: Colors.white),
      headlineSmall: AppTextStyles.headlineSmall(color: Colors.white),
      headlineMedium: AppTextStyles.headlineMedium(color: Colors.white),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1A1A1A),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
