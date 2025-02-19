import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/task.dart';
import 'package:taskfy/providers/task_providers.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:taskfy/providers/user_availability_provider.dart';

final usersProvider = StreamProvider((ref) {
  return getIt<SupabaseClientWrapper>().client
      .from('users')
      .stream(primaryKey: ['id'])
      .map((data) => data.map((json) => json['email'] as String).toList());
});

class TaskCreateScreen extends ConsumerStatefulWidget {
  const TaskCreateScreen({super.key});

  @override
  ConsumerState<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends ConsumerState<TaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'medium';
  final Set<String> _assignedTo = {};
  DateTime _deadline = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsyncValue = ref.watch(usersProvider);

    return AppLayout(
      title: 'Task Manager',
      pageTitle: 'Create Task',
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Save Task'),
          onPressed: _submitForm,
        ),
      ],
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Task Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a task name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: ['low', 'medium', 'high'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _priority = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text('Assign To:', style: Theme.of(context).textTheme.titleMedium),
                usersAsyncValue.when(
                  data: (users) {
                    return Wrap(
                      spacing: 8,
                      children: users.map((user) {
                        final isAvailable = ref.watch(userAvailabilityProvider(UserAvailabilityParams(user, _deadline)));
                        return FilterChip(
                          label: Text(user),
                          selected: _assignedTo.contains(user),
                          onSelected: isAvailable ? (selected) {
                            setState(() {
                              if (selected && _assignedTo.length < 3) {
                                _assignedTo.add(user);
                              } else {
                                _assignedTo.remove(user);
                              }
                            });
                          } : null,
                          backgroundColor: isAvailable ? null : Colors.grey,
                        );
                      }).toList(),
                    );
                  },
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
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_assignedTo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please assign the task to at least one person')),
        );
        return;
      }

      final task = Task(
        name: _nameController.text,
        description: _descriptionController.text,
        status: 'not_started',
        priority: _priority,
        assignedTo: _assignedTo.toList(),
        deadline: _deadline,
      );

      try {
        await ref.read(taskNotifierProvider.notifier).createTask(task);

        if (mounted) {
          context.go('/tasks');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task created successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating task: $e')),
          );
        }
      }
    }
  }
}

