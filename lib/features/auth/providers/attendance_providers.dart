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
