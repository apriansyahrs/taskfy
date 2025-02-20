import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/providers/project_providers.dart';

final userAvailabilityProvider = Provider.family<bool, UserAvailabilityParams>((ref, params) {
  final projects = ref.watch(projectListStreamProvider(null)).value ?? [];

  for (final project in projects) {
    if (project.teamMembers.contains(params.userEmail) &&
        _isDateInRange(params.date, project.startDate, project.endDate) &&
        project.status.toLowerCase() != 'completed') {
      return false;
    }
  }

  return true;
});

bool _isDateInRange(DateTime date, DateTime start, DateTime end) {
  return date.isAtSameMomentAs(start) ||
         date.isAtSameMomentAs(end) ||
         (date.isAfter(start) && date.isBefore(end));
}

class UserAvailabilityParams {
  final String userEmail;
  final DateTime date;

  UserAvailabilityParams(this.userEmail, this.date);
}

