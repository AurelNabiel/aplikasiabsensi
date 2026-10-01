import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/activity.dart';
import '../../../core/models/task.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/user_avatar.dart';
import '../auth/providers/activity_providers.dart';
import '../auth/providers/auth_providers.dart';
import '../auth/providers/task_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).asData?.value;
    final upcoming =
        ref.watch(divisionUpcomingProvider).asData?.value ??
            const <UpcomingActivity>[];

    // Tugas aktif milik user (belum dikumpulkan), ada deadline, urut terdekat.
    final tasks = (profile == null)
        ? const <TaskItem>[]
        : (ref.watch(myTasksProvider(profile.id)).asData?.value ??
                const <TaskItem>[])
            .where((t) => t.mySubmission == null)
            .toList()
      ..sort((a, b) {
        final da = a.deadline, db = b.deadline;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

    final empty = upcoming.isEmpty && tasks.isEmpty;

    return Scaffold(
      appBar: const GradientAppBar(title: 'Notifikasi'),
      body: empty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_rounded,
                      size: 64,
                      color: AppColors.textSecondary.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  const Text('Belum ada notifikasi',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (upcoming.isNotEmpty) ...[
                  const _SectionTitle('Kegiatan Mendatang'),
                  for (final a in upcoming) _ActivityNotif(activity: a),
                  const SizedBox(height: 8),
                ],
                if (tasks.isNotEmpty) ...[
                  const _SectionTitle('Tugas Aktif'),
                  for (final t in tasks) _TaskNotif(task: t),
                ],
              ],
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Text(text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      );
}

class _ActivityNotif extends StatelessWidget {
  const _ActivityNotif({required this.activity});
  final UpcomingActivity activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_available_rounded,
                color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(formatRelatif(activity.startTime),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          _DivisionTag(division: activity.division),
        ],
      ),
    );
  }
}

class _TaskNotif extends StatelessWidget {
  const _TaskNotif({required this.task});
  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final overdue = task.isOverdue;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.checklist_rounded, color: AppColors.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  task.deadline == null
                      ? 'Tanpa deadline'
                      : overdue
                          ? 'Terlambat'
                          : 'Deadline ${formatRelatif(task.deadline!)}',
                  style: TextStyle(
                      color: overdue ? AppColors.danger : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          overdue ? FontWeight.w600 : FontWeight.normal),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Tugas',
                style: TextStyle(
                    color: AppColors.info,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Tag divisi (logo + label) untuk mengenali sumber notifikasi.
class _DivisionTag extends StatelessWidget {
  const _DivisionTag({required this.division});
  final dynamic division; // Division?

  @override
  Widget build(BuildContext context) {
    if (division == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Umum',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600)),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DivisionLogo(asset: division.asset, size: 20),
          const SizedBox(width: 6),
          Text(division.label,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
