import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/activity.dart';
import '../../../core/models/profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../providers/activity_providers.dart';
import '../providers/auth_providers.dart';

class ActivityListScreen extends ConsumerWidget {
  const ActivityListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesProvider);
    final profile = ref.watch(currentProfileProvider).asData?.value;
    final isAdmin = profile?.role.isAtLeast(UserRole.admin) ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Kegiatan')),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/activity/form'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label:
                  const Text('Kegiatan', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: activitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          onRetry: () => ref.invalidate(activitiesProvider),
        ),
        data: (items) {
          if (items.isEmpty) return const _EmptyState();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(activitiesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _ActivityCard(
                activity: items[i],
                isAdmin: isAdmin,
                onEdit: () =>
                    context.push('/activity/form', extra: items[i]),
                onDelete: () => _confirmDelete(context, ref, items[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Activity a) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus kegiatan?'),
        content: Text('"${a.title}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await ref.read(activityRepositoryProvider).deleteActivity(a.id);
      ref.invalidate(activitiesProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gagal menghapus'),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  final Activity activity;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: isAdmin ? onEdit : null,
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
                  child: Text(
                    activity.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                if (isAdmin)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
              ],
            ),
            if (activity.description != null &&
                activity.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                activity.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            _infoRow(Icons.schedule_rounded, formatTanggalJam(activity.startTime)),
            const SizedBox(height: 6),
            _infoRow(Icons.flag_outlined,
                'Selesai ${formatJam(activity.endTime)}'),
            const SizedBox(height: 12),
            _MethodChip(method: activity.method),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12.5)),
      ],
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({required this.method});
  final ActivityMethod method;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (method) {
      ActivityMethod.qr => (AppColors.primary, Icons.qr_code_rounded),
      ActivityMethod.location => (AppColors.accent, Icons.location_on_rounded),
      ActivityMethod.manual => (AppColors.warning, Icons.how_to_reg_rounded),
      ActivityMethod.any => (AppColors.info, Icons.all_inclusive_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(method.label,
              style: TextStyle(
                  color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_rounded,
              size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('Belum ada kegiatan',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Gagal memuat data'),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
