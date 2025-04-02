import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/project.dart';
import 'package:taskfy/providers/project_providers.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:taskfy/config/constants.dart';
import 'package:taskfy/config/style_guide.dart';

final usersProvider = StreamProvider((ref) {
  return getIt<SupabaseClientWrapper>().client
      .from('users')
      .stream(primaryKey: ['id'])
      .map((data) => data
          .where((json) => json['role'] == AppConstants.roleEmployee)
          .map((json) => json['email'] as String)
          .toList());
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
    final theme = Theme.of(context);

    return AppLayout(
      title: AppLocalizations.of(context)!.appTitle,
      pageTitle: AppLocalizations.of(context)!.createProjectButton,
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: Text(AppLocalizations.of(context)!.saveButton),
          onPressed: _submitForm,
          style: StyleGuide.buttonStyle(context),
        ),
      ],
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Info Card
                _buildSectionCard(
                  context,
                  title: 'Project Information',
                  icon: Icons.business,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: StyleGuide.inputDecoration(
                        labelText: AppLocalizations.of(context)!.projectNameLabel,
                        prefixIcon: Icons.title,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.projectNameLabel;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: StyleGuide.spacingMedium),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: StyleGuide.inputDecoration(
                        labelText: AppLocalizations.of(context)!.descriptionLabel,
                        prefixIcon: Icons.description,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
                
                const SizedBox(height: 38.0), // Golden ratio: ~1.618 * spacingLarge
                
                // Project Details Card
                _buildSectionCard(
                  context,
                  title: 'Project Details',
                  icon: Icons.settings,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: StyleGuide.inputDecoration(
                        labelText: AppLocalizations.of(context)!.highPriorityLabel,
                        prefixIcon: Icons.flag,
                      ),
                      items: [
                        _buildDropdownMenuItem('low', theme.colorScheme.primary.withOpacity(0.5)),
                        _buildDropdownMenuItem('medium', theme.colorScheme.primary),
                        _buildDropdownMenuItem('high', theme.colorScheme.error),
                      ],
                      onChanged: (newValue) {
                        setState(() {
                          _priority = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: StyleGuide.spacingMedium),
                    
                    // Date Range Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildDatePicker(
                            labelText: 'Start Date',
                            selectedDate: _startDate,
                            onDateSelected: (date) {
                              setState(() {
                                _startDate = date;
                                // Ensure end date is not before start date
                                if (_endDate.isBefore(_startDate)) {
                                  _endDate = _startDate;
                                }
                              });
                            },
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          ),
                        ),
                        const SizedBox(width: StyleGuide.spacingMedium),
                        Expanded(
                          child: _buildDatePicker(
                            labelText: 'End Date',
                            selectedDate: _endDate,
                            onDateSelected: (date) {
                              setState(() {
                                _endDate = date;
                              });
                            },
                            firstDate: _startDate,
                            lastDate: _startDate.add(const Duration(days: 365)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 38.0), // Golden ratio: ~1.618 * spacingLarge
                
                // Team Members Card
                _buildSectionCard(
                  context,
                  title: 'Team Members',
                  icon: Icons.people,
                  children: [
                    Text(
                      'Select team members for this project:',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: StyleGuide.spacingSmall),
                    usersAsyncValue.when(
                      data: (users) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.dividerColor),
                            borderRadius: BorderRadius.circular(StyleGuide.borderRadiusMedium),
                          ),
                          padding: const EdgeInsets.all(StyleGuide.paddingMedium),
                          child: Wrap(
                            spacing: StyleGuide.spacingSmall,
                            runSpacing: StyleGuide.spacingSmall,
                            children: users.map((user) {
                              return FilterChip(
                                label: Text(user),
                                selected: _teamMembers.contains(user),
                                avatar: Icon(
                                  Icons.person,
                                  size: 18,
                                  color: _teamMembers.contains(user) 
                                      ? theme.colorScheme.onPrimary 
                                      : theme.colorScheme.primary,
                                ),
                                selectedColor: theme.colorScheme.primary,
                                checkmarkColor: theme.colorScheme.onPrimary,
                                labelStyle: TextStyle(
                                  color: _teamMembers.contains(user) 
                                      ? theme.colorScheme.onPrimary 
                                      : theme.colorScheme.onSurface,
                                ),
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
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Text('Error: $err', style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  ],
                ),
                
                const SizedBox(height: 38.0), // Golden ratio: ~1.618 * spacingLarge
                
                // Submit Button
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: Text(
                      AppLocalizations.of(context)!.saveButton,
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: StyleGuide.paddingLarge,
                        vertical: StyleGuide.paddingMedium,
                      ),
                    ),
                    onPressed: _submitForm,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper method to build section cards
  Widget _buildSectionCard(BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: StyleGuide.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StyleGuide.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(StyleGuide.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: StyleGuide.spacingSmall),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: StyleGuide.spacingLarge),
            ...children,
          ],
        ),
      ),
    );
  }
  
  // Helper method to build date pickers
  Widget _buildDatePicker({
    required String labelText,
    required DateTime selectedDate,
    required Function(DateTime) onDateSelected,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
      child: InputDecorator(
        decoration: StyleGuide.inputDecoration(
          labelText: labelText,
          prefixIcon: Icons.calendar_today,
        ),
        child: Text(DateFormat('MMM d, y').format(selectedDate)),
      ),
    );
  }
  
  // Helper method to build dropdown menu items with colored indicators
  DropdownMenuItem<String> _buildDropdownMenuItem(String value, Color color) {
    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(value.toUpperCase()),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = getIt<SupabaseClientWrapper>().client.auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not authenticated')),
        );
        return;
      }

      final now = DateTime.now();
      final project = Project(
        id: '',
        name: _nameController.text,
        description: _descriptionController.text,
        status: 'not_started',
        priority: _priority,
        teamMembers: _teamMembers.toList(),
        startDate: _startDate,
        endDate: _endDate,
        createdBy: currentUser.id,
        updatedBy: currentUser.id,
        createdAt: now,
        updatedAt: now,
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

