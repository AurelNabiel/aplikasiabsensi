import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/attendance.dart';
import '../../auth/data/attendance_repository.dart';
import 'auth_providers.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepository(ref.watch(supabaseClientProvider)),
);

/// Daftar kehadiran per kegiatan (family by activityId).
final attendancesProvider = FutureProvider.autoDispose
    .family<List<Attendance>, String>((ref, activityId) async {
  return ref.watch(attendanceRepositoryProvider).fetchAttendances(activityId);
});

/// Realtime: memantau perubahan tabel `attendances` untuk satu kegiatan.
/// Dipakai untuk memicu refresh daftar kehadiran otomatis (tanpa nama join).
final attendanceRealtimeProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, activityId) {
  final client = ref.watch(supabaseClientProvider);
  return client
      .from('attendances')
      .stream(primaryKey: ['id']).eq('activity_id', activityId);
});

/// Roster kehadiran (semua anggota + status) per kegiatan.
final activityRosterProvider = FutureProvider.autoDispose
    .family<List<RosterEntry>, String>((ref, activityId) {
  return ref.watch(attendanceRepositoryProvider).fetchRoster(activityId);
});
