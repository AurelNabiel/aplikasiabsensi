import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/activity.dart';
import '../../../core/models/profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/geo.dart';
import '../providers/attendance_providers.dart';
import '../providers/auth_providers.dart';
import 'attendance_list_screen.dart';
import 'location_checkin_screen.dart';
import 'my_qr_screen.dart';
import 'qr_scan_screen.dart';

class ActivityAttendanceHubScreen extends ConsumerStatefulWidget {
  const ActivityAttendanceHubScreen({super.key, required this.activity});

  final Activity activity;

  @override
  ConsumerState<ActivityAttendanceHubScreen> createState() =>
      _ActivityAttendanceHubScreenState();
}

class _ActivityAttendanceHubScreenState
    extends ConsumerState<ActivityAttendanceHubScreen> {
  late String? _locationId = widget.activity.locationId;
  bool _settingLocation = false;

  bool get _hasLocation => _locationId != null;
  bool get _allowsLocation =>
      widget.activity.method == ActivityMethod.location ||
      widget.activity.method == ActivityMethod.any;
  bool get _allowsQr =>
      widget.activity.method == ActivityMethod.qr ||
      widget.activity.method == ActivityMethod.any;

  Future<void> _setLocationHere() async {
    setState(() => _settingLocation = true);
    try {
      final pos = await getCurrentLocation();
      final repo = ref.read(attendanceRepositoryProvider);
      final locId = await repo.createLocation(
        name: '${widget.activity.title} — Lokasi',
        lat: pos.lat,
        lng: pos.lng,
        radius: 100,
      );
      await repo.assignLocation(
        activityId: widget.activity.id,
        locationId: locId,
      );
      if (!mounted) return;
      setState(() => _locationId = locId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi ditetapkan (radius 100 m)'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _settingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).asData?.value;
    final isStaff = profile?.role.isAtLeast(UserRole.petugas) ?? false;
    final isAdmin = profile?.role.isAtLeast(UserRole.admin) ?? false;
    final a = widget.activity;

    return Scaffold(
      appBar: AppBar(title: const Text('Absensi Kegiatan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(a.title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.fingerprint_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Metode: ${a.method.label}',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(_hasLocation
                  ? Icons.location_on_rounded
                  : Icons.location_off_rounded,
                  size: 16,
                  color:
                      _hasLocation ? AppColors.success : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(_hasLocation ? 'Lokasi sudah diset' : 'Lokasi belum diset',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 24),

          // --- Aksi anggota (berlaku untuk semua role) ---
          _ActionTile(
            icon: Icons.qr_code_2_rounded,
            color: AppColors.primary,
            title: 'Tampilkan QR Saya',
            subtitle: 'Untuk dipindai petugas',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MyQrScreen(activityId: a.id)),
            ),
          ),
          if (_allowsLocation && _hasLocation)
            _ActionTile(
              icon: Icons.my_location_rounded,
              color: AppColors.accent,
              title: 'Check-in Lokasi',
              subtitle: 'Harus dalam radius 100 m',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LocationCheckinScreen(activity: a),
                ),
              ),
            ),

          // --- Aksi petugas / admin ---
          if (isStaff) ...[
            const Padding(
              padding: EdgeInsets.only(top: 20, bottom: 8),
              child: Text('Petugas',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
            if (_allowsQr)
              _ActionTile(
                icon: Icons.qr_code_scanner_rounded,
                color: AppColors.info,
                title: 'Pindai QR Anggota',
                subtitle: 'Tandai hadir dengan scan',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QrScanScreen(activity: a),
                  ),
                ),
              ),
            _ActionTile(
              icon: Icons.fact_check_rounded,
              color: AppColors.success,
              title: 'Kehadiran & Verifikasi',
              subtitle: 'Lihat, ubah status, absen manual',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendanceListScreen(activity: a),
                ),
              ),
            ),
          ],

          // --- Set lokasi (admin) ---
          if (isAdmin && _allowsLocation && !_hasLocation) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _settingLocation ? null : _setLocationHere,
              icon: _settingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_location_alt_rounded),
              label: Text(_settingLocation
                  ? 'Mengambil lokasi...'
                  : 'Tetapkan Lokasi (GPS saat ini)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
