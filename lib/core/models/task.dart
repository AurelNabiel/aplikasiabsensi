import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum TaskPriority {
  low,
  medium,
  high;

  static TaskPriority fromString(String? v) => values.firstWhere(
        (e) => e.name == v,
        orElse: () => TaskPriority.medium,
      );

  String get label => switch (this) {
        TaskPriority.low => 'Rendah',
        TaskPriority.medium => 'Sedang',
        TaskPriority.high => 'Tinggi',
      };

  Color get color => switch (this) {
        TaskPriority.low => AppColors.info,
        TaskPriority.medium => AppColors.warning,
        TaskPriority.high => AppColors.danger,
      };
}

enum SubmissionStatus {
  submitted,
  approved,
  revisi,
  ditolak;

  static SubmissionStatus fromString(String? v) => values.firstWhere(
        (e) => e.name == v,
        orElse: () => SubmissionStatus.submitted,
      );

  String get label => switch (this) {
        SubmissionStatus.submitted => 'Terkumpul',
        SubmissionStatus.approved => 'Disetujui',
        SubmissionStatus.revisi => 'Revisi',
        SubmissionStatus.ditolak => 'Ditolak',
      };

  Color get color => switch (this) {
        SubmissionStatus.submitted => AppColors.info,
        SubmissionStatus.approved => AppColors.success,
        SubmissionStatus.revisi => AppColors.warning,
        SubmissionStatus.ditolak => AppColors.danger,
      };
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.priority,
    this.description,
    this.startDate,
    this.deadline,
    this.mySubmission,
    this.assigneeCount = 0,
    this.submissionCount = 0,
  });

  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final DateTime? startDate;
  final DateTime? deadline;

  /// Status pengumpulan milik user saat ini (tampilan anggota).
  final SubmissionStatus? mySubmission;

  /// Ringkasan untuk tampilan admin.
  final int assigneeCount;
  final int submissionCount;

  bool get isOverdue =>
      deadline != null &&
      DateTime.now().isAfter(deadline!) &&
      (mySubmission == null || mySubmission == SubmissionStatus.revisi);

  factory TaskItem.fromMap(Map<String, dynamic> m, {String? forUserId}) {
    final subs = (m['task_submissions'] as List?) ?? const [];
    final assignees = (m['task_assignees'] as List?) ?? const [];

    SubmissionStatus? mine;
    if (forUserId != null) {
      for (final s in subs) {
        if (s is Map && s['user_id'] == forUserId) {
          mine = SubmissionStatus.fromString(s['status'] as String?);
          break;
        }
      }
    }

    return TaskItem(
      id: m['id'] as String,
      title: m['title'] as String,
      description: m['description'] as String?,
      priority: TaskPriority.fromString(m['priority'] as String?),
      startDate: m['start_date'] != null
          ? DateTime.parse(m['start_date'] as String).toLocal()
          : null,
      deadline: m['deadline'] != null
          ? DateTime.parse(m['deadline'] as String).toLocal()
          : null,
      mySubmission: mine,
      assigneeCount: assignees.length,
      submissionCount: subs.length,
    );
  }
}

class TaskSubmission {
  const TaskSubmission({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.status,
    this.userName,
    this.notes,
    this.submittedAt,
  });

  final String id;
  final String taskId;
  final String userId;
  final String? userName;
  final String? notes;
  final SubmissionStatus status;
  final DateTime? submittedAt;

  factory TaskSubmission.fromMap(Map<String, dynamic> m) {
    final prof = m['profiles'];
    return TaskSubmission(
      id: m['id'] as String,
      taskId: m['task_id'] as String,
      userId: m['user_id'] as String,
      userName: (prof is Map) ? prof['full_name'] as String? : null,
      notes: m['notes'] as String?,
      status: SubmissionStatus.fromString(m['status'] as String?),
      submittedAt: m['submitted_at'] != null
          ? DateTime.parse(m['submitted_at'] as String).toLocal()
          : null,
    );
  }
}
