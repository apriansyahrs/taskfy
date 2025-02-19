import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/project.dart';
import 'package:taskfy/providers/project_providers.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';

final usersProvider = StreamProvider((ref) {
  return getIt<SupabaseClientWrapper>().client
      .from('users')
      .stream(primaryKey: ['id'])
      .map((data) => data.map((json) => json['email'] as String).toList());
});

class ProjectCreateScreen extends ConsumerStatefulWidget {
  const ProjectCreateScreen({super.key});

  @override
  ConsumerState<ProjectCreateScreen> createState() => _ProjectCreateScreenState();
}

class _ProjectCreateScreenState extends ConsumerState<ProjectCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'medium';
  final Set<String> _teamMembers = {};
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

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
      pageTitle: 'Create Project',
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Save Project'),
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
                    labelText: 'Project Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a project name';
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
                Text('Team Members:', style: Theme.of(context).textTheme.titleMedium),
                usersAsyncValue.when(
                  data: (users) {
                    return Wrap(
                      spacing: 8,
                      children: users.map((user) {
                        return FilterChip(
                          label: Text(user),
                          selected: _teamMembers.contains(user),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _teamMembers.add(user);
                              } else {
                                _teamMembers.remove(user);
                              }
                            });
                          },
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
                      initialDate: _startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _startDate = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('MMM d, y').format(_startDate)),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: _startDate,
                      lastDate: _startDate.add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _endDate = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('MMM d, y').format(_endDate)),
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
      final project = Project(
        id: '',
        name: _nameController.text,
        description: _descriptionController.text,
        status: 'not_started',
        priority: _priority,
        teamMembers: _teamMembers.toList(),
        startDate: _startDate,
        endDate: _endDate,
        completion: 0,
      );

      try {
        await ref.read(projectNotifierProvider.notifier).createProject(project);
        if (mounted) {
          context.go('/projects');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project created successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating project: $e')),
          );
        }
      }
    }
  }
}

