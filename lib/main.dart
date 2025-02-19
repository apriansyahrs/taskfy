import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/router.dart';
import 'package:taskfy/config/theme_config.dart';
import 'package:taskfy/utils/error_handler.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';

/// The entry point of the application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  await getIt<SupabaseClientWrapper>().initialize();
  setupLogging();
  runApp(const ProviderScope(child: MyApp()));
}

/// Provider for the app's theme mode.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// The root widget of the application.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Task Manager',
      theme: ThemeConfig.lightTheme,
      darkTheme: ThemeConfig.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

