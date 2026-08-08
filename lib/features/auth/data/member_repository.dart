import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/profile.dart';

class MemberRepository {
  MemberRepository(this._client);

  final SupabaseClient _client;

  /// Direktori anggota (view aman, tanpa email/telepon).
  Future<List<Profile>> fetchMembers() async {
    final rows = await _client
        .from('profiles')
        .select('id, full_name, role, jabatan, avatar_url') // tanpa phone/email
        .order('full_name', ascending: true);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(Profile.fromMap)
        .toList();
  }
}
