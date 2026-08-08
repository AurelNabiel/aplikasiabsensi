/// Metode absensi untuk sebuah kegiatan, selaras dengan enum
/// `activity_method` di database.
enum ActivityMethod {
  qr,
  location,
  manual,
  any;

  static ActivityMethod fromString(String? v) => values.firstWhere(
        (e) => e.name == v,
        orElse: () => ActivityMethod.any,
      );

  String get label => switch (this) {
        ActivityMethod.qr => 'QR Code',
        ActivityMethod.location => 'Lokasi (GPS)',
        ActivityMethod.manual => 'Manual (petugas)',
        ActivityMethod.any => 'Semua metode',
      };
}

class Activity {
  const Activity({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.method,
    required this.status,
    this.description,
    this.locationId,
    this.locationName,
  });

  final String id;
  final String title;
  final String? description;
  final String? locationId;
  final String? locationName;
  final DateTime startTime;
  final DateTime endTime;
  final ActivityMethod method;
  final String status;

  factory Activity.fromMap(Map<String, dynamic> map) {
    final loc = map['locations'];
    return Activity(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      locationId: map['location_id'] as String?,
      locationName: (loc is Map) ? loc['name'] as String? : null,
      startTime: DateTime.parse(map['start_time'] as String).toLocal(),
      endTime: DateTime.parse(map['end_time'] as String).toLocal(),
      method: ActivityMethod.fromString(map['method'] as String?),
      status: (map['status'] as String?) ?? 'scheduled',
    );
  }
}
