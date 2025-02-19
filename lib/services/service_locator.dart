import 'package:get_it/get_it.dart';
import 'package:taskfy/services/auth_service.dart';
import 'package:taskfy/services/supabase_client.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Register services
  getIt.registerLazySingleton<SupabaseClientWrapper>(() => SupabaseClientWrapper());
  getIt.registerLazySingleton<AuthService>(() => AuthService(getIt<SupabaseClientWrapper>()));

  // Register repositories (to be implemented)
  // getIt.registerLazySingleton<TaskRepository>(() => TaskRepository(getIt<SupabaseClientWrapper>()));
  // getIt.registerLazySingleton<ProjectRepository>(() => ProjectRepository(getIt<SupabaseClientWrapper>()));

  // Register other dependencies as needed
}

