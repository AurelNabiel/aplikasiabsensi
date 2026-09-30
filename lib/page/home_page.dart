import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/activity.dart';
import '../../core/models/profile.dart';
import '../../core/models/stats.dart';
import '../../core/models/task.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/user_avatar.dart';
import '../auth/providers/auth_providers.dart';
import '../page/notification_page.dart';
import '../auth/providers/activity_providers.dart';
import '../auth/providers/statistics_provider.dart';
import '../auth/providers/task_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // Refresh dashboard & pengingat secara debounced, dengan guard agar tidak
  // mengganggu pemuatan pertama (mencegah badai invalidate).
  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (ref.read(dashboardStatsProvider).hasValue) {
        ref.invalidate(dashboardStatsProvider);
      }
      if (ref.read(divisionUpcomingProvider).hasValue) {
        ref.invalidate(divisionUpcomingProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    // Realtime → refresh. Hanya bereaksi ke emisi DATA (abaikan loading/error),
    // supaya stream yang berkedip/error tidak memicu invalidate terus-menerus.
    final myId = profileAsync.asData?.value?.id;
    if (myId != null) {
      void onEvent(Object? prev, Object? next) {
        if (next is AsyncData) _scheduleRefresh();
      }
      ref.listen(userAttendanceRealtimeProvider(myId), onEvent);
      ref.listen(userSubmissionRealtimeProvider(myId), onEvent);
      ref.listen(activitiesRealtimeProvider, onEvent);
      ref.listen(myTaskAssignRealtimeProvider(myId), onEvent);
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(currentProfileProvider);

            // Tunggu hingga data selesai dimuat ulang
            await Future.wait([
              ref.read(dashboardStatsProvider.future),
              ref.read(currentProfileProvider.future),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              profileAsync.when(
                data: (profile) => _Header(profile: profile, ref: ref),
                loading: () => const SizedBox(
                  height: 48,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => _Header(profile: null, ref: ref),
              ),
              const SizedBox(height: 24),
              const _StatRow(),
              const _NextActivityCountdown(),
              const SizedBox(height: 24),
              const Text(
                'Menu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const _MenuGrid(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/attendance'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        label: const Text(
          'Absen',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.ref});

  final Profile? profile;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final name = profile?.callName ?? 'Pengguna';
    final role = profile?.role.label ?? '-';

    return Row(
      children: [
        UserAvatar(
          name: profile?.fullName ?? '',
          url: profile?.avatarUrl,
          radius: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Halo, $name 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              Text(role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const _NotifBell(),
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Keluar',
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ],
    );
  }
}

class _StatRow extends ConsumerWidget {
  const _StatRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats =
        ref.watch(dashboardStatsProvider).asData?.value ?? DashboardStats.empty;
    return Row(
      children: [
        _StatCard(
            label: 'Hadir',
            value: '${stats.hadirBulan}',
            color: AppColors.success,
            icon: Icons.check_circle_rounded),
        const SizedBox(width: 12),
        _StatCard(
            label: 'Tugas',
            value: '${stats.tugasAktif}',
            color: AppColors.info,
            icon: Icons.task_alt_rounded),
        const SizedBox(width: 12),
        _StatCard(
            label: 'Kegiatan',
            value: '${stats.kegiatanBerlangsung}',
            color: AppColors.warning,
            icon: Icons.event_rounded),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid();

  @override
  Widget build(BuildContext context) {
    final routes = {
      'Jadwal': '/activities',
      'Absensi': '/attendance',
      'Statistik': '/statistics',
      'Tugas': '/tasks',
      'Profil': '/profile',
      'Anggota': '/members',
    };
    const items = [
      ('Absensi', Icons.how_to_reg_rounded, AppColors.primary),
      ('Jadwal', Icons.calendar_month_rounded, AppColors.accent),
      ('Tugas', Icons.checklist_rounded, AppColors.success),
      ('Statistik', Icons.bar_chart_rounded, AppColors.warning),
      ('Anggota', Icons.groups_rounded, AppColors.info),
      ('Profil', Icons.person_rounded, AppColors.danger),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        for (final it in items)
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              final path = routes[it.$1];
              if (path != null) context.push(path);
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: it.$3.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(it.$2, color: it.$3),
                  ),
                  const SizedBox(height: 8),
                  Text(it.$1, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          )
      ],
    );
  }
}

class _NotifBell extends ConsumerWidget {
  const _NotifBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming =
        ref.watch(divisionUpcomingProvider).asData?.value ?? const [];
    final profile = ref.watch(currentProfileProvider).asData?.value;
    final tasks = profile == null
        ? const <TaskItem>[]
        : (ref.watch(myTasksProvider(profile.id)).asData?.value ??
                const <TaskItem>[])
            .where((t) => t.mySubmission == null)
            .toList();
    final count = upcoming.length + tasks.length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          tooltip: 'Notifikasi',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationScreen()),
          ),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}

class _NextActivityCountdown extends ConsumerStatefulWidget {
  const _NextActivityCountdown();

  @override
  ConsumerState<_NextActivityCountdown> createState() =>
      _NextActivityCountdownState();
}

class _NextActivityCountdownState
    extends ConsumerState<_NextActivityCountdown> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(divisionUpcomingProvider).asData?.value ??
        const <UpcomingActivity>[];
    if (items.isEmpty) return const SizedBox.shrink();
    final a = items.first;
    final remaining = a.startTime.difference(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text('Kegiatan Berikutnya',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const Spacer(),
                _tag(a.division?.label ?? 'Umum'),
              ],
            ),
            const SizedBox(height: 12),
            Text(a.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(formatHitungMundur(remaining),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
            const SizedBox(height: 2),
            Text('mulai ${formatTanggalJam(a.startTime)}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.22),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600)),
      );
}
