import 'package:flutter/material.dart';
import 'package:taskfy/config/theme_config.dart';

/// Style guide for the Taskfy application.
/// This class follows the Google Play Console style design patterns
/// seen in app_layout.dart to maintain consistency across the application.
class StyleGuide {
  /// Standard padding values based on app_layout.dart
  static const double paddingTiny = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  /// Standard border radius values based on app_layout.dart
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXLarge = 16.0;

  /// Standard spacing between widgets based on app_layout.dart
  static const double spacingTiny = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;

  /// Standard heights for components based on app_layout.dart
  static const double navItemHeight = 48.0;
  static const double appBarHeight = 64.0;

  /// Standard shadows based on app_layout.dart
  static List<BoxShadow> get lightShadow => [
        const BoxShadow(
          color: ThemeConfig.shadowColor,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ];
  
  static List<BoxShadow> get subtleShadow => [
        const BoxShadow(
          color: ThemeConfig.shadowColor,
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ];

  /// Standard input decoration styled like Google Play Console
  static InputDecoration inputDecoration({
    required String labelText,
    IconData? prefixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null 
          ? Icon(prefixIcon, size: 20, color: ThemeConfig.labelTextColor) 
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        borderSide: const BorderSide(color: ThemeConfig.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        borderSide: const BorderSide(color: ThemeConfig.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        borderSide: const BorderSide(color: ThemeConfig.accentColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: paddingMedium,
        vertical: paddingMedium,
      ),
      labelStyle: const TextStyle(color: ThemeConfig.labelTextColor),
      hintStyle: const TextStyle(color: ThemeConfig.labelTextColor),
    );
  }

  /// Standard button style like in app_layout.dart
  static ButtonStyle buttonStyle(BuildContext context) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.all(ThemeConfig.accentColor),
      foregroundColor: WidgetStateProperty.all(ThemeConfig.primary),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(
          horizontal: paddingMedium, 
          vertical: paddingSmall
        ),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Standard card style based on app_layout.dart
  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: ThemeConfig.card,
      borderRadius: BorderRadius.circular(borderRadiusLarge),
      boxShadow: lightShadow,
    );
  }

  /// Standard container decoration based on app_layout.dart
  static BoxDecoration containerDecoration() {
    return BoxDecoration(
      color: ThemeConfig.card,
      borderRadius: BorderRadius.circular(borderRadiusLarge),
      boxShadow: lightShadow,
    );
  }

  /// Standard navigation item style based on app_layout.dart
  static BoxDecoration navItemDecoration({required bool isSelected}) {
    return BoxDecoration(
      color: isSelected ? ThemeConfig.selectedBgColor : Colors.transparent,
      borderRadius: BorderRadius.circular(0),
    );
  }

  /// Standard responsive breakpoints based on app_layout.dart
  static const double breakpointMobile = 480;
  static const double breakpointTablet = 768;
  static const double breakpointDesktop = 900;

  /// Standard card elevation for consistency across the app
  static const double cardElevation = 0;

  /// Standard error style based on app_layout colors
  static TextStyle errorTextStyle(BuildContext context) {
    return const TextStyle(
      color: ThemeConfig.errorColor,
      fontSize: 12,
    );
  }
  
  /// Standard text styles based on app_layout.dart
  static TextStyle get titleStyle => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: ThemeConfig.textPrimary,
  );
  
  static TextStyle get subtitleStyle => const TextStyle(
    fontSize: 16, 
    fontWeight: FontWeight.w500,
    color: ThemeConfig.titleTextColor,
  );
  
  static TextStyle get navLabelStyle => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ThemeConfig.titleTextColor,
  );
  
  static TextStyle get navLabelSelectedStyle => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ThemeConfig.accentColor,
  );
  
  static TextStyle get smallLabelStyle => const TextStyle(
    fontSize: 12,
    color: ThemeConfig.labelTextColor,
  );
  
  /// Standard avatar style for user menu based on app_layout.dart
  static CircleAvatar userAvatar(String initial) {
    return CircleAvatar(
      backgroundColor: ThemeConfig.accentColor,
      radius: 16,
      child: Text(
        initial.isNotEmpty ? initial[0].toUpperCase() : '?',
        style: const TextStyle(
          color: ThemeConfig.primary,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
}