import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AttendanceStatus {
  hadir,
  izin,
  sakit,
  alpha,
  pending;

  static AttendanceStatus fromString(String? v) => values.firstWhere(
        (e) => e.name == v,
        orElse: () => AttendanceStatus.pending,
      );

  String get label => switch (this) {
        AttendanceStatus.hadir => 'Hadir',
        AttendanceStatus.izin => 'Izin',
        AttendanceStatus.sakit => 'Sakit',
        AttendanceStatus.alpha => 'Alpha',
        AttendanceStatus.pending => 'Menunggu',
      };

  Color get color => switch (this) {
        AttendanceStatus.hadir => AppColors.success,
        AttendanceStatus.izin => AppColors.info,
        AttendanceStatus.sakit => AppColors.warning,
        AttendanceStatus.alpha => AppColors.danger,
        AttendanceStatus.pending => AppColors.textSecondary,
      };
}

class Attendance {
  const Attendance({
    required this.id,
    required this.activityId,
    required this.userId,
    required this.status,
    required this.method,
    this.userName,
    this.checkInTime,
    this.distanceM,
    this.isMocked = false,
  });

  final String id;
  final String activityId;
  final String userId;
  final String? userName;
  final AttendanceStatus status;
  final String method;
  final DateTime? checkInTime;
  final double? distanceM;
  final bool isMocked;

  factory Attendance.fromMap(Map<String, dynamic> m) {
    final prof = m['profiles'];
    return Attendance(
      id: m['id'] as String,
      activityId: m['activity_id'] as String,
      userId: m['user_id'] as String,
      userName: (prof is Map) ? prof['full_name'] as String? : null,
      status: AttendanceStatus.fromString(m['status'] as String?),
      method: (m['method'] as String?) ?? '-',
      checkInTime: m['check_in_time'] != null
          ? DateTime.parse(m['check_in_time'] as String).toLocal()
          : null,
      distanceM: (m['distance_m'] as num?)?.toDouble(),
      isMocked: (m['is_mocked'] as bool?) ?? false,
    );
  }
}

class AppLocation {
  const AppLocation({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusM,
    this.address,
  });

  final String id;
  final String name;
  final String? address;
  final double lat;
  final double lng;
  final int radiusM;

  factory AppLocation.fromMap(Map<String, dynamic> m) => AppLocation(
        id: m['id'] as String,
        name: m['name'] as String,
        address: m['address'] as String?,
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        radiusM: (m['radius_m'] as num?)?.toInt() ?? 100,
      );
}
