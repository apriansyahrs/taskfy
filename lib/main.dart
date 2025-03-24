import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:taskfy/router.dart';
import 'package:taskfy/config/theme_config.dart';
import 'package:taskfy/utils/error_handler.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:taskfy/providers/locale_provider.dart';
import 'package:taskfy/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskfy/state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  await getIt<SupabaseClientWrapper>().initialize();
  setupLogging();
  
  // Attempt to restore last path
  String? initialPath;
  try {
    final prefs = await SharedPreferences.getInstance();
    initialPath = prefs.getString('last_path');
  } catch (e) {
    debugPrint('Error loading stored path: $e');
  }
  
  runApp(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(getIt<AuthService>()),
        // Initialize last path provider with stored value
        if (initialPath != null)
          lastPathProvider.overrideWith((ref) => initialPath),
      ],
      child: const MyApp(),
    ),
  );
}

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
        title: 'Task Manager',
        theme: ThemeConfig.lightTheme,
        darkTheme: ThemeConfig.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('id'),
        ],
      );
  }
}

