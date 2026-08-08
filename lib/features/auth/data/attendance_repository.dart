import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/attendance.dart';
import '../../../core/models/profile.dart';
import '../providers/auth_providers.dart';

class AttendanceRepository {
  AttendanceRepository(this._client);

  final SupabaseClient _client;

  Map<String, dynamic> _row(dynamic res) {
    if (res is List) return (res.first as Map).cast<String, dynamic>();
    return (res as Map).cast<String, dynamic>();
  }

  /// Anggota: terbitkan token QR personal (berotasi, kedaluwarsa cepat).
  Future<String> issueQrToken() async {
    final res = await _client.rpc('issue_qr_token');
    return res as String;
  }

  /// Petugas: pindai QR anggota untuk kegiatan.
  /// Mengembalikan nama anggota + apakah dia SUDAH hadir sebelumnya.
  Future<({String userName, bool already})> checkinQr({
    required String activityId,
    required String token,
  }) async {
    final res = await _client.rpc('checkin_qr', params: {
      'p_activity_id': activityId,
      'p_token': token,
    });
    final row = _row(res);
    final name = (row['member_name'] as String?) ?? '';
    final already = (row['already'] as bool?) ?? false;
    return (userName: name.isEmpty ? 'Anggota' : name, already: already);
  }

  /// Anggota: check-in GPS. Validasi radius dilakukan di server.
  Future<Attendance> checkinLocation({
    required String activityId,
    required double lat,
    required double lng,
    required bool isMocked,
  }) async {
    final res = await _client.rpc('checkin_location', params: {
      'p_activity_id': activityId,
      'p_lat': lat,
      'p_lng': lng,
      'p_is_mocked': isMocked,
    });
    return Attendance.fromMap(_row(res));
  }

  /// Petugas: ubah / verifikasi status kehadiran.
  Future<void> verifyAttendance({
    required String attendanceId,
    required AttendanceStatus status,
  }) async {
    await _client.rpc('verify_attendance', params: {
      'p_attendance_id': attendanceId,
      'p_status': status.name,
    });
  }

  /// Petugas: tandai kehadiran manual.
  Future<void> markManual({
    required String activityId,
    required String userId,
    required AttendanceStatus status,
  }) async {
    await _client.rpc('mark_attendance_manual', params: {
      'p_activity_id': activityId,
      'p_user_id': userId,
      'p_status': status.name,
    });
  }

  /// Daftar kehadiran satu kegiatan (dengan nama anggota).
  Future<List<Attendance>> fetchAttendances(String activityId) async {
    final rows = await _client
        .from('attendances')
        .select('*, profiles!user_id(full_name)')
        .eq('activity_id', activityId)
        .order('check_in_time', ascending: false);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(Attendance.fromMap)
        .toList();
  }

  /// Semua anggota (untuk pemilihan absen manual).
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

  /// Admin: buat lokasi baru dari koordinat, kembalikan id-nya.
  Future<String> createLocation({
    required String name,
    String? address,
    required double lat,
    required double lng,
    int radius = 100,
  }) async {
    final res = await _client.rpc('create_location', params: {
      'p_name': name,
      'p_address': address,
      'p_lat': lat,
      'p_lng': lng,
      'p_radius': radius,
    });
    return res as String;
  }

  /// Admin: tautkan lokasi ke kegiatan.
  Future<void> assignLocation({
    required String activityId,
    required String locationId,
  }) async {
    await _client
        .from('activities')
        .update({'location_id': locationId}).eq('id', activityId);
  }

  final attendanceRealtimeProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, activityId) {
  final client = ref.watch(supabaseClientProvider);
  return client
      .from('attendances')
      .stream(primaryKey: ['id'])
      .eq('activity_id', activityId);
});

  /// Roster: semua anggota + status kehadirannya untuk kegiatan.
  Future<List<RosterEntry>> fetchRoster(String activityId) async {
    final res = await _client
        .rpc('activity_roster', params: {'p_activity_id': activityId});
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(RosterEntry.fromMap)
        .toList();
  }
}
