class SupabaseConfig {
  SupabaseConfig._();

  /// Diisi saat build lewat --dart-define / --dart-define-from-file.
  /// TIDAK di-hardcode di source (aman untuk di-commit).
  ///   flutter run   --dart-define-from-file=dart_define.json
  ///   flutter build apk --release --dart-define-from-file=dart_define.json
  static const String url =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String anonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// True bila kredensial sudah terisi saat build.
  static bool get isValid => url.isNotEmpty && anonKey.isNotEmpty;
}
