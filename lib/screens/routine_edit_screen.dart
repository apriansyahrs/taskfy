import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:intl/intl.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:taskfy/providers/user_availability_provider.dart';
import 'package:taskfy/providers/permission_provider.dart';
import 'package:taskfy/config/style_guide.dart';
import 'package:taskfy/models/routine.dart';
import 'package:taskfy/providers/routine_providers.dart';

final usersProvider = StreamProvider((ref) {
  return getIt<SupabaseClientWrapper>().client
      .from('users')
      .stream(primaryKey: ['id'])
      .map((data) => data.map((json) => json['email'] as String).toList());
});

class RoutineEditScreen extends ConsumerStatefulWidget {
  final String routineId;

  const RoutineEditScreen({super.key, required this.routineId});

  @override
  ConsumerState<RoutineEditScreen> createState() => _RoutineEditScreenState();
}

class _RoutineEditScreenState extends ConsumerState<RoutineEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'medium';
  final Set<String> _assignedTo = {};
  DateTime _deadline = DateTime.now().add(const Duration(days: 1));
  String _status = 'not_started';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routineAsyncValue = ref.watch(routineProvider(widget.routineId));
    final usersAsyncValue = ref.watch(usersProvider);
    final canEditAllFields = _canEditAllFields();

    return AppLayout(
      title: 'Task Manager',
      pageTitle: 'Edit Routine',
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Save Changes'),
          onPressed: _submitForm,
        ),
      ],
      child: routineAsyncValue.when(
        data: (routine) {
          if (routine != null) {
            _titleController.text = routine.title;
            _descriptionController.text = routine.description;
            _priority = routine.priority;
            _assignedTo.addAll(routine.assignees);
            _deadline = routine.dueDate;
            _status = routine.status;
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(StyleGuide.paddingMedium),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: StyleGuide.inputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter routine title',
                      ),
                      readOnly: !canEditAllFields,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a routine title';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: StyleGuide.spacingMedium),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: StyleGuide.inputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                      readOnly: !canEditAllFields,
                    ),
                    SizedBox(height: StyleGuide.spacingMedium),
                    DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: StyleGuide.inputDecoration(
                        labelText: 'Priority',
                      ),
                      onChanged: canEditAllFields ? (newValue) {
                        setState(() {
                          _priority = newValue!;
                        });
                      } : null,
                      items: ['low', 'medium', 'high'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: StyleGuide.inputDecoration(
                        labelText: 'Status',
                      ),
                      items: ['not_started', 'in_progress', 'completed'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _status = newValue!;
                        });
                      },
                    ),
                    if (canEditAllFields) ...[
                      const SizedBox(height: 16),
                      Text('Assign To:', style: Theme.of(context).textTheme.titleMedium),
                      usersAsyncValue.when(
                        data: (users) => _buildAssigneeChips(users),
                        loading: () => const CircularProgressIndicator(),
                        error: (err, stack) => Text('Error: $err'),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _deadline,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              _deadline = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Deadline',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('MMM d, y').format(_deadline)),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final canEditAllFields = _canEditAllFields();
      final currentRoutine = ref.read(routineProvider(widget.routineId)).value;

      if (currentRoutine == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Routine not found')),
        );
        return;
      }

      final updatedRoutine = canEditAllFields
          ? Routine(
              id: widget.routineId,
              title: _titleController.text,
              description: _descriptionController.text,
              status: _status,
              priority: _priority,
              assignees: _assignedTo.toList(),
              dueDate: _deadline,
              createdBy: currentRoutine.createdBy,
              updatedBy: currentRoutine.createdBy,
              createdAt: currentRoutine.createdAt,
              updatedAt: DateTime.now(),
            )
          : currentRoutine.copyWith(status: _status);

      try {
        await ref.read(routineNotifierProvider.notifier).updateRoutine(updatedRoutine);
        if (mounted) {
          context.go('/routines');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Routine updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating routine: $e')),
          );
        }
      }
    }
  }

  bool _canEditAllFields() {
    final permissions = ref.read(permissionProvider);
    return permissions.contains('update_routine');
  }

  Widget _buildAssigneeChips(List<String> users) {
    return Wrap(
      spacing: 8,
      children: users.map((email) {
        final isAvailable = ref.watch(userAvailabilityProvider(UserAvailabilityParams(email, _deadline)));
        return FilterChip(
          label: Text(email.trim()),
          selected: _assignedTo.contains(email),
          onSelected: isAvailable ? (selected) {
            setState(() {
              if (selected && _assignedTo.length < 3) {
                _assignedTo.add(email);
              } else {
                _assignedTo.remove(email);
              }
            });
          } : null,
          backgroundColor: isAvailable ? null : Colors.grey,
        );
      }).toList(),
    );
  }
}

