import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/activity.dart';
import '../../../core/models/attendance.dart';
import '../../../core/models/profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../providers/attendance_providers.dart';

class AttendanceListScreen extends ConsumerWidget {
  const AttendanceListScreen({super.key, required this.activity});
  final Activity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(attendancesProvider(activity.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Kehadiran')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _manualAdd(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('Manual', style: TextStyle(color: Colors.white)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(attendancesProvider(activity.id)),
            child: const Text('Gagal memuat. Coba lagi'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Belum ada kehadiran',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(attendancesProvider(activity.id)),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _AttendanceTile(
                attendance: items[i],
                onChangeStatus: () =>
                    _changeStatus(context, ref, items[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _changeStatus(
      BuildContext context, WidgetRef ref, Attendance a) async {
    final status = await showModalBottomSheet<AttendanceStatus>(
      context: context,
      builder: (_) => _StatusPicker(current: a.status),
    );
    if (status == null) return;
    try {
      await ref
          .read(attendanceRepositoryProvider)
          .verifyAttendance(attendanceId: a.id, status: status);
      ref.invalidate(attendancesProvider(activity.id));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gagal mengubah status'),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _manualAdd(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(attendanceRepositoryProvider);
    List<Profile> profiles;
    try {
      profiles = await repo.fetchAllProfiles();
    } catch (_) {
      return;
    }
    if (!context.mounted) return;

    final picked = await showModalBottomSheet<Profile>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProfilePicker(profiles: profiles),
    );
    if (picked == null || !context.mounted) return;

    final status = await showModalBottomSheet<AttendanceStatus>(
      context: context,
      builder: (_) => const _StatusPicker(current: AttendanceStatus.hadir),
    );
    if (status == null) return;

    try {
      await repo.markManual(
        activityId: activity.id,
        userId: picked.id,
        status: status,
      );
      ref.invalidate(attendancesProvider(activity.id));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gagal menyimpan'),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({
    required this.attendance,
    required this.onChangeStatus,
  });
  final Attendance attendance;
  final VoidCallback onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final a = attendance;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onChangeStatus,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.userName ?? 'Anggota',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Metode: ${a.method}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      if (a.distanceM != null) ...[
                        const SizedBox(width: 8),
                        Text('• ${a.distanceM!.round()} m',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                      if (a.isMocked) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.warning_amber_rounded,
                            size: 14, color: AppColors.danger),
                        const Text(' mock',
                            style: TextStyle(
                                color: AppColors.danger, fontSize: 12)),
                      ],
                    ],
                  ),
                  if (a.checkInTime != null) ...[
                    const SizedBox(height: 2),
                    Text(formatTanggalJam(a.checkInTime!),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ],
              ),
            ),
            _StatusBadge(status: a.status),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final AttendanceStatus status;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.label,
          style: TextStyle(
              color: status.color,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusPicker extends StatelessWidget {
  const _StatusPicker({required this.current});
  final AttendanceStatus current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const Text('Ubah status kehadiran',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final s in AttendanceStatus.values)
            ListTile(
              leading: Icon(Icons.circle, color: s.color, size: 14),
              title: Text(s.label),
              trailing: s == current
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.pop(context, s),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ProfilePicker extends StatelessWidget {
  const _ProfilePicker({required this.profiles});
  final List<Profile> profiles;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scroll) => Column(
        children: [
          const SizedBox(height: 12),
          const Text('Pilih anggota',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              itemCount: profiles.length,
              itemBuilder: (_, i) {
                final p = profiles[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      (p.fullName.isNotEmpty ? p.fullName[0] : '?')
                          .toUpperCase(),
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                  title: Text(p.fullName.isEmpty ? 'Tanpa nama' : p.fullName),
                  subtitle: Text(p.role.label),
                  onTap: () => Navigator.pop(context, p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
