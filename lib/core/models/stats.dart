enum StatsPeriod {
  minggu,
  bulan,
  tahun;

  String get label => switch (this) {
        StatsPeriod.minggu => 'Minggu',
        StatsPeriod.bulan => 'Bulan',
        StatsPeriod.tahun => 'Tahun',
      };

  /// Granularitas bucket untuk RPC.
  String get bucket => switch (this) {
        StatsPeriod.minggu => 'day',
        StatsPeriod.bulan => 'week',
        StatsPeriod.tahun => 'month',
      };

  /// Rentang [from, to) berdasarkan waktu sekarang (lokal).
  (DateTime, DateTime) range() {
    final now = DateTime.now();
    switch (this) {
      case StatsPeriod.minggu:
        final today = DateTime(now.year, now.month, now.day);
        return (today.subtract(const Duration(days: 6)),
            today.add(const Duration(days: 1)));
      case StatsPeriod.bulan:
        final first = DateTime(now.year, now.month, 1);
        final next = DateTime(now.year, now.month + 1, 1);
        return (first, next);
      case StatsPeriod.tahun:
        return (DateTime(now.year, 1, 1), DateTime(now.year + 1, 1, 1));
    }
  }
}

class StatsSummary {
  const StatsSummary({
    required this.hadir,
    required this.izin,
    required this.sakit,
    required this.alpha,
    required this.pending,
    required this.totalKegiatan,
    required this.tugasTotal,
    required this.tugasDikerjakan,
  });

  final int hadir;
  final int izin;
  final int sakit;
  final int alpha;
  final int pending;
  final int totalKegiatan;
  final int tugasTotal;
  final int tugasDikerjakan;

  /// Tingkat kehadiran 0..1.
  double get rate => totalKegiatan == 0 ? 0 : hadir / totalKegiatan;
  int get ratePct => (rate * 100).round();

  /// Rasio tugas dikerjakan 0..1.
  double get taskRate => tugasTotal == 0 ? 0 : tugasDikerjakan / tugasTotal;

  /// Skor keaktifan gabungan: rata-rata komponen yang tersedia
  /// (kehadiran & tugas). Bila periode tak punya kegiatan/tugas,
  /// komponen itu tidak dihitung.
  double get keaktifan {
    final parts = <double>[];
    if (totalKegiatan > 0) parts.add(rate);
    if (tugasTotal > 0) parts.add(taskRate);
    if (parts.isEmpty) return 0;
    return parts.reduce((a, b) => a + b) / parts.length;
  }

  int get keaktifanPct => (keaktifan * 100).round();

  /// True bila tidak ada aktivitas apa pun pada periode ini.
  bool get isEmpty =>
      totalKegiatan == 0 && tugasTotal == 0 && hadir == 0;

  factory StatsSummary.fromMap(Map<String, dynamic> m) => StatsSummary(
        hadir: (m['hadir'] as num?)?.toInt() ?? 0,
        izin: (m['izin'] as num?)?.toInt() ?? 0,
        sakit: (m['sakit'] as num?)?.toInt() ?? 0,
        alpha: (m['alpha'] as num?)?.toInt() ?? 0,
        pending: (m['pending'] as num?)?.toInt() ?? 0,
        totalKegiatan: (m['total_kegiatan'] as num?)?.toInt() ?? 0,
        tugasTotal: (m['tugas_total'] as num?)?.toInt() ?? 0,
        tugasDikerjakan: (m['tugas_dikerjakan'] as num?)?.toInt() ?? 0,
      );

  static const empty = StatsSummary(
    hadir: 0, izin: 0, sakit: 0, alpha: 0, pending: 0,
    totalKegiatan: 0, tugasTotal: 0, tugasDikerjakan: 0,
  );
}

class StatsPoint {
  const StatsPoint({
    required this.bucket,
    required this.hadir,
    required this.total,
  });

  final DateTime bucket;
  final int hadir;
  final int total;

  factory StatsPoint.fromMap(Map<String, dynamic> m) => StatsPoint(
        bucket: DateTime.parse(m['bucket'] as String),
        hadir: (m['hadir'] as num?)?.toInt() ?? 0,
        total: (m['total'] as num?)?.toInt() ?? 0,
      );
}

class StatsData {
  const StatsData({required this.summary, required this.points});
  final StatsSummary summary;
  final List<StatsPoint> points;
}

/// Statistik ringkas untuk kartu di home.
class DashboardStats {
  const DashboardStats({
    required this.hadirBulan,
    required this.tugasAktif,
    required this.kegiatanMendatang,
  });

  final int hadirBulan;
  final int tugasAktif;
  final int kegiatanMendatang;

  factory DashboardStats.fromMap(Map<String, dynamic> m) => DashboardStats(
        hadirBulan: (m['hadir_bulan'] as num?)?.toInt() ?? 0,
        tugasAktif: (m['tugas_aktif'] as num?)?.toInt() ?? 0,
        kegiatanMendatang: (m['kegiatan_mendatang'] as num?)?.toInt() ?? 0,
      );

  static const empty =
      DashboardStats(hadirBulan: 0, tugasAktif: 0, kegiatanMendatang: 0);
}
