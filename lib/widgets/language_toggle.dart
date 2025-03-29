import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/providers/locale_provider.dart';
import 'package:taskfy/config/theme_config.dart';

class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final notifier = ref.read(localeProvider.notifier);

    return IconButton(
      icon: Text(
        locale.languageCode.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: ThemeConfig.accentColor,
          fontSize: 14,
        ),
      ),
      onPressed: () {
        notifier.toggleLocale();
      },
      tooltip: locale.languageCode == 'en' ? 'Switch to Indonesian' : 'Ganti ke Bahasa Inggris',
    );
  }
}