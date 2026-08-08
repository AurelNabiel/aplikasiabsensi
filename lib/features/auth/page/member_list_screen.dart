import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/profile.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/member_provider.dart';

class MemberListScreen extends ConsumerStatefulWidget {
  const MemberListScreen({super.key});

  @override
  ConsumerState<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends ConsumerState<MemberListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(membersDirectoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Anggota')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Cari anggota...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(membersDirectoryProvider),
                  child: const Text('Gagal memuat. Coba lagi'),
                ),
              ),
              data: (members) {
                final filtered = _query.isEmpty
                    ? members
                    : members
                        .where((m) =>
                            m.fullName.toLowerCase().contains(_query) ||
                            (m.jabatan ?? '').toLowerCase().contains(_query))
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada anggota',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(membersDirectoryProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _MemberTile(profile: filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final initial =
        (profile.fullName.isNotEmpty ? profile.fullName[0] : '?').toUpperCase();
    final name = profile.fullName.isEmpty ? 'Tanpa nama' : profile.fullName;
    final jabatan = (profile.jabatan?.isNotEmpty ?? false)
        ? profile.jabatan!
        : profile.role.label;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryLight,
            child: Text(initial,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(jabatan,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(profile.role.label,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
