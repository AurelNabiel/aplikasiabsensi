import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/profile.dart';
import '../../../core/models/task.dart';
import '../data/task_repository.dart';
import 'auth_providers.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(supabaseClientProvider)),
);

/// Tugas milik anggota tertentu.
final myTasksProvider =
    FutureProvider.autoDispose.family<List<TaskItem>, String>((ref, userId) {
  return ref.watch(taskRepositoryProvider).fetchMyTasks(userId);
});

/// Semua tugas (admin).
final allTasksProvider = FutureProvider.autoDispose<List<TaskItem>>((ref) {
  return ref.watch(taskRepositoryProvider).fetchAllTasks();
});

/// Pengumpulan untuk sebuah tugas.
final submissionsProvider = FutureProvider.autoDispose
    .family<List<TaskSubmission>, String>((ref, taskId) {
  return ref.watch(taskRepositoryProvider).fetchSubmissions(taskId);
});

final assignableMembersProvider =
    FutureProvider.autoDispose<List<Profile>>((ref) {
  return ref.watch(taskRepositoryProvider).fetchMembers();
});
