import 'package:flutter/material.dart';

/// Palet warna "cerah" untuk Hadirin.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF5B5FEF); // bright indigo
  static const Color primaryDark = Color(0xFF3F43D6);
  static const Color primaryLight = Color(0xFFE8E9FF);
  static const Color accent = Color(0xFF22D3EE); // cyan
  static const Color accentSoft = Color(0xFFCFF9FF);

  // Semantic
  static const Color success = Color(0xFF22C55E); // hadir
  static const Color warning = Color(0xFFF59E0B); // izin / pending
  static const Color danger = Color(0xFFEF4444); // alpha / ditolak
  static const Color info = Color(0xFF3B82F6);

  // Neutrals
  static const Color background = Color(0xFFF6F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B5FEF), Color(0xFF7C4DFF), Color(0xFF22D3EE)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF6D6FF6), Color(0xFF5B5FEF), Color(0xFF22D3EE)],
  );
}
