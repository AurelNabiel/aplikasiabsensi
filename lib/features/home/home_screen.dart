import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/profile.dart';
import '../../core/models/stats.dart';
import '../../core/theme/app_colors.dart';
import '../auth/providers/auth_providers.dart';
import '../auth/providers/statistics_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

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
    final name =
        profile?.fullName.isNotEmpty == true ? profile!.fullName : 'Pengguna';
    final role = profile?.role.label ?? '-';

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo, $name 👋',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(role,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        const Spacer(),
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
            value: '${stats.kegiatanMendatang}',
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
