import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/activity.dart';

class ActivityRepository {
  ActivityRepository(this._client);

  final SupabaseClient _client;

  Future<List<Activity>> fetchActivities() async {
    final rows = await _client
        .from('activities')
        .select('*, locations(name)')
        .order('start_time', ascending: true);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(Activity.fromMap)
        .toList();
  }

  Future<void> createActivity({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    required ActivityMethod method,
  }) async {
    await _client.from('activities').insert({
      'title': title,
      'description': description,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'method': method.name,
      'created_by': _client.auth.currentUser?.id,
    });
  }

  Future<void> updateActivity(
    String id, {
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    required ActivityMethod method,
  }) async {
    await _client.from('activities').update({
      'title': title,
      'description': description,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'method': method.name,
    }).eq('id', id);
  }

  Future<void> deleteActivity(String id) async {
    await _client.from('activities').delete().eq('id', id);
  }
}
