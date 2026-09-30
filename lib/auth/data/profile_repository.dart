import 'dart:typed_data';

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

  /// Admin: ubah divisi anggota.
  Future<void> updateDivision({
    required String userId,
    required Division? division,
  }) async {
    await _client
        .from('profiles')
        .update({'division': division?.value}).eq('id', userId);
  }

  /// Upload foto profil ke Storage (bucket 'avatars', folder = uid),
  /// lalu simpan public URL (dengan cache-buster) ke profiles.avatar_url.
  Future<String> uploadAvatar({
    required String userId,
    required List<int> bytes,
    String ext = 'jpg',
  }) async {
    final path = '$userId/avatar.$ext';
    await _client.storage.from('avatars').uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(
            upsert: true,
            contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
          ),
        );
    final base = _client.storage.from('avatars').getPublicUrl(path);
    final url = '$base?t=${DateTime.now().millisecondsSinceEpoch}';
    await _client.from('profiles').update({'avatar_url': url}).eq('id', userId);
    return url;
  }
}
