import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  String? get currentEmail => _client.auth.currentUser?.email;

  Future<void> updateOwnProfile({
    required String fullName,
    String? phone,
    String? jabatan,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw 'Belum login';
    await _client.from('profiles').update({
      'full_name': fullName,
      'phone': phone,
      'jabatan': jabatan,
    }).eq('id', uid);
  }

  Future<List<Profile>> fetchAllProfiles() async {
    final rows = await _client
        .from('profiles')
        .select()
        .order('full_name', ascending: true);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(Profile.fromMap)
        .toList();
  }

  /// Ubah role anggota. Aturan hierarki ditegakkan oleh trigger DB;
  /// pelanggaran akan melempar error yang bisa ditangkap di UI.
  Future<void> updateRole({
    required String userId,
    required UserRole role,
  }) async {
    await _client
        .from('profiles')
        .update({'role': role.name}).eq('id', userId);
  }
}
