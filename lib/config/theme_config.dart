import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeConfig {
  // Light theme colors
  static const Color primaryLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF4F4F5);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE4E4E7);
  static const Color textPrimaryLight = Color(0xFF18181B);
  static const Color textSecondaryLight = Color(0xFF71717A);
  static const Color accentColorLight = Color(0xFF3B82F6);

  // Dark theme colors
  static const Color primaryDark = Color(0xFF18181B);
  static const Color backgroundDark = Color(0xFF0F0F0F);
  static const Color cardDark = Color(0xFF27272A);
  static const Color borderDark = Color(0xFF3F3F46);
  static const Color textPrimaryDark = Color(0xFFFAFAFA);
  static const Color textSecondaryDark = Color(0xFFA1A1AA);
  static const Color accentColorDark = Color(0xFF60A5FA);

  // Shared colors
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFFACC15);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundLight,
    primaryColor: primaryLight,
    colorScheme: const ColorScheme.light(
      primary: accentColorLight,
      secondary: accentColorLight,
    ),
    
    // Text Theme
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.light().textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimaryLight,
          letterSpacing: -0.5,
        ),
        headlineMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimaryLight,
          letterSpacing: -0.5,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: textPrimaryLight,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: textSecondaryLight,
        ),
      ),
    ),

    // Card Theme
    cardTheme: CardTheme(
      color: cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: borderLight,
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accentColorLight, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: const TextStyle(color: textSecondaryLight),
      hintStyle: const TextStyle(color: textSecondaryLight),
      errorStyle: const TextStyle(color: errorColor),
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(accentColorLight),
        foregroundColor: MaterialStateProperty.all(primaryLight),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        elevation: MaterialStateProperty.all(0),
        textStyle: MaterialStateProperty.all(
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: textSecondaryLight,
      size: 24,
    ),

    // App Bar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryLight,
      foregroundColor: textPrimaryLight,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimaryLight,
      ),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: borderLight,
      thickness: 1,
      space: 24,
    ),

    // Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return accentColorLight;
        }
        return borderLight;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return accentColorLight;
        }
        return textSecondaryLight;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return accentColorLight.withOpacity(0.5);
        }
        return textSecondaryLight.withOpacity(0.3);
      }),
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: accentColorLight,
      linearTrackColor: borderLight,
    ),

    // Tooltip Theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: textPrimaryLight.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(color: primaryLight),
    ),
  );

  // Dark Theme (keeping the existing dark theme configuration with some improvements)
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    primaryColor: primaryDark,
    colorScheme: const ColorScheme.dark(
      primary: accentColorDark,
      secondary: accentColorDark,
    ),
    
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimaryDark,
          letterSpacing: -0.5,
        ),
        headlineMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimaryDark,
          letterSpacing: -0.5,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: textPrimaryDark,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: textSecondaryDark,
        ),
      ),
    ),

    cardTheme: CardTheme(
      color: cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: borderDark,
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accentColorDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: const TextStyle(color: textSecondaryDark),
      hintStyle: const TextStyle(color: textSecondaryDark),
      errorStyle: const TextStyle(color: errorColor),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(accentColorDark),
        foregroundColor: MaterialStateProperty.all(textPrimaryDark),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        elevation: MaterialStateProperty.all(0),
        textStyle: MaterialStateProperty.all(
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),

    iconTheme: const IconThemeData(
      color: textSecondaryDark,
      size: 24,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: primaryDark,
      foregroundColor: textPrimaryDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimaryDark,
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: borderDark,
      thickness: 1,
      space: 24,
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return accentColorDark;
        }
        return borderDark;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return accentColorDark;
        }
        return textSecondaryDark;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return accentColorDark.withOpacity(0.5);
        }
        return textSecondaryDark.withOpacity(0.3);
      }),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: accentColorDark,
      linearTrackColor: borderDark,
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: textPrimaryDark.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(color: primaryDark),
    ),
  );
}

