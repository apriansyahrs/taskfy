import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskfy/models/routine.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:intl/intl.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:taskfy/config/style_guide.dart';

final routineProvider = StreamProvider.family<Routine?, String>((ref, routineId) {
  return getIt<SupabaseClientWrapper>().client
      .from('routines')
      .stream(primaryKey: ['id'])
      .eq('id', routineId)
      .map((data) => data.isNotEmpty ? Routine.fromJson(data.first) : null);
});

final permissionProvider = Provider<Set<String>>((ref) => {'update_routine'}); //Example provider, replace with your actual implementation

class RoutineDetailScreen extends ConsumerWidget {
  final String routineId;

  const RoutineDetailScreen({super.key, required this.routineId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineAsyncValue = ref.watch(routineProvider(routineId));
    final permissions = ref.watch(permissionProvider);

    return AppLayout(
      title: 'Routine Manager',
      pageTitle: 'Routine Details',
      child: routineAsyncValue.when(
        data: (routine) {
          if (routine == null) {
            return const Center(child: Text('Routine not found'));
          }
          return _buildRoutineDetails(context, ref, routine, permissions);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildRoutineDetails(BuildContext context, WidgetRef ref, Routine routine, Set<String> permissions) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(StyleGuide.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoutineHeader(context, routine),
            SizedBox(height: StyleGuide.spacingLarge),
            _buildRoutineInfo(context, routine),
            SizedBox(height: StyleGuide.spacingLarge),
            if (permissions.contains('update_routine'))
              _buildStatusUpdate(context, ref, routine),
            SizedBox(height: StyleGuide.spacingLarge),
            _buildDescription(context, routine),
            SizedBox(height: StyleGuide.spacingLarge),
            _buildAssignees(context, routine),
            SizedBox(height: StyleGuide.spacingLarge),
            if (permissions.contains('update_routine'))
              _buildAttachments(context, ref, routine),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineHeader(BuildContext context, Routine routine) {
    return Card(
      elevation: StyleGuide.cardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StyleGuide.borderRadiusLarge)),
      child: Padding(
        padding: const EdgeInsets.all(StyleGuide.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              routine.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: StyleGuide.spacingSmall),
            Row(
              children: [
                _buildStatusChip(routine.status),
                SizedBox(width: StyleGuide.spacingSmall),
                _buildPriorityChip(routine.priority),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineInfo(BuildContext context, Routine routine) {
    return Card(
      elevation: StyleGuide.cardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StyleGuide.borderRadiusLarge)),
      child: Padding(
        padding: const EdgeInsets.all(StyleGuide.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(context, 'Due Date', DateFormat('MMM d, y').format(routine.dueDate)),
            SizedBox(height: StyleGuide.spacingSmall),
            _buildInfoRow(context, 'Created', DateFormat('MMM d, y').format(routine.createdAt)),
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

  Widget _buildStatusUpdate(BuildContext context, WidgetRef ref, Routine routine) {
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
                _buildStatusButton(context, ref, routine, 'Not Started'),
                _buildStatusButton(context, ref, routine, 'In Progress'),
                _buildStatusButton(context, ref, routine, 'Completed'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(BuildContext context, WidgetRef ref, Routine routine, String status) {
    final isCurrentStatus = routine.status.toLowerCase() == status.toLowerCase();
    return ElevatedButton(
      onPressed: isCurrentStatus ? null : () => _updateStatus(context, ref, routine, status),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCurrentStatus ? Theme.of(context).primaryColor : null,
        foregroundColor: isCurrentStatus ? Colors.white : null,
      ),
      child: Text(status),
    );
  }

  Widget _buildDescription(BuildContext context, Routine routine) {
    return Card(
      elevation: StyleGuide.cardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StyleGuide.borderRadiusLarge)),
      child: Padding(
        padding: const EdgeInsets.all(StyleGuide.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: StyleGuide.spacingSmall),
            Text(routine.description),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignees(BuildContext context, Routine routine) {
    return Card(
      elevation: StyleGuide.cardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StyleGuide.borderRadiusLarge)),
      child: Padding(
        padding: const EdgeInsets.all(StyleGuide.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assigned To', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: StyleGuide.spacingSmall),
            Wrap(
              spacing: StyleGuide.spacingSmall,
              runSpacing: StyleGuide.spacingSmall,
              children: routine.assignees.map((assignee) => Chip(label: Text(assignee))).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachments(BuildContext context, WidgetRef ref, Routine routine) {
    return Card(
      elevation: StyleGuide.cardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StyleGuide.borderRadiusLarge)),
      child: Padding(
        padding: const EdgeInsets.all(StyleGuide.paddingMedium),
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
                  onPressed: () => _uploadAttachment(context, ref, routine),
                ),
              ],
            ),
            SizedBox(height: StyleGuide.spacingSmall),
            routine.attachments.isEmpty
                ? Text('No attachments')
                : Column(
                    children: routine.attachments
                        .map((attachment) => ListTile(
                              leading: Icon(Icons.attachment),
                              title: Text(path.basename(attachment)),
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _deleteAttachment(context, ref, routine, attachment),
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

  void _updateStatus(BuildContext context, WidgetRef ref, Routine routine, String newStatus) async {
    if (routine.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Routine ID is null')),
      );
      return;
    }

    try {
      await getIt<SupabaseClientWrapper>().client
          .from('routines')
          .update({'status': newStatus.toLowerCase().replaceAll(' ', '_')})
          .eq('id', routine.id as Object);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Routine status updated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating routine status: $e')),
        );
      }
    }
  }

  Future<void> _uploadAttachment(BuildContext context, WidgetRef ref, Routine routine) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );
      
      if (result != null) {
        PlatformFile file = result.files.first;
        String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        String filePath = 'routine_attachments/${routine.id}/$fileName';

        // Determine the MIME type
        String? mimeType = lookupMimeType(file.name);
        if (mimeType == null) {
          throw Exception('Unable to determine file type');
        }

        // Upload the file
        await getIt<SupabaseClientWrapper>().client.storage.from('attachments').uploadBinary(
              filePath,
              file.bytes!,
              fileOptions: FileOptions(contentType: mimeType),
            );

        // Get the public URL
        String publicUrl = getIt<SupabaseClientWrapper>().client.storage.from('attachments').getPublicUrl(filePath);

        // Update the routine's attachments
        List<String> updatedAttachments = [...routine.attachments, publicUrl];
        await _updateRoutineAttachments(routine.id!, updatedAttachments);

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

  Future<void> _deleteAttachment(BuildContext context, WidgetRef ref, Routine routine, String attachmentUrl) async {
    try {
      String filePath = attachmentUrl.split('attachments/')[1];
      await getIt<SupabaseClientWrapper>().client.storage.from('attachments').remove([filePath]);

      List<String> updatedAttachments = (routine.attachments).where((a) => a != attachmentUrl).map((e) => e.toString()).toList();
      await _updateRoutineAttachments(routine.id!, updatedAttachments);

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

  Future<void> _updateRoutineAttachments(String routineId, List<String> attachments) async {
    await getIt<SupabaseClientWrapper>().client
        .from('routines')
        .update({'attachments': attachments})
        .eq('id', routineId);
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

