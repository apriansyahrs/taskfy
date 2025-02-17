import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/models/project.dart';
import 'package:taskfy/providers/project_providers.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:intl/intl.dart';

class ProjectEditScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectEditScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectEditScreen> createState() => _ProjectEditScreenState();
}

class _ProjectEditScreenState extends ConsumerState<ProjectEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String _priority = 'medium';
  List<String> _teamMembers = [];
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  String _status = 'not_started';
  double _completion = 0.0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectAsyncValue = ref.watch(projectProvider(widget.projectId));

    return AppLayout(
      title: 'Task Manager',
      pageTitle: 'Edit Project',
      actions: [
        ElevatedButton.icon(
          icon: Icon(Icons.save),
          label: Text('Save Changes'),
          onPressed: _submitForm,
        ),
      ],
      child: projectAsyncValue.when(
        data: (project) {
          if (project != null) {
            _nameController.text = project.name;
            _descriptionController.text = project.description;
            _priority = project.priority;
            _teamMembers = project.teamMembers;
            _startDate = project.startDate;
            _endDate = project.endDate;
            _status = project.status;
            _completion = project.completion;
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Project Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a project name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: InputDecoration(labelText: 'Priority'),
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
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: InputDecoration(labelText: 'Status'),
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
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _showTeamMemberSelection,
                      child: Text('Team Members (${_teamMembers.length})'),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text('Start Date'),
                      subtitle: Text(DateFormat('MMM d, y').format(_startDate)),
                      trailing: Icon(Icons.calendar_today),
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
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text('End Date'),
                      subtitle: Text(DateFormat('MMM d, y').format(_endDate)),
                      trailing: Icon(Icons.calendar_today),
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
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: _completion.toString(),
                      decoration: InputDecoration(labelText: 'Completion (%)'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _completion = double.tryParse(value) ?? 0.0;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showTeamMemberSelection() async {
    // Implement team member selection dialog
    // This is a placeholder for the actual implementation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Team Members'),
        content: Text('Team member selection to be implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final updatedProject = Project(
        id: widget.projectId,
        name: _nameController.text,
        description: _descriptionController.text,
        status: _status,
        priority: _priority,
        teamMembers: _teamMembers,
        startDate: _startDate,
        endDate: _endDate,
        completion: _completion,
      );

      await ref.read(projectNotifierProvider.notifier).updateProject(updatedProject);
      if (mounted) {
        context.go('/projects');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project updated successfully')),
        );
      }
    }
  }
}

