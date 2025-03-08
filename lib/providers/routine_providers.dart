import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/routine.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:taskfy/utils/error_handler.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:taskfy/config/constants.dart';
import 'package:logging/logging.dart';

final _log = Logger('RoutineNotifier');

final routineNotifierProvider =
    StateNotifierProvider<RoutineNotifier, AsyncValue<Routine?>>(
        (ref) => RoutineNotifier());

final routineListStreamProvider =
    StreamProvider.family<List<Routine>, String?>((ref, userEmail) async* {
  final supabase = getIt<SupabaseClientWrapper>().client;

  Stream<List<Map<String, dynamic>>> stream;
  if (userEmail != null) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    if (user != null &&
        (user.role == AppConstants.roleAdmin ||
            user.role == AppConstants.roleManager)) {
      stream = supabase.from('routines').stream(primaryKey: ['id']);
    } else {
      stream = supabase
          .from('routines')
          .select()
          .filter('assignees', 'cs', '["$userEmail"]')
          .order('due_date', ascending: true)
          .then((data) => data.map((json) => json).toList())
          .asStream();

      _log.info('Querying routines for user: $userEmail');
    }
  } else {
    stream = supabase.from('routines').stream(primaryKey: ['id']);
  }

  await for (final data in stream) {
    final routines = data.map((json) => Routine.fromJson(json)).toList();
    routines.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    yield routines;
  }
});

final routineProvider =
    StreamProvider.family<Routine?, String>((ref, routineId) async* {
  final stream = getIt<SupabaseClientWrapper>()
      .client
      .from('routines')
      .stream(primaryKey: ['id']).eq('id', routineId);

  await for (final data in stream) {
    if (data.isNotEmpty) {
      yield Routine.fromJson(data.first);
    } else {
      yield null;
    }
  }
});

class RoutineNotifier extends StateNotifier<AsyncValue<Routine?>> {
  RoutineNotifier() : super(const AsyncValue.loading());

  final _supabase = getIt<SupabaseClientWrapper>().client;

  /// Creates a new routine.
  Future<void> createRoutine(Routine routine) async {
    state = const AsyncValue.loading();
    try {
      final routineData = routine.toJson()..remove('id');
      final response = await _supabase
          .from('routines')
          .insert(routineData)
          .select()
          .single();
      final createdRoutine = Routine.fromJson(response);
      state = AsyncValue.data(createdRoutine);
      _log.info('Routine created successfully: ${createdRoutine.title}');
    } catch (e, stack) {
      final errorMessage = getErrorMessage(e);
      _log.warning('Failed to create routine: $errorMessage');
      state = AsyncValue.error(errorMessage, stack);
      rethrow;
    }
  }

  /// Updates an existing routine.
  Future<void> updateRoutine(Routine routine) async {
    state = const AsyncValue.loading();
    try {
      final routineData = routine.toJson();
      final response = await _supabase
          .from('routines')
          .update(routineData)
          .eq('id', routine.id ?? '')
          .select()
          .single();
      final updatedRoutine = Routine.fromJson(response);
      state = AsyncValue.data(updatedRoutine);
      _log.info('Routine updated successfully: ${updatedRoutine.title}');
    } catch (e, stack) {
      final errorMessage = getErrorMessage(e);
      _log.warning('Failed to update routine: $errorMessage');
      state = AsyncValue.error(errorMessage, stack);
      rethrow;
    }
  }

  Future<void> deleteRoutine(String routineId) async {
    state = const AsyncValue.loading();
    try {
      _log.info('Attempting to delete routine with ID: $routineId');

      final routineExists = await _supabase
          .from('routines')
          .select('id')
          .eq('id', routineId)
          .maybeSingle();

      if (routineExists == null) {
        _log.warning('Routine with ID $routineId not found');
        state = AsyncValue.error('Routine not found', StackTrace.current);
        return;
      }

      await _supabase.from('routines').delete().eq('id', routineId);

      final checkDeleted = await _supabase
          .from('routines')
          .select('id')
          .eq('id', routineId)
          .maybeSingle();

      if (checkDeleted != null) {
        throw Exception('Failed to delete routine: Record still exists');
      }

      state = const AsyncValue.data(null);
      _log.info('Routine deleted successfully: $routineId');
    } catch (e, stack) {
      final errorMessage = getErrorMessage(e);
      _log.severe('Failed to delete routine: $errorMessage', e, stack);
      state = AsyncValue.error(errorMessage, stack);
      rethrow;
    }
  }
}
