import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/profile.dart';
import '../../../core/models/task.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../providers/auth_providers.dart';
import '../providers/task_provider.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).asData?.value;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tugas')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isAdmin = profile.role.isAtLeast(UserRole.admin);
    final tasksAsync = isAdmin
        ? ref.watch(allTasksProvider)
        : ref.watch(myTasksProvider(profile.id));

    void refresh() {
      if (isAdmin) {
        ref.invalidate(allTasksProvider);
      } else {
        ref.invalidate(myTasksProvider(profile.id));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tugas')),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TaskFormScreen()),
                );
                refresh();
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Tugas', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: TextButton(
            onPressed: refresh,
            child: const Text('Gagal memuat. Coba lagi'),
          ),
        ),
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.checklist_rounded,
                      size: 64,
                      color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text(isAdmin ? 'Belum ada tugas' : 'Belum ada tugas untukmu',
                      style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _TaskCard(
                task: tasks[i],
                isAdmin: isAdmin,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TaskDetailScreen(task: tasks[i], isAdmin: isAdmin),
                    ),
                  );
                  refresh();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.isAdmin,
    required this.onTap,
  });

  final TaskItem task;
  final bool isAdmin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(task.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                _PriorityChip(priority: task.priority),
              ],
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.flag_rounded,
                    size: 15,
                    color:
                        task.isOverdue ? AppColors.danger : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  task.deadline != null
                      ? 'Deadline ${formatTanggalJam(task.deadline!)}'
                      : 'Tanpa deadline',
                  style: TextStyle(
                    color:
                        task.isOverdue ? AppColors.danger : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight:
                        task.isOverdue ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isAdmin)
              _Badge(
                text: '${task.submissionCount}/${task.assigneeCount} terkumpul',
                color: AppColors.info,
              )
            else
              _MemberStatusBadge(task: task),
          ],
        ),
      ),
    );
  }
}

class _MemberStatusBadge extends StatelessWidget {
  const _MemberStatusBadge({required this.task});
  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    if (task.mySubmission != null) {
      return _Badge(
          text: task.mySubmission!.label, color: task.mySubmission!.color);
    }
    if (task.isOverdue) {
      return const _Badge(text: 'Terlambat', color: AppColors.danger);
    }
    return const _Badge(text: 'Belum dikumpulkan', color: AppColors.textSecondary);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});
  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: priority.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(priority.label,
          style: TextStyle(
              color: priority.color,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}
