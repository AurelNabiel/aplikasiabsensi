import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/profile.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_providers.dart';
import '../providers/profile_provider.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(currentProfileProvider).asData?.value;
    final async = ref.watch(allProfilesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Anggota')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(allProfilesProvider),
            child: const Text('Gagal memuat. Coba lagi'),
          ),
        ),
        data: (profiles) {
          if (editor == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final editorIsSuper = editor.role == UserRole.superadmin;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allProfilesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: profiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final p = profiles[i];
                final isSelf = p.id == editor.id;
                final editable = !isSelf &&
                    (p.role != UserRole.superadmin || editorIsSuper);
                return _MemberTile(
                  profile: p,
                  isSelf: isSelf,
                  editable: editable,
                  onTap: editable
                      ? () => _changeRole(context, ref, p, editorIsSuper)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    Profile target,
    bool editorIsSuper,
  ) async {
    final options = editorIsSuper
        ? UserRole.values
        : [UserRole.anggota, UserRole.petugas, UserRole.admin];

    final chosen = await showModalBottomSheet<UserRole>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text('Ubah role — ${target.fullName}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final r in options)
              ListTile(
                leading: Icon(Icons.shield_outlined,
                    color: r == target.role
                        ? AppColors.primary
                        : AppColors.textSecondary),
                title: Text(r.label),
                trailing: r == target.role
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, r),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (chosen == null || chosen == target.role) return;

    try {
      await ref
          .read(profileRepositoryProvider)
          .updateRole(userId: target.id, role: chosen);
      ref.invalidate(allProfilesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Role ${target.fullName} → ${chosen.label}'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$e'.replaceFirst('Exception: ', '')),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.profile,
    required this.isSelf,
    required this.editable,
    required this.onTap,
  });

  final Profile profile;
  final bool isSelf;
  final bool editable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final initial =
        (profile.fullName.isNotEmpty ? profile.fullName[0] : '?').toUpperCase();
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Text(initial,
                  style: const TextStyle(color: AppColors.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                            profile.fullName.isEmpty
                                ? 'Tanpa nama'
                                : profile.fullName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      if (isSelf)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Text('(Anda)',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(profile.role.label,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (editable)
              const Icon(Icons.edit_rounded,
                  size: 18, color: AppColors.primary)
            else
              const Icon(Icons.lock_outline_rounded,
                  size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
