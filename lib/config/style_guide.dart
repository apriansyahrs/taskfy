import 'package:flutter/material.dart';

/// Style guide for the Taskfy application.
/// This class contains standardized styles and patterns to maintain consistency
/// across the application.
class StyleGuide {
  /// Standard padding values
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  /// Standard border radius values
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;

  /// Standard spacing between widgets
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;

  /// Standard card elevation
  static const double cardElevation = 2.0;

  /// Standard input decoration
  static InputDecoration inputDecoration({
    required String labelText,
    IconData? prefixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusLarge),
      ),
      contentPadding: const EdgeInsets.all(paddingMedium),
    );
  }

  /// Standard button style
  static ButtonStyle buttonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(
        horizontal: paddingMedium,
        vertical: paddingSmall,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
      ),
    );
  }

  /// Standard card style
  static BoxDecoration cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(borderRadiusLarge),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Standard responsive breakpoints
  static const double breakpointMobile = 480;
  static const double breakpointTablet = 768;
  static const double breakpointDesktop = 1024;

  /// Standard error style
  static TextStyle errorTextStyle(BuildContext context) {
    return TextStyle(
      color: Theme.of(context).colorScheme.error,
      fontSize: 12,
    );
  }
}