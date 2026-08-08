/// Role user, selaras dengan enum `user_role` di database.
enum UserRole {
  superadmin,
  admin,
  petugas,
  anggota;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.anggota,
    );
  }

  /// Level hierarki (dipakai untuk cek kewenangan).
  int get level => switch (this) {
        UserRole.superadmin => 4,
        UserRole.admin => 3,
        UserRole.petugas => 2,
        UserRole.anggota => 1,
      };

  String get label => switch (this) {
        UserRole.superadmin => 'Super Admin',
        UserRole.admin => 'Admin',
        UserRole.petugas => 'Petugas',
        UserRole.anggota => 'Anggota',
      };

  bool isAtLeast(UserRole min) => level >= min.level;
}

class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.phone,
    this.jabatan,
  });

  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? phone;
  final String? jabatan;
  final UserRole role;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      fullName: (map['full_name'] as String?) ?? '',
      avatarUrl: map['avatar_url'] as String?,
      phone: map['phone'] as String?,
      jabatan: map['jabatan'] as String?,
      role: UserRole.fromString(map['role'] as String?),
    );
  }
}
