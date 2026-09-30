import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/activity.dart';
import '../../../core/models/profile.dart';
import '../data/activity_repository.dart';
import 'auth_providers.dart';

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(ref.watch(supabaseClientProvider)),
);

/// Daftar kegiatan, TERFILTER per divisi:
/// - Admin/Super Admin: melihat semua divisi (untuk pengelolaan).
/// - Petugas/Anggota: hanya kegiatan divisinya sendiri + kegiatan Umum
///   (division null). Jadi antar divisi tidak bercampur.
/// Panggil `ref.invalidate(activitiesProvider)` setelah create/update/delete.
final activitiesProvider =
    FutureProvider.autoDispose<List<Activity>>((ref) async {
  final all = await ref.watch(activityRepositoryProvider).fetchActivities();
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return all;
  if (profile.role.isAtLeast(UserRole.admin)) return all;
  final myDiv = profile.division;
  return all
      .where((a) => a.division == null || a.division == myDiv)
      .toList();
});

/// Realtime: perubahan tabel activities (untuk kartu "Kegiatan" & daftar Jadwal).
final activitiesRealtimeProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.from('activities').stream(primaryKey: ['id']);
});

/// Pengingat: kegiatan mendatang untuk divisi user.
final divisionUpcomingProvider =
    FutureProvider.autoDispose<List<UpcomingActivity>>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(activityRepositoryProvider).divisionUpcoming();
});
