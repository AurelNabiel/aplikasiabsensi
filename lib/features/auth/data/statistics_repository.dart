import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/stats.dart';

class StatisticsRepository {
  StatisticsRepository(this._client);

  final SupabaseClient _client;

  Future<StatsSummary> summary({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final res = await _client.rpc('stats_summary', params: {
      'p_user_id': userId,
      'p_from': from.toUtc().toIso8601String(),
      'p_to': to.toUtc().toIso8601String(),
    });
    final list = (res as List);
    if (list.isEmpty) return StatsSummary.empty;
    return StatsSummary.fromMap((list.first as Map).cast<String, dynamic>());
  }

  Future<List<StatsPoint>> series({
    required String userId,
    required DateTime from,
    required DateTime to,
    required String bucket,
  }) async {
    final res = await _client.rpc('stats_series', params: {
      'p_user_id': userId,
      'p_from': from.toUtc().toIso8601String(),
      'p_to': to.toUtc().toIso8601String(),
      'p_bucket': bucket,
    });
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(StatsPoint.fromMap)
        .toList();
  }

  /// Statistik ringkas untuk kartu di home (user saat ini).
  Future<DashboardStats> dashboard() async {
    final res = await _client.rpc('dashboard_stats');
    final list = (res as List);
    if (list.isEmpty) return DashboardStats.empty;
    return DashboardStats.fromMap((list.first as Map).cast<String, dynamic>());
  }
}