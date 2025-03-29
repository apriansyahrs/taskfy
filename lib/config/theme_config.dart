import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeConfig {
  // App colors from app_layout.dart
  static const Color primary = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFD);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE4E4E7);
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color accentColor = Color(0xFF1967D2);
  
  // UI element colors from app_layout.dart
  static const Color selectedBgColor = Color(0xFFE8F0FE);
  static const Color hoverColor = Color(0xFFF1F3F4);
  static const Color dividerColor = Color(0xFFE1E3E6);
  static const Color shadowColor = Color(0x0A000000);
  
  // Status colors
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFFACC15);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);
  
  // Text colors based on app_layout.dart
  static const Color titleTextColor = Color(0xFF3C4043);
  static const Color labelTextColor = Color(0xFF5F6368);

  static ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: ColorScheme.light(
      primary: accentColor,
      secondary: accentColor,
      surface: card,
      error: errorColor,
      onPrimary: primary,
      onSecondary: primary,
      onSurface: textPrimary,
      onError: primary,
      surfaceTint: accentColor.withOpacity(0.05),
      outlineVariant: border,
      shadow: shadowColor,
    ),
    
    // Text Theme based on app_layout.dart
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.light().textTheme.copyWith(
        // Large heading like page titles
        headlineLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        // Medium heading like section titles
        headlineMedium: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        // Title large for prominent elements
        titleLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: titleTextColor,
        ),
        // Title medium for menu items, etc.
        titleMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: titleTextColor,
        ),
        // Body large for main content
        bodyLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: titleTextColor,
        ),
        // Body medium for secondary content
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: labelTextColor,
        ),
        // Small labels like in the user menu
        labelSmall: const TextStyle(
          fontSize: 12,
          color: labelTextColor,
        ),
      ),
    ),

    // Card Theme
    cardTheme: CardTheme(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: border, width: 1),
      ),
      margin: EdgeInsets.zero,
      shadowColor: shadowColor,
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accentColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: const TextStyle(color: labelTextColor),
      hintStyle: const TextStyle(color: labelTextColor),
      errorStyle: const TextStyle(color: errorColor),
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(accentColor),
        foregroundColor: WidgetStateProperty.all(primary),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        elevation: WidgetStateProperty.all(0),
        textStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: labelTextColor,
      size: 20,
    ),

    // App Bar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 1,
      space: 1,
    ),

    // Navigation Bar Theme
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: card,
      indicatorColor: selectedBgColor,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      iconTheme: WidgetStateProperty.all(
        const IconThemeData(size: 20),
      ),
    ),
    
    // List Tile Theme - for navigation items
    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent,
      selectedTileColor: selectedBgColor,
      iconColor: labelTextColor,
      selectedColor: accentColor,
      textColor: titleTextColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      minLeadingWidth: 20,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
    ),
    
    // Popup Menu Theme - for user menu
    popupMenuTheme: PopupMenuThemeData(
      color: card,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: titleTextColor, 
        fontSize: 14
      ),
    ),
    
    // Visual Density - compact like Google Play Console
    visualDensity: VisualDensity.compact,
  );
}

