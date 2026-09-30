import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:image_picker/image_picker.dart';

import '../../../core/models/profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/user_avatar.dart';
import '../auth/providers/auth_providers.dart';
import '../auth/providers/profile_provider.dart';
import 'edit_profile_page.dart';
import 'members_page.dart';

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
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Column(
                  children: [
                    _ProfileAvatar(profile: profile),
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
              _DivisionTile(division: profile.division),
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

class _ProfileAvatar extends ConsumerStatefulWidget {
  const _ProfileAvatar({required this.profile});
  final Profile profile;

  @override
  ConsumerState<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends ConsumerState<_ProfileAvatar> {
  bool _busy = false;

  Future<void> _change() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Ganti foto profil',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final x = await ImagePicker()
        .pickImage(source: source, maxWidth: 600, imageQuality: 80);
    if (x == null) return;

    setState(() => _busy = true);
    try {
      final bytes = await x.readAsBytes();
      final ext = x.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      await ref.read(profileRepositoryProvider).uploadAvatar(
            userId: widget.profile.id,
            bytes: bytes,
            ext: ext,
          );
      ref.invalidate(currentProfileProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gagal mengunggah foto'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        UserAvatar(
          name: widget.profile.fullName,
          url: widget.profile.avatarUrl,
          radius: 48,
        ),
        if (_busy)
          const Positioned.fill(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.black26,
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: _busy ? null : _change,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _DivisionTile extends StatelessWidget {
  const _DivisionTile({required this.division});
  final Division? division;

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
          if (division != null)
            DivisionLogo(asset: division!.asset, size: 22)
          else
            const Icon(Icons.groups_2_outlined,
                color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 14),
          const Text('Divisi',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(division?.label ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
