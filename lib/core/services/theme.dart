// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_sizes.dart';

// Enhanced color palette for admin panel design
class AppColors {
  // Primary gradient colors (Deep blue professional theme)
  static const Color primaryDark = Color(0xff00224D);
  static const Color primary = Color(0xff27548A);
  static const Color primaryLight = Color(0xff4A90E2);

  // Secondary colors for accents and highlights
  static const Color secondary = Color(0xff028391);
  static const Color secondaryLight = Color(0xff4DD0E1);

  // Success, warning, and error colors
  static const Color success = Color(0xff88C273);
  static const Color warning = Color(0xffDDA853);
  static const Color error = Color(0xffAE445A);

  // Neutral colors for backgrounds and surfaces
  static const Color surfaceLight = Color(0xffFEFAF6);
  static const Color cardBackground = Color(0xffF8FAFE);
  static const Color cardBorder = Color(0xffE8F4FD);

  // Glass morphism colors
  static const Color glassBackground = Color(0x1A4A90E2);
  static const Color glassBorder = Color(0x334A90E2);
}

ThemeData theme(BuildContext context) {
  AppSizes.init(context);
  return ThemeData(
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 0, // Remove default elevation for custom gradient
      shadowColor: AppColors.primaryDark.withOpacity(0.3),
      toolbarHeight: 100,
      titleTextStyle: GoogleFonts.cairo(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 22,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(
        color: Colors.white,
        size: 24,
      ),
      actionsIconTheme: IconThemeData(
        color: Colors.white,
        size: 24,
      ),
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    // Enhanced custom theme extensions
    extensions: <ThemeExtension<dynamic>>[
      CustomAppBarTheme(
        gradientColors: [
          AppColors.primaryDark,
          AppColors.primary,
          AppColors.primaryLight,
        ],
      ),
      AdminPanelTheme(
        cardElevation: 8,
        cardShadowColor: AppColors.primary.withOpacity(0.1),
        glassBackgroundColor: AppColors.glassBackground,
        glassBorderColor: AppColors.glassBorder,
      ),
    ],
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.fromSeed(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.cardBackground,
      seedColor: AppColors.primary,
      error: AppColors.error,
      background: AppColors.surfaceLight,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xff2C3E50),
      onBackground: Color(0xff2C3E50),
    ),
    canvasColor: AppColors.surfaceLight,
    cardColor: AppColors.cardBackground,
    scaffoldBackgroundColor: AppColors.surfaceLight,
    // Enhanced text theme with better hierarchy
    textTheme: TextTheme(
      displayLarge: GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        color: AppColors.primaryDark,
        fontSize: AppSizes.blockHeight * 2.8,
        letterSpacing: 0.3,
      ),
      displayMedium: GoogleFonts.cairo(
        fontWeight: FontWeight.w600,
        color: Color(0xff2C3E50),
        fontSize: AppSizes.blockHeight * 2.2,
        letterSpacing: 0.2,
      ),
      displaySmall: GoogleFonts.cairo(
        fontWeight: FontWeight.w500,
        color: Color(0xff525252),
        fontSize: AppSizes.blockHeight * 1.8,
      ),
      headlineLarge: GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        color: AppColors.primaryDark,
        fontSize: AppSizes.blockHeight * 3.2,
        letterSpacing: 0.4,
      ),
      headlineMedium: GoogleFonts.cairo(
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        fontSize: AppSizes.blockHeight * 2.6,
        letterSpacing: 0.3,
      ),
      bodyLarge: GoogleFonts.notoSansArabic(
        fontWeight: FontWeight.w600,
        fontSize: AppSizes.blockHeight * 2,
        letterSpacing: 0.1,
      ),
      bodyMedium: GoogleFonts.notoSansArabic(
        fontWeight: FontWeight.w500,
        fontSize: AppSizes.blockHeight * 1.6,
        letterSpacing: 0.1,
      ),
      bodySmall: GoogleFonts.alexandria(
        fontWeight: FontWeight.normal,
        fontSize: AppSizes.blockHeight * 1.3,
        color: Color(0xff6B7280),
      ),
      labelLarge: GoogleFonts.cairo(
        fontWeight: FontWeight.w600,
        fontSize: AppSizes.blockHeight * 1.4,
        color: AppColors.primary,
        letterSpacing: 0.2,
      ),
    ),
    // Enhanced card theme
    cardTheme: CardTheme(
      color: AppColors.cardBackground,
      elevation: 8,
      shadowColor: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.cardBorder,
          width: 1,
        ),
      ),
      margin: EdgeInsets.symmetric(
        horizontal: AppPadding.medium,
        vertical: AppPadding.small,
      ),
    ),
    // Enhanced elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shadowColor: AppColors.primary.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppPadding.large,
          vertical: AppPadding.medium,
        ),
        textStyle: GoogleFonts.cairo(
          fontWeight: FontWeight.w600,
          fontSize: AppSizes.blockHeight * 1.8,
          letterSpacing: 0.2,
        ),
      ),
    ),
  );
}

// Enhanced custom theme extension for app bar gradient
class CustomAppBarTheme extends ThemeExtension<CustomAppBarTheme> {
  final List<Color> gradientColors;

  const CustomAppBarTheme({
    required this.gradientColors,
  });

  @override
  CustomAppBarTheme copyWith({
    List<Color>? gradientColors,
  }) {
    return CustomAppBarTheme(
      gradientColors: gradientColors ?? this.gradientColors,
    );
  }

  @override
  CustomAppBarTheme lerp(CustomAppBarTheme? other, double t) {
    if (other is! CustomAppBarTheme) {
      return this;
    }
    return CustomAppBarTheme(
      gradientColors: gradientColors,
    );
  }
}

// New admin panel theme extension for modern effects
class AdminPanelTheme extends ThemeExtension<AdminPanelTheme> {
  final double cardElevation;
  final Color cardShadowColor;
  final Color glassBackgroundColor;
  final Color glassBorderColor;

  const AdminPanelTheme({
    required this.cardElevation,
    required this.cardShadowColor,
    required this.glassBackgroundColor,
    required this.glassBorderColor,
  });

  @override
  AdminPanelTheme copyWith({
    double? cardElevation,
    Color? cardShadowColor,
    Color? glassBackgroundColor,
    Color? glassBorderColor,
  }) {
    return AdminPanelTheme(
      cardElevation: cardElevation ?? this.cardElevation,
      cardShadowColor: cardShadowColor ?? this.cardShadowColor,
      glassBackgroundColor: glassBackgroundColor ?? this.glassBackgroundColor,
      glassBorderColor: glassBorderColor ?? this.glassBorderColor,
    );
  }

  @override
  AdminPanelTheme lerp(AdminPanelTheme? other, double t) {
    if (other is! AdminPanelTheme) {
      return this;
    }
    return AdminPanelTheme(
      cardElevation: cardElevation,
      cardShadowColor: cardShadowColor,
      glassBackgroundColor: glassBackgroundColor,
      glassBorderColor: glassBorderColor,
    );
  }
}
