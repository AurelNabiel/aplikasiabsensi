import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

/// AppBar gradient seragam untuk seluruh halaman (judul & ikon putih,
/// sudut bawah membulat) — selaras dengan Home yang baru.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final ts = (Theme.of(context).appBarTheme.titleTextStyle ??
            const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))
        .copyWith(color: Colors.white);
    return AppBar(
      title: Text(title, style: ts),
      actions: actions,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        ),
      ),
    );
  }
}

enum NavTab { beranda, jadwal, absen, tugas, profil, none }

/// Bottom navigation floating & modern (latar transparan agar konten tembus
/// di belakangnya). Pakai `extendBody: true` pada Scaffold halaman.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key, required this.current});
  final NavTab current;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 18),
          child: child,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _item(context, NavTab.beranda, Icons.home_rounded, 'Beranda',
                  '/home'),
              _item(context, NavTab.jadwal, Icons.calendar_month_rounded,
                  'Jadwal', '/activities'),
              _center(context),
              _item(context, NavTab.tugas, Icons.checklist_rounded, 'Tugas',
                  '/tasks'),
              _item(context, NavTab.profil, Icons.person_rounded, 'Profil',
                  '/profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, NavTab tab, IconData icon, String label,
      String path) {
    final active = current == tab;
    final color = active ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: active ? null : () => context.go(path),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _center(BuildContext context) {
    final active = current == NavTab.absen;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: active ? null : () => context.go('/attendance'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.fingerprint_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(height: 2),
            const Text('Absen',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
