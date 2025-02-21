import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/models/task.dart';
import 'package:taskfy/providers/task_providers.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:intl/intl.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:taskfy/providers/user_availability_provider.dart';
import 'package:taskfy/providers/permission_provider.dart';
import 'package:taskfy/config/style_guide.dart';

final usersProvider = StreamProvider((ref) {
  return getIt<SupabaseClientWrapper>().client
      .from('users')
      .stream(primaryKey: ['id'])
      .map((data) => data.map((json) => json['email'] as String).toList());
});

class TaskEditScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskEditScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends ConsumerState<TaskEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'medium';
  final Set<String> _assignedTo = {};
  DateTime _deadline = DateTime.now().add(const Duration(days: 1));
  String _status = 'not_started';

  bool _canEditAllFields() {
    final permissions = ref.read(permissionProvider);
    return permissions.contains('edit_task');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Widget _buildAssigneeChips(List<String> users) {
    return Wrap(
      spacing: 8,
      children: users.map((user) {
        final isAvailable = ref.watch(userAvailabilityProvider(UserAvailabilityParams(user, _deadline)));
        final isAssigned = _assignedTo.contains(user);
        return FilterChip(
          label: Text(user),
          selected: isAssigned,
          onSelected: (isAvailable || isAssigned) ? (selected) {
            setState(() {
              if (selected && _assignedTo.length < 3) {
                _assignedTo.add(user);
              } else {
                _assignedTo.remove(user);
              }
            });
          } : null,
          backgroundColor: (isAvailable || isAssigned) ? null : Colors.grey,
        );
      }).toList(),
    );
  }


  @override
  Widget build(BuildContext context) {
    final taskAsyncValue = ref.watch(taskProvider(widget.taskId));
    final usersAsyncValue = ref.watch(usersProvider);
    final canEditAllFields = _canEditAllFields();

    return AppLayout(
      title: 'Task Manager',
      pageTitle: 'Edit Task',
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Save Changes'),
          onPressed: _submitForm,
        ),
      ],
      child: taskAsyncValue.when(
        data: (task) {
          if (task != null) {
            _nameController.text = task.name;
            _descriptionController.text = task.description;
            _priority = task.priority;
            _assignedTo.addAll(task.assignedTo);
            _deadline = task.deadline;
            _status = task.status;
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
                      controller: _nameController,
                      decoration: StyleGuide.inputDecoration(
                        labelText: 'Task Name',
                      ),
                      readOnly: !canEditAllFields,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a task name';
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
      final currentTask = ref.read(taskProvider(widget.taskId)).value;

      if (currentTask == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Task not found')),
        );
        return;
      }

      final updatedTask = canEditAllFields
          ? Task(
              id: widget.taskId,
              name: _nameController.text,
              description: _descriptionController.text,
              status: _status,
              priority: _priority,
              assignedTo: _assignedTo.toList(),
              deadline: _deadline,
            )
          : currentTask.copyWith(status: _status);

      try {
        await ref.read(taskNotifierProvider.notifier).updateTask(updatedTask);
        if (mounted) {
          context.go('/tasks');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating task: $e')),
          );
        }
      }
    }
  }
}

