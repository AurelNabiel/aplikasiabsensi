import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/profile.dart';
import '../../../core/models/stats.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_providers.dart';
import '../providers/statistics_provider.dart';

const _bulanShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  StatsPeriod _period = StatsPeriod.minggu;
  String? _userId; // null = diri sendiri

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).asData?.value;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statistik')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isStaff = profile.role.isAtLeast(UserRole.petugas);
    final targetId = _userId ?? profile.id;

    // Realtime: statistik ikut ambil ulang saat kehadiran / tugas berubah.
    void refreshStats(_, __) =>
        ref.invalidate(statsDataProvider((userId: targetId, period: _period)));
    ref.listen(userAttendanceRealtimeProvider(targetId), refreshStats);
    ref.listen(userSubmissionRealtimeProvider(targetId), refreshStats);

    final dataAsync =
        ref.watch(statsDataProvider((userId: targetId, period: _period)));

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _PeriodSelector(
            period: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          if (isStaff) ...[
            const SizedBox(height: 16),
            _MemberSelector(
              selfProfile: profile,
              value: _userId,
              onChanged: (id) => setState(() => _userId = id),
            ),
          ],
          const SizedBox(height: 20),
          dataAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text('$e'.replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
            ),
            data: (data) => _StatsBody(data: data, period: _period),
          ),
        ],
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.data, required this.period});
  final StatsData data;
  final StatsPeriod period;

  @override
  Widget build(BuildContext context) {
    final s = data.summary;
    if (s.isEmpty && data.points.isEmpty) {
      return const _EmptyStats();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SummaryCard(
                label: 'Hadir',
                value: '${s.hadir}',
                color: AppColors.success,
                icon: Icons.check_circle_rounded),
            const SizedBox(width: 12),
            _SummaryCard(
                label: 'Kehadiran',
                value: '${s.ratePct}%',
                color: AppColors.primary,
                icon: Icons.percent_rounded),
            const SizedBox(width: 12),
            _SummaryCard(
                label: 'Kegiatan',
                value: '${s.totalKegiatan}',
                color: AppColors.info,
                icon: Icons.event_rounded),
          ],
        ),
        const SizedBox(height: 16),
        _Keaktifan(summary: s),
        const SizedBox(height: 24),
        const Text('Tren Kehadiran',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('Batang penuh = total kegiatan, warna = hadir',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: data.points.isEmpty
              ? const Center(
                  child: Text('Belum ada data pada periode ini',
                      style: TextStyle(color: AppColors.textSecondary)),
                )
              : _AttendanceChart(points: data.points, period: period),
        ),
        const SizedBox(height: 24),
        const Text('Rincian Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusChip('Izin', s.izin, AppColors.info),
            _StatusChip('Sakit', s.sakit, AppColors.warning),
            _StatusChip('Alpha', s.alpha, AppColors.danger),
            _StatusChip('Menunggu', s.pending, AppColors.textSecondary),
          ],
        ),
      ],
    );
  }
}

class _AttendanceChart extends StatelessWidget {
  const _AttendanceChart({required this.points, required this.period});
  final List<StatsPoint> points;
  final StatsPeriod period;

  String _label(DateTime d) => switch (period) {
        StatsPeriod.minggu => '${d.day}',
        StatsPeriod.bulan => '${d.day}/${d.month}',
        StatsPeriod.tahun => _bulanShort[d.month - 1],
      };

  @override
  Widget build(BuildContext context) {
    var maxTotal = 0;
    for (final p in points) {
      if (p.total > maxTotal) maxTotal = p.total;
    }
    final maxY = (maxTotal < 1 ? 1 : maxTotal).toDouble() + 0.5;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _label(points[i].bucket),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].hadir.toDouble(),
                  width: 16,
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: points[i].total.toDouble(),
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.period, required this.onChanged});
  final StatsPeriod period;
  final ValueChanged<StatsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final p in StatsPeriod.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        p == period ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    p.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: p == period
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberSelector extends ConsumerWidget {
  const _MemberSelector({
    required this.selfProfile,
    required this.value,
    required this.onChanged,
  });

  final Profile selfProfile;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider);
    return membersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (members) {
        final others =
            members.where((m) => m.id != selfProfile.id).toList();
        return DropdownButtonFormField<String?>(
          value: value,
          decoration: const InputDecoration(
            labelText: 'Lihat statistik',
            prefixIcon: Icon(Icons.person_search_rounded),
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text('Saya (${selfProfile.fullName})'),
            ),
            for (final m in others)
              DropdownMenuItem(
                value: m.id,
                child: Text(m.fullName.isEmpty ? 'Tanpa nama' : m.fullName),
              ),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
            Icon(icon, color: color, size: 20),
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

class _Keaktifan extends StatelessWidget {
  const _Keaktifan({required this.summary});
  final StatsSummary summary;

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.local_fire_department_rounded,
                  color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              const Text('Keaktifan',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${summary.keaktifanPct}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: summary.keaktifan.clamp(0, 1),
              minHeight: 10,
              backgroundColor: AppColors.primaryLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _KeaktifanPart(
                label: 'Kehadiran',
                value: summary.totalKegiatan == 0
                    ? '—'
                    : '${summary.ratePct}%',
              ),
              const SizedBox(width: 16),
              _KeaktifanPart(
                label: 'Tugas',
                value: summary.tugasTotal == 0
                    ? '—'
                    : '${(summary.taskRate * 100).round()}% '
                        '(${summary.tugasDikerjakan}/${summary.tugasTotal})',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeaktifanPart extends StatelessWidget {
  const _KeaktifanPart({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _EmptyStats extends StatelessWidget {
  const _EmptyStats();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.insights_rounded,
                size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('Belum ada data pada periode ini',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text(
              'Data kehadiran & tugas akan muncul di sini\nsetelah ada aktivitas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label, this.count, this.color);
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count',
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
