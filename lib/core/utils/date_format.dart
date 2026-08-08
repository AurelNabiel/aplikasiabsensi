/// Format tanggal sederhana Bahasa Indonesia tanpa perlu init locale intl.
const _hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];

String _dua(int n) => n.toString().padLeft(2, '0');

/// Contoh: "Sen, 12 Agu 2026 • 09:00"
String formatTanggalJam(DateTime dt) {
  final h = _hari[(dt.weekday - 1) % 7];
  final b = _bulan[dt.month - 1];
  return '$h, ${dt.day} $b ${dt.year} • ${_dua(dt.hour)}:${_dua(dt.minute)}';
}

/// Contoh: "12 Agu 2026"
String formatTanggal(DateTime dt) =>
    '${dt.day} ${_bulan[dt.month - 1]} ${dt.year}';

/// Contoh: "09:00"
String formatJam(DateTime dt) => '${_dua(dt.hour)}:${_dua(dt.minute)}';
