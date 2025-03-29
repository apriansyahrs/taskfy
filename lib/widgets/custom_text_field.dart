import 'package:flutter/material.dart';
import 'package:taskfy/config/style_guide.dart';
import 'package:taskfy/config/theme_config.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.obscureText = false,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: StyleGuide.inputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon,
      ),
      style: TextStyle(
        fontFamily: 'Inter',
        color: ThemeConfig.textPrimary,
      ),
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
    );
  }
}

