import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/project.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:intl/intl.dart';

final projectProvider = StreamProvider.family<Project?, String>((ref, projectId) {
  return supabaseClient.client
      .from('projects')
      .stream(primaryKey: ['id'])
      .eq('id', projectId)
      .map((data) => data.isNotEmpty ? Project.fromJson(data.first) : null);
});

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsyncValue = ref.watch(projectProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('Project Detail')),
      body: projectAsyncValue.when(
        data: (project) {
          if (project == null) {
            return const Center(child: Text('Project not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.name, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(project.description, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                _buildInfoRow('Status', project.status),
                _buildInfoRow('Priority', project.priority),
                _buildInfoRow('Start Date', DateFormat('yyyy-MM-dd').format(project.startDate)),
                _buildInfoRow('End Date', DateFormat('yyyy-MM-dd').format(project.endDate)),
                _buildInfoRow('Completion', '${project.completion.toStringAsFixed(1)}%'),
                const SizedBox(height: 16),
                Text('Team Members', style: Theme.of(context).textTheme.headlineSmall),
                ...project.teamMembers.map((member) => ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(member),
                    )),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showUpdateDialog(context, project),
                  child: const Text('Update Project'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Project'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: project.status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['not_started', 'in_progress', 'completed'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    _updateProject(context, {'status': newValue});
                  }
                },
              ),
              TextFormField(
                initialValue: project.completion.toString(),
                decoration: const InputDecoration(labelText: 'Completion (%)'),
                keyboardType: TextInputType.number,
                onFieldSubmitted: (value) {
                  final completion = double.tryParse(value);
                  if (completion != null) {
                    _updateProject(context, {'completion': completion});
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _updateProject(BuildContext context, Map<String, dynamic> updates) async {
    try {
      await supabaseClient.client.from('projects').update(updates).eq('id', projectId);
      if (context.mounted) {
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project updated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating project: $e')),
        );
      }
    }
  }
}

