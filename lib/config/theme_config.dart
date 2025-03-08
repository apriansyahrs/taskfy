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
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundLight,
    primaryColor: primaryLight,
    colorScheme: ColorScheme.light(
      primary: accentColorLight,
      secondary: accentColorLight,
      surface: cardLight,
      error: errorColor,
      onPrimary: primaryLight,
      onSecondary: primaryLight,
      onSurface: textPrimaryLight,
      onError: primaryLight,
      surfaceTint: accentColorLight.withOpacity(0.05),
      outlineVariant: borderLight,
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
        backgroundColor: WidgetStateProperty.all(accentColorLight),
        foregroundColor: WidgetStateProperty.all(primaryLight),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        elevation: WidgetStateProperty.all(0),
        textStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
    
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(accentColorLight),
        foregroundColor: WidgetStateProperty.all(primaryLight),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        elevation: WidgetStateProperty.all(0),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(accentColorLight),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        side: WidgetStateProperty.all(
          BorderSide(color: accentColorLight),
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(accentColorLight),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
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
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return accentColorLight;
        }
        return textSecondaryLight;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
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
    
    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentColorLight,
      foregroundColor: primaryLight,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: cardLight,
      disabledColor: borderLight,
      selectedColor: accentColorLight.withOpacity(0.2),
      secondarySelectedColor: accentColorLight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(fontSize: 14),
      secondaryLabelStyle: const TextStyle(color: primaryLight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: borderLight),
      ),
    ),
    
    // Dialog Theme
    dialogTheme: DialogTheme(
      backgroundColor: cardLight,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    // Bottom Sheet Theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: cardLight,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    
    // Navigation Bar Theme
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardLight,
      indicatorColor: accentColorLight.withOpacity(0.1),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      iconTheme: WidgetStateProperty.all(
        const IconThemeData(size: 24),
      ),
    ),
    
    // Navigation Rail Theme
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: cardLight,
      selectedIconTheme: const IconThemeData(color: accentColorLight),
      unselectedIconTheme: const IconThemeData(color: textSecondaryLight),
      selectedLabelTextStyle: const TextStyle(
        color: accentColorLight,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: const TextStyle(color: textSecondaryLight),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    primaryColor: primaryDark,
    colorScheme: ColorScheme.dark(
      primary: accentColorDark,
      secondary: accentColorDark,
      surface: cardDark,
      error: errorColor,
      onPrimary: textPrimaryDark,
      onSecondary: textPrimaryDark,
      onSurface: textPrimaryDark,
      onError: textPrimaryDark,
      surfaceTint: accentColorDark.withOpacity(0.05),
      outlineVariant: borderDark,
    ),
    
    // Text Theme
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

    // Card Theme
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

    // Input Decoration Theme
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

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(accentColorDark),
        foregroundColor: WidgetStateProperty.all(textPrimaryDark),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        elevation: WidgetStateProperty.all(0),
        textStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
    
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(accentColorDark),
        foregroundColor: WidgetStateProperty.all(textPrimaryDark),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        elevation: WidgetStateProperty.all(0),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(accentColorDark),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        side: WidgetStateProperty.all(
          BorderSide(color: accentColorDark),
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(accentColorDark),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: textSecondaryDark,
      size: 24,
    ),

    // App Bar Theme
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

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: borderDark,
      thickness: 1,
      space: 24,
    ),

    // Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return accentColorDark;
        }
        return borderDark;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return accentColorDark;
        }
        return textSecondaryDark;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return accentColorDark.withOpacity(0.5);
        }
        return textSecondaryDark.withOpacity(0.3);
      }),
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: accentColorDark,
      linearTrackColor: borderDark,
    ),
    
    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentColorDark,
      foregroundColor: textPrimaryDark,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: cardDark,
      disabledColor: borderDark,
      selectedColor: accentColorDark.withOpacity(0.2),
      secondarySelectedColor: accentColorDark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(fontSize: 14),
      secondaryLabelStyle: const TextStyle(color: textPrimaryDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: borderDark),
      ),
    ),
    
    // Dialog Theme
    dialogTheme: DialogTheme(
      backgroundColor: cardDark,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    // Bottom Sheet Theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: cardDark,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    
    // Navigation Bar Theme
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardDark,
      indicatorColor: accentColorDark.withOpacity(0.1),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      iconTheme: WidgetStateProperty.all(
        const IconThemeData(size: 24),
      ),
    ),
    
    // Navigation Rail Theme
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: cardDark,
      selectedIconTheme: const IconThemeData(color: accentColorDark),
      unselectedIconTheme: const IconThemeData(color: textSecondaryDark),
      selectedLabelTextStyle: const TextStyle(
        color: accentColorDark,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: const TextStyle(color: textSecondaryDark),
    ),
    
    // Tooltip Theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: textPrimaryDark.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(color: primaryDark),
    ),
    
    // Snackbar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: cardDark,
      contentTextStyle: const TextStyle(color: textPrimaryDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      actionTextColor: accentColorDark,
      behavior: SnackBarBehavior.floating,
    ),
    
    // Tab Bar Theme
    tabBarTheme: const TabBarTheme(
      labelColor: accentColorDark,
      unselectedLabelColor: textSecondaryDark,
      indicatorColor: accentColorDark,
      dividerColor: borderDark,
    ),
    
    // Slider Theme
    sliderTheme: SliderThemeData(
      activeTrackColor: accentColorDark,
      inactiveTrackColor: borderDark,
      thumbColor: accentColorDark,
      overlayColor: accentColorDark.withOpacity(0.2),
      valueIndicatorColor: accentColorDark,
      valueIndicatorTextStyle: const TextStyle(color: textPrimaryDark),
    ),
    
    // Date Picker Theme
    datePickerTheme: DatePickerThemeData(
      backgroundColor: cardDark,
      headerBackgroundColor: accentColorDark,
      headerForegroundColor: textPrimaryDark,
      dayBackgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return accentColorDark;
        }
        return cardDark;
      }),
      dayForegroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return textPrimaryDark;
        }
        return textPrimaryDark;
      }),
      todayBackgroundColor: WidgetStateProperty.all(accentColorDark.withOpacity(0.2)),
      todayForegroundColor: WidgetStateProperty.all(accentColorDark),
      yearBackgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return accentColorDark;
        }
        return cardDark;
      }),
      yearForegroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return textPrimaryDark;
        }
        return textPrimaryDark;
      }),
    ),
    
    // Time Picker Theme
    timePickerTheme: TimePickerThemeData(
      backgroundColor: cardDark,
      hourMinuteTextColor: textPrimaryDark,
      hourMinuteColor: cardDark,
      dayPeriodTextColor: textPrimaryDark,
      dayPeriodColor: cardDark,
      dialHandColor: accentColorDark,
      dialBackgroundColor: cardDark,
      dialTextColor: textPrimaryDark,
      entryModeIconColor: accentColorDark,
    )
  );
}

