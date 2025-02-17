import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskfy/models/task.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:intl/intl.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

final taskProvider = StreamProvider.family<Task?, String>((ref, taskId) {
  return supabaseClient.client
      .from('tasks')
      .stream(primaryKey: ['id'])
      .eq('id', taskId)
      .map((data) => data.isNotEmpty ? Task.fromJson(data.first) : null);
});

class TaskDetailScreen extends ConsumerWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsyncValue = ref.watch(taskProvider(taskId));

    return AppLayout(
      title: 'Task Manager',
      pageTitle: 'Task Details',
      child: taskAsyncValue.when(
        data: (task) {
          if (task == null) {
            return const Center(child: Text('Task not found'));
          }
          return _buildTaskDetails(context, ref, task);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildTaskDetails(BuildContext context, WidgetRef ref, Task task) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaskHeader(context, task),
            SizedBox(height: 24),
            _buildTaskInfo(context, task),
            SizedBox(height: 24),
            _buildStatusUpdate(context, ref, task),
            SizedBox(height: 24),
            _buildDescription(context, task),
            SizedBox(height: 24),
            _buildAssignees(context, task),
            SizedBox(height: 24),
            _buildAttachments(context, ref, task),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHeader(BuildContext context, Task task) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip(task.status),
                SizedBox(width: 8),
                _buildPriorityChip(task.priority),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskInfo(BuildContext context, Task task) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(context, 'Deadline', DateFormat('MMM d, y').format(task.deadline)),
            SizedBox(height: 8),
            _buildInfoRow(context, 'Created', DateFormat('MMM d, y').format(task.deadline.subtract(Duration(days: 7)))), // Assuming creation date
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }

  Widget _buildStatusUpdate(BuildContext context, WidgetRef ref, Task task) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update Status', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusButton(context, ref, task, 'Not Started'),
                _buildStatusButton(context, ref, task, 'In Progress'),
                _buildStatusButton(context, ref, task, 'Completed'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(BuildContext context, WidgetRef ref, Task task, String status) {
    final isCurrentStatus = task.status.toLowerCase() == status.toLowerCase();
    return ElevatedButton(
      onPressed: isCurrentStatus ? null : () => _updateStatus(context, ref, task, status),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCurrentStatus ? Theme.of(context).primaryColor : null,
        foregroundColor: isCurrentStatus ? Colors.white : null,
      ),
      child: Text(status),
    );
  }

  Widget _buildDescription(BuildContext context, Task task) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Text(task.description),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignees(BuildContext context, Task task) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assigned To', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: task.assignedTo.map((assignee) => Chip(label: Text(assignee))).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachments(BuildContext context, WidgetRef ref, Task task) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Attachments', style: Theme.of(context).textTheme.titleLarge),
                ElevatedButton.icon(
                  icon: Icon(Icons.upload_file),
                  label: Text('Upload'),
                  onPressed: () => _uploadAttachment(context, ref, task),
                ),
              ],
            ),
            SizedBox(height: 8),
            task.attachments.isEmpty
                ? Text('No attachments')
                : Column(
                    children: task.attachments
                        .map((attachment) => ListTile(
                              leading: Icon(Icons.attachment),
                              title: Text(path.basename(attachment)),
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _deleteAttachment(context, ref, task, attachment),
                              ),
                              onTap: () => _viewAttachment(context, attachment),
                            ))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'in progress':
        color = Colors.blue;
        break;
      case 'not started':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    switch (priority.toLowerCase()) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'low':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        priority,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  void _updateStatus(BuildContext context, WidgetRef ref, Task task, String newStatus) async {
    if (task.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Task ID is null')),
      );
      return;
    }

    try {
      await supabaseClient.client
          .from('tasks')
          .update({'status': newStatus.toLowerCase().replaceAll(' ', '_')})
          .eq('id', task.id as Object);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task status updated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task status: $e')),
        );
      }
    }
  }

  Future<void> _uploadAttachment(BuildContext context, WidgetRef ref, Task task) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );
      
      if (result != null) {
        PlatformFile file = result.files.first;
        String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        String filePath = 'task_attachments/${task.id}/$fileName';

        // Determine the MIME type
        String? mimeType = lookupMimeType(file.name);
        if (mimeType == null) {
          throw Exception('Unable to determine file type');
        }

        // Upload the file
        await supabaseClient.client.storage.from('attachments').uploadBinary(
              filePath,
              file.bytes!,
              fileOptions: FileOptions(contentType: mimeType),
            );

        // Get the public URL
        String publicUrl = supabaseClient.client.storage.from('attachments').getPublicUrl(filePath);

        // Update the task's attachments
        List<String> updatedAttachments = [...task.attachments, publicUrl];
        await _updateTaskAttachments(task.id!, updatedAttachments);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Attachment uploaded successfully')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading attachment: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteAttachment(BuildContext context, WidgetRef ref, Task task, String attachmentUrl) async {
    try {
      String filePath = attachmentUrl.split('attachments/')[1];
      await supabaseClient.client.storage.from('attachments').remove([filePath]);

      List<String> updatedAttachments = task.attachments.where((a) => a != attachmentUrl).toList();
      await _updateTaskAttachments(task.id!, updatedAttachments);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Attachment deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting attachment: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateTaskAttachments(String taskId, List<String> attachments) async {
    await supabaseClient.client
        .from('tasks')
        .update({'attachments': attachments})
        .eq('id', taskId);
  }

  void _viewAttachment(BuildContext context, String attachmentUrl) {
    // For now, we'll just show a dialog with the attachment URL
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Attachment'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Attachment URL:'),
                SizedBox(height: 8),
                Text(attachmentUrl, style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

