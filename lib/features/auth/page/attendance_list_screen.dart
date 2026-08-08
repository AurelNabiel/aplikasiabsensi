import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/activity.dart';
import '../../../core/models/attendance.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../providers/attendance_providers.dart';

class AttendanceListScreen extends ConsumerStatefulWidget {
  const AttendanceListScreen({super.key, required this.activity});
  final Activity activity;

  @override
  ConsumerState<AttendanceListScreen> createState() =>
      _AttendanceListScreenState();
}

class _AttendanceListScreenState extends ConsumerState<AttendanceListScreen> {
  Timer? _debounce;
  Activity get activity => widget.activity;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Realtime (debounce + guard) → refresh roster tanpa badai invalidate.
    ref.listen(attendanceRealtimeProvider(activity.id), (prev, next) {
      if (next is! AsyncData) return;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), () {
        final cur = ref.read(activityRosterProvider(activity.id));
        if (cur.hasValue) ref.invalidate(activityRosterProvider(activity.id));
      });
    });

    final async = ref.watch(activityRosterProvider(activity.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Kehadiran')),
      body: async.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(activityRosterProvider(activity.id)),
            child: const Text('Gagal memuat. Coba lagi'),
          ),
        ),
        data: (roster) {
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(activityRosterProvider(activity.id)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _Summary(roster: roster),
                const SizedBox(height: 16),
                if (roster.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text('Belum ada anggota',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  )
                else
                  for (final e in roster) ...[
                    _RosterTile(
                      entry: e,
                      onTap: () => _setStatus(context, ref, e),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _setStatus(
      BuildContext context, WidgetRef ref, RosterEntry e) async {
    final status = await showModalBottomSheet<AttendanceStatus>(
      context: context,
      builder: (_) => _StatusPicker(
        current: e.status ?? AttendanceStatus.hadir,
        title: e.fullName.isEmpty ? 'Set status' : 'Set status — ${e.fullName}',
      ),
    );
    if (status == null) return;
    try {
      final repo = ref.read(attendanceRepositoryProvider);
      if (e.attendanceId != null) {
        await repo.verifyAttendance(attendanceId: e.attendanceId!, status: status);
      } else {
        await repo.markManual(
          activityId: activity.id,
          userId: e.memberId,
          status: status,
        );
      }
      ref.invalidate(activityRosterProvider(activity.id));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gagal menyimpan status'),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.roster});
  final List<RosterEntry> roster;

  @override
  Widget build(BuildContext context) {
    int hadir = 0, izin = 0, sakit = 0, alpha = 0, pending = 0, belum = 0;
    for (final e in roster) {
      switch (e.status) {
        case AttendanceStatus.hadir:
          hadir++;
        case AttendanceStatus.izin:
          izin++;
        case AttendanceStatus.sakit:
          sakit++;
        case AttendanceStatus.alpha:
          alpha++;
        case AttendanceStatus.pending:
          pending++;
        case null:
          belum++;
      }
    }
    return Container(
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
              const Text('Ringkasan',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${roster.length} anggota',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill('Hadir', hadir, AppColors.success),
              _pill('Izin', izin, AppColors.info),
              _pill('Sakit', sakit, AppColors.warning),
              _pill('Alpha', alpha, AppColors.danger),
              if (pending > 0)
                _pill('Menunggu', pending, AppColors.textSecondary),
              _pill('Belum absen', belum, AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, int count, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count',
                style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      );
}

class _RosterTile extends StatelessWidget {
  const _RosterTile({required this.entry, required this.onTap});
  final RosterEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final initial =
        (e.fullName.isNotEmpty ? e.fullName[0] : '?').toUpperCase();
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Text(initial,
                  style: const TextStyle(color: AppColors.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.fullName.isEmpty ? 'Tanpa nama' : e.fullName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(e.role.label,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      if (e.method != null) ...[
                        const Text(' • ',
                            style: TextStyle(color: AppColors.textSecondary)),
                        Text(e.method!,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                      if (e.distanceM != null) ...[
                        const SizedBox(width: 6),
                        Text('${e.distanceM!.round()} m',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                      if (e.isMocked) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.warning_amber_rounded,
                            size: 14, color: AppColors.danger),
                      ],
                    ],
                  ),
                  if (e.checkInTime != null) ...[
                    const SizedBox(height: 2),
                    Text(formatTanggalJam(e.checkInTime!),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ],
              ),
            ),
            _StatusBadge(status: e.status),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final AttendanceStatus? status;

  @override
  Widget build(BuildContext context) {
    final label = status?.label ?? 'Belum absen';
    final color = status?.color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusPicker extends StatelessWidget {
  const _StatusPicker({required this.current, required this.title});
  final AttendanceStatus current;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
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
