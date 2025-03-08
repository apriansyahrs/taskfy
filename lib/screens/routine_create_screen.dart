import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskfy/models/user.dart' as taskfy;
import 'package:taskfy/widgets/app_layout.dart';
import 'package:intl/intl.dart';
import 'package:taskfy/config/style_guide.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:taskfy/providers/user_availability_provider.dart';
import 'package:taskfy/models/routine.dart';
import 'package:taskfy/providers/routine_providers.dart';
import 'package:file_picker/file_picker.dart';

final usersProvider = StreamProvider((ref) {
  return getIt<SupabaseClientWrapper>().client
      .from('users')
      .stream(primaryKey: ['id'])
      .map((data) => data.map((json) => taskfy.User.fromJson(json)).toList());
});

class RoutineCreateScreen extends ConsumerStatefulWidget {
  const RoutineCreateScreen({super.key});

  @override
  ConsumerState<RoutineCreateScreen> createState() => _RoutineCreateScreenState();
}

class _RoutineCreateScreenState extends ConsumerState<RoutineCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'medium';
  final Set<String> _assignedTo = {};
  DateTime _deadline = DateTime.now().add(const Duration(days: 1));
  List<PlatformFile> _attachments = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final currentContext = context; // Store context before async gap
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && currentContext.mounted) {
        setState(() {
          _attachments = result.files;
        });
      }
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Error picking files: $e')),
        );
      }
    }
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
  
  // Helper method to build date picker
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

  @override
  Widget build(BuildContext context) {
    final usersAsyncValue = ref.watch(usersProvider);
    final theme = Theme.of(context);

    return AppLayout(
      title: 'Task Manager',
      pageTitle: 'Create Routine',
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Save Routine'),
          onPressed: _submitForm,
          style: StyleGuide.buttonStyle(context),
        ),
      ],
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: StyleGuide.paddingXLarge,
            vertical: StyleGuide.paddingLarge,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Routine Info Card
                _buildSectionCard(
                  context,
                  title: 'Routine Information',
                  icon: Icons.assignment,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: StyleGuide.inputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter routine title',
                        prefixIcon: Icons.title,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a routine title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: StyleGuide.spacingMedium),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: StyleGuide.inputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icons.description,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
                
                const SizedBox(height: 38.0), // Golden ratio: ~1.618 * spacingLarge
                
                // Routine Details Card
                _buildSectionCard(
                  context,
                  title: 'Routine Details',
                  icon: Icons.settings,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: StyleGuide.inputDecoration(
                        labelText: 'Priority',
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
                    _buildDatePicker(
                      labelText: 'Deadline',
                      selectedDate: _deadline,
                      onDateSelected: (date) {
                        setState(() {
                          _deadline = date;
                        });
                      },
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    ),
                  ],
                ),
                
                const SizedBox(height: 38.0), // Golden ratio: ~1.618 * spacingLarge
                
                // Team Members Card
                _buildSectionCard(
                  context,
                  title: 'Assign To',
                  icon: Icons.people,
                  children: [
                    Text(
                      'Select team members for this routine:',
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
                              final userEmail = user.email.trim();
                              final isAvailable = ref.watch(userAvailabilityProvider(UserAvailabilityParams(userEmail, _deadline)));
                              return FilterChip(
                                label: Text(userEmail),
                                selected: _assignedTo.contains(userEmail),
                                avatar: Icon(
                                  Icons.person,
                                  size: 18,
                                  color: _assignedTo.contains(userEmail) 
                                      ? theme.colorScheme.onPrimary 
                                      : theme.colorScheme.primary,
                                ),
                                selectedColor: theme.colorScheme.primary,
                                checkmarkColor: theme.colorScheme.onPrimary,
                                labelStyle: TextStyle(
                                  color: _assignedTo.contains(userEmail) 
                                      ? theme.colorScheme.onPrimary 
                                      : theme.colorScheme.onSurface,
                                ),
                                backgroundColor: !isAvailable ? Colors.grey.withOpacity(0.3) : null,
                                onSelected: isAvailable && userEmail.isNotEmpty ? (selected) {
                                  setState(() {
                                    if (selected && _assignedTo.length < 3) {
                                      _assignedTo.add(userEmail);
                                    } else {
                                      _assignedTo.remove(userEmail);
                                    }
                                  });
                                } : null,
                                tooltip: !isAvailable ? 'User not available on this date' : null,
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
                
                // Attachments Card
                _buildSectionCard(
                  context,
                  title: 'Attachments',
                  icon: Icons.attach_file,
                  children: [
                    Text(
                      'Add files to this routine:',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: StyleGuide.spacingSmall),
                    ElevatedButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.add),
                      label: const Text('Select Files'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                      ),
                    ),
                    if (_attachments.isNotEmpty) ...[                  
                      const SizedBox(height: StyleGuide.spacingMedium),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(StyleGuide.borderRadiusMedium),
                        ),
                        padding: const EdgeInsets.all(StyleGuide.paddingSmall),
                        child: Wrap(
                          spacing: StyleGuide.spacingSmall,
                          runSpacing: StyleGuide.spacingSmall,
                          children: _attachments.map((file) => Chip(
                            avatar: const Icon(Icons.insert_drive_file, size: 18),
                            label: Text(file.name),
                            onDeleted: () {
                              setState(() {
                                _attachments.remove(file);
                              });
                            },
                          )).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 38.0), // Golden ratio: ~1.618 * spacingLarge
                
                // Submit Button
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text(
                      'Save Routine',
                      style: TextStyle(fontSize: 16),
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_assignedTo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please assign the routine to at least one person')),
        );
        return;
      }

      final currentUser = getIt<SupabaseClientWrapper>().client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final supabase = getIt<SupabaseClientWrapper>().client;
      List<String> uploadedFiles = [];

      try {
        // Upload attachments
        for (final file in _attachments) {
          if (file.bytes != null) {
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            final filePath = 'attachments/$fileName';
            
            await supabase.storage.from('attachments').uploadBinary(
              filePath,
              file.bytes!,
              fileOptions: FileOptions(
                contentType: file.extension != null ? 'application/${file.extension}' : 'application/octet-stream',
                upsert: true
              ),
            );

            final fileUrl = supabase.storage.from('attachments').getPublicUrl(filePath);
            uploadedFiles.add(fileUrl);
          }
        }

        final now = DateTime.now();
        final routine = Routine(
          id: '',
          title: _titleController.text,
          description: _descriptionController.text,
          status: 'not_started',
          priority: _priority,
          assignees: _assignedTo.toList(),
          dueDate: _deadline,
          attachments: uploadedFiles,
          createdBy: currentUser.id,
          updatedBy: currentUser.id,
          createdAt: now,
          updatedAt: now,
        );

        await ref.read(routineNotifierProvider.notifier).createRoutine(routine);

        if (mounted) {
          context.go('/routines');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Routine created successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating routine: $e')),
          );
        }
      }
    }
  }
}

