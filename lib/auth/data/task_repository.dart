import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/profile.dart';
import '../../../core/models/task.dart';

class TaskRepository {
  TaskRepository(this._client);

  final SupabaseClient _client;

  /// Tugas yang ditugaskan ke [userId] (tampilan anggota).
  Future<List<TaskItem>> fetchMyTasks(String userId) async {
    final rows = await _client
        .from('tasks')
        .select(
            '*, task_assignees!inner(user_id), task_submissions(status, user_id, notes, attachment_url, review_note)')
        .eq('task_assignees.user_id', userId)
        .order('deadline', ascending: true);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map((m) => TaskItem.fromMap(m, forUserId: userId))
        .toList();
  }

  /// Semua tugas (tampilan admin) + ringkasan penugasan & pengumpulan.
  Future<List<TaskItem>> fetchAllTasks() async {
    final rows = await _client
        .from('tasks')
        .select('*, task_assignees(user_id), task_submissions(id)')
        .order('deadline', ascending: true);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map((m) => TaskItem.fromMap(m))
        .toList();
  }

  Future<void> createTask({
    required String title,
    String? description,
    required TaskPriority priority,
    DateTime? startDate,
    DateTime? deadline,
    required List<String> assigneeIds,
  }) async {
    final inserted = await _client
        .from('tasks')
        .insert({
          'title': title,
          'description': description,
          'priority': priority.name,
          'start_date': startDate?.toUtc().toIso8601String(),
          'deadline': deadline?.toUtc().toIso8601String(),
          'created_by': _client.auth.currentUser?.id,
        })
        .select('id')
        .single();

    final taskId = inserted['id'] as String;

    if (assigneeIds.isNotEmpty) {
      await _client.from('task_assignees').insert([
        for (final uid in assigneeIds) {'task_id': taskId, 'user_id': uid},
      ]);
    }
  }

  Future<void> deleteTask(String id) async {
    await _client.from('tasks').delete().eq('id', id);
  }

  /// Anggota mengumpulkan / mengumpulkan ulang tugas (lampiran berupa link).
  /// Mengumpulkan ulang mereset alasan review sebelumnya.
  Future<void> submitTask({
    required String taskId,
    required String userId,
    String? notes,
    String? link,
  }) async {
    await _client.from('task_submissions').upsert(
      {
        'task_id': taskId,
        'user_id': userId,
        'notes': notes,
        'attachment_url': link,
        'status': 'submitted',
        'submitted_at': DateTime.now().toUtc().toIso8601String(),
        'review_note': null,
        'reviewed_at': null,
      },
      onConflict: 'task_id,user_id',
    );
  }

  /// Daftar pengumpulan untuk sebuah tugas (admin).
  Future<List<TaskSubmission>> fetchSubmissions(String taskId) async {
    final rows = await _client
        .from('task_submissions')
        .select('*, profiles!user_id(full_name)')
        .eq('task_id', taskId)
        .order('submitted_at', ascending: false);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(TaskSubmission.fromMap)
        .toList();
  }

  /// Admin me-review pengumpulan (opsional beri alasan, mis. saat menolak/revisi).
  Future<void> reviewSubmission({
    required String submissionId,
    required SubmissionStatus status,
    String? reviewNote,
  }) async {
    await _client.from('task_submissions').update({
      'status': status.name,
      'reviewed_by': _client.auth.currentUser?.id,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      'review_note': reviewNote,
    }).eq('id', submissionId);
  }

  Future<List<Profile>> fetchMembers() async {
    final rows = await _client
        .from('profiles')
        .select()
        .order('full_name', ascending: true);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(Profile.fromMap)
        .toList();
  }

  Future<List<String>> fetchAssigneeIds(String taskId) async {
    final rows = await _client
        .from('task_assignees')
        .select('user_id')
        .eq('task_id', taskId);
    return (rows as List).map((r) => r['user_id'] as String).toList();
  }

  Future<void> updateTask({
    required String taskId,
    required String title,
    String? description,
    required TaskPriority priority,
    DateTime? startDate,
    DateTime? deadline,
    required List<String> assigneeIds,
  }) async {
    await _client.from('tasks').update({
      'title': title,
      'description': description,
      'priority': priority.name,
      'start_date': startDate?.toUtc().toIso8601String(),
      'deadline': deadline?.toUtc().toIso8601String(),
    }).eq('id', taskId);

    // Sinkronkan penerima: hapus lama, isi baru.
    await _client.from('task_assignees').delete().eq('task_id', taskId);
    if (assigneeIds.isNotEmpty) {
      await _client.from('task_assignees').insert([
        for (final uid in assigneeIds) {'task_id': taskId, 'user_id': uid},
      ]);
    }
  }
}
