import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/profile.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_providers.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_screen.dart';
import 'members_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final email = ref.watch(profileRepositoryProvider).currentEmail;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Gagal memuat profil')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profil tidak ditemukan'));
          }
          final isAdmin = profile.role.isAtLeast(UserRole.admin);
          final initial =
              (profile.fullName.isNotEmpty ? profile.fullName[0] : '?')
                  .toUpperCase();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(initial,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      profile.fullName.isEmpty ? 'Tanpa nama' : profile.fullName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(profile.role.label,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _InfoTile(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  value: email ?? '-'),
              _InfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Telepon',
                  value: (profile.phone?.isNotEmpty ?? false)
                      ? profile.phone!
                      : '-'),
              _InfoTile(
                  icon: Icons.badge_outlined,
                  label: 'Jabatan',
                  value: (profile.jabatan?.isNotEmpty ?? false)
                      ? profile.jabatan!
                      : '-'),
              const SizedBox(height: 24),
              _MenuButton(
                icon: Icons.edit_rounded,
                label: 'Edit Profil',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => EditProfileScreen(profile: profile)),
                ),
              ),
              if (isAdmin)
                _MenuButton(
                  icon: Icons.groups_rounded,
                  label: 'Kelola Anggota',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MembersScreen()),
                  ),
                ),
              _MenuButton(
                icon: Icons.logout_rounded,
                label: 'Keluar',
                danger: true,
                onTap: () => ref.read(authRepositoryProvider).signOut(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 14),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.textPrimary;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
