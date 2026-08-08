import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/task.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../providers/auth_providers.dart';
import '../providers/task_provider.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.isAdmin,
  });

  final TaskItem task;
  final bool isAdmin;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _notes = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final profile = ref.read(currentProfileProvider).asData?.value;
    if (profile == null) return;
    setState(() => _submitting = true);
    try {
      await ref.read(taskRepositoryProvider).submitTask(
            taskId: widget.task.id,
            userId: profile.id,
            notes: _notes.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tugas dikumpulkan'),
              backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gagal mengumpulkan'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteTask() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus tugas?'),
        content: const Text('Tugas & semua pengumpulannya akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (yes != true) return;
    await ref.read(taskRepositoryProvider).deleteTask(widget.task.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tugas'),
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _deleteTask,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(t.title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: t.priority.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Prioritas ${t.priority.label}',
                    style: TextStyle(
                        color: t.priority.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (t.description != null && t.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(t.description!,
                style: const TextStyle(color: AppColors.textPrimary)),
          ],
          const SizedBox(height: 16),
          _InfoRow(
              icon: Icons.play_arrow_rounded,
              label: 'Mulai',
              value: t.startDate != null
                  ? formatTanggalJam(t.startDate!)
                  : '-'),
          const SizedBox(height: 8),
          _InfoRow(
              icon: Icons.flag_rounded,
              label: 'Deadline',
              value:
                  t.deadline != null ? formatTanggalJam(t.deadline!) : '-',
              danger: t.isOverdue),
          const Divider(height: 40),
          if (widget.isAdmin)
            _AdminReview(taskId: t.id)
          else
            _MemberSubmit(
              task: t,
              notesController: _notes,
              submitting: _submitting,
              onSubmit: _submit,
            ),
        ],
      ),
    );
  }
}

class _MemberSubmit extends StatelessWidget {
  const _MemberSubmit({
    required this.task,
    required this.notesController,
    required this.submitting,
    required this.onSubmit,
  });

  final TaskItem task;
  final TextEditingController notesController;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final sub = task.mySubmission;
    final approved = sub == SubmissionStatus.approved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sub != null)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: sub.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: sub.color),
                const SizedBox(width: 10),
                Text('Status pengumpulan: ${sub.label}',
                    style: TextStyle(
                        color: sub.color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        if (!approved) ...[
          const Text('Catatan pengumpulan',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          TextField(
            controller: notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Tulis catatan / tautan hasil kerja...',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: submitting ? null : onSubmit,
            icon: submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white))
                : const Icon(Icons.upload_rounded),
            label: Text(sub == null ? 'Kumpulkan' : 'Kumpulkan Ulang'),
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success),
                SizedBox(width: 10),
                Text('Tugas sudah disetujui. Selesai!',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }
}

class _AdminReview extends ConsumerWidget {
  const _AdminReview({required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(submissionsProvider(taskId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pengumpulan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        async.when(
          loading: () =>
              const Center(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator())),
          error: (_, __) => const Text('Gagal memuat pengumpulan'),
          data: (subs) {
            if (subs.isEmpty) {
              return const Text('Belum ada yang mengumpulkan',
                  style: TextStyle(color: AppColors.textSecondary));
            }
            return Column(
              children: [
                for (final s in subs)
                  _SubmissionTile(
                    submission: s,
                    onReview: (status) async {
                      await ref.read(taskRepositoryProvider).reviewSubmission(
                            submissionId: s.id,
                            status: status,
                          );
                      ref.invalidate(submissionsProvider(taskId));
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  const _SubmissionTile({required this.submission, required this.onReview});
  final TaskSubmission submission;
  final Future<void> Function(SubmissionStatus) onReview;

  Future<void> _pickReview(BuildContext context) async {
    final status = await showModalBottomSheet<SubmissionStatus>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Review pengumpulan',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success),
              title: const Text('Setujui'),
              onTap: () => Navigator.pop(context, SubmissionStatus.approved),
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded,
                  color: AppColors.warning),
              title: const Text('Minta Revisi'),
              onTap: () => Navigator.pop(context, SubmissionStatus.revisi),
            ),
            ListTile(
              leading:
                  const Icon(Icons.cancel_rounded, color: AppColors.danger),
              title: const Text('Tolak'),
              onTap: () => Navigator.pop(context, SubmissionStatus.ditolak),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (status != null) await onReview(status);
  }

  @override
  Widget build(BuildContext context) {
    final s = submission;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s.userName ?? 'Anggota',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: s.status.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(s.status.label,
                    style: TextStyle(
                        color: s.status.color,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (s.notes != null && s.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(s.notes!,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
          if (s.submittedAt != null) ...[
            const SizedBox(height: 6),
            Text(formatTanggalJam(s.submittedAt!),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _pickReview(context),
              icon: const Icon(Icons.rate_review_rounded, size: 18),
              label: const Text('Review'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.textSecondary;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: danger ? AppColors.danger : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
