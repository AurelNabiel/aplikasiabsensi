import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/activity.dart';
import '../data/activity_repository.dart';
import 'auth_providers.dart';

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(ref.watch(supabaseClientProvider)),
);

/// Daftar kegiatan. Panggil `ref.invalidate(activitiesProvider)`
/// setelah create/update/delete untuk refresh.
final activitiesProvider =
    FutureProvider.autoDispose<List<Activity>>((ref) async {
  return ref.watch(activityRepositoryProvider).fetchActivities();
});
