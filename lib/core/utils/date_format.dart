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

/// Waktu relatif ringkas Bahasa Indonesia untuk pengingat.
/// Contoh: "dalam 25 menit", "dalam 3 jam", "besok 09:00", "3 hari lagi".
String formatRelatif(DateTime dt) {
  final now = DateTime.now();
  final diff = dt.difference(now);
  if (diff.isNegative) return 'berlangsung';
  if (diff.inMinutes < 1) return 'sebentar lagi';
  if (diff.inMinutes < 60) return 'dalam ${diff.inMinutes} menit';
  if (diff.inHours < 24) return 'dalam ${diff.inHours} jam';
  if (diff.inDays == 1) return 'besok ${formatJam(dt)}';
  if (diff.inDays < 7) return '${diff.inDays} hari lagi';
  return formatTanggalJam(dt);
}

/// Hitung mundur live. Contoh: "02:15:30" (<24 jam) atau "3 hari 4 jam lagi".
String formatHitungMundur(Duration d) {
  if (d.isNegative || d.inSeconds == 0) return 'Dimulai';
  if (d.inDays >= 1) return '${d.inDays} hari ${d.inHours % 24} jam lagi';
  return '${_dua(d.inHours)}:${_dua(d.inMinutes % 60)}:${_dua(d.inSeconds % 60)}';
}
