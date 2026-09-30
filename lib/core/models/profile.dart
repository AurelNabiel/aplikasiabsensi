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

enum Division {
  danceCover,
  kasei,
  manga;

  static Division? fromString(String? v) => switch (v) {
        'dance_cover' => Division.danceCover,
        'kasei' => Division.kasei,
        'manga' => Division.manga,
        _ => null,
      };

  String get value => switch (this) {
        Division.danceCover => 'dance_cover',
        Division.kasei => 'kasei',
        Division.manga => 'manga',
      };

  String get label => switch (this) {
        Division.danceCover => 'Dance Cover',
        Division.kasei => 'Kasei',
        Division.manga => 'Manga',
      };

  /// Path aset logo divisi.
  String get asset => switch (this) {
        Division.danceCover => 'assets/images/div_dance_cover.png',
        Division.kasei => 'assets/images/div_kasei.png',
        Division.manga => 'assets/images/div_manga.png',
      };
}

class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.role,
    this.division,
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
  final Division? division;

  /// Nama panggilan = kata pertama dari nama lengkap (untuk sapaan ringkas).
  String get callName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return (parts.isEmpty || parts.first.isEmpty) ? 'Pengguna' : parts.first;
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      fullName: (map['full_name'] as String?) ?? '',
      avatarUrl: map['avatar_url'] as String?,
      phone: map['phone'] as String?,
      jabatan: map['jabatan'] as String?,
      role: UserRole.fromString(map['role'] as String?),
      division: Division.fromString(map['division'] as String?),
    );
  }
}
