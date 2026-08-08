import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/profile.dart';
import '../../../core/models/stats.dart';
import '../data/statistics_repository.dart';
import 'auth_providers.dart';

final statisticsRepositoryProvider = Provider<StatisticsRepository>(
  (ref) => StatisticsRepository(ref.watch(supabaseClientProvider)),
);

typedef StatsArgs = ({String userId, StatsPeriod period});

final statsDataProvider =
    FutureProvider.autoDispose.family<StatsData, StatsArgs>((ref, args) async {
  ref.watch(authStateChangesProvider); // refetch saat akun berganti
  final repo = ref.watch(statisticsRepositoryProvider);
  final (from, to) = args.period.range();
  final summary = await repo.summary(userId: args.userId, from: from, to: to);
  final points = await repo.series(
    userId: args.userId,
    from: from,
    to: to,
    bucket: args.period.bucket,
  );
  return StatsData(summary: summary, points: points);
});

/// Kartu ringkas di home (Hadir bulan ini, Tugas aktif, Kegiatan mendatang).
final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  ref.watch(authStateChangesProvider); // refetch saat akun berganti
  return ref.watch(statisticsRepositoryProvider).dashboard();
});

/// Untuk petugas/admin memilih anggota lain.
final membersProvider = FutureProvider.autoDispose<List<Profile>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final rows =
      await client.from('profiles').select().order('full_name', ascending: true);
  return (rows as List)
      .cast<Map<String, dynamic>>()
      .map(Profile.fromMap)
      .toList();
});

/// Realtime: perubahan kehadiran milik user (untuk auto-refresh statistik/home).
final userAttendanceRealtimeProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, userId) {
  final client = ref.watch(supabaseClientProvider);
  return client
      .from('attendances')
      .stream(primaryKey: ['id']).eq('user_id', userId);
});

/// Realtime: perubahan pengumpulan tugas milik user.
final userSubmissionRealtimeProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, userId) {
  final client = ref.watch(supabaseClientProvider);
  return client
      .from('task_submissions')
      .stream(primaryKey: ['id']).eq('user_id', userId);
});
