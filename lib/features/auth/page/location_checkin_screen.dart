import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/activity.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/geo.dart';
import '../providers/attendance_providers.dart';

class LocationCheckinScreen extends ConsumerStatefulWidget {
  const LocationCheckinScreen({super.key, required this.activity});
  final Activity activity;

  @override
  ConsumerState<LocationCheckinScreen> createState() =>
      _LocationCheckinScreenState();
}

class _LocationCheckinScreenState
    extends ConsumerState<LocationCheckinScreen> {
  bool _loading = false;
  String? _message;
  bool _success = false;

  Future<void> _checkin() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final pos = await getCurrentLocation();
      final att = await ref.read(attendanceRepositoryProvider).checkinLocation(
            activityId: widget.activity.id,
            lat: pos.lat,
            lng: pos.lng,
            isMocked: pos.isMocked,
          );
      if (!mounted) return;
      final dist = att.distanceM?.round() ?? 0;
      setState(() {
        _success = true;
        _message = pos.isMocked
            ? 'Check-in tercatat, tapi lokasi terdeteksi palsu (mock). '
                'Menunggu verifikasi petugas.'
            : 'Check-in berhasil ($dist m dari titik). '
                'Menunggu verifikasi petugas.';
      });
      ref.invalidate(attendancesProvider(widget.activity.id));
    } catch (e) {
      if (mounted) {
        setState(() {
          _success = false;
          _message = '$e'.replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in Lokasi')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.my_location_rounded,
                    size: 48, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 24),
            Text(widget.activity.title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Pastikan kamu berada dalam radius 100 m dari lokasi kegiatan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            if (_message != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (_success ? AppColors.success : AppColors.danger)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                        _success
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color:
                            _success ? AppColors.success : AppColors.danger),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_message!)),
                  ],
                ),
              ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _loading ? null : _checkin,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white))
                  : const Icon(Icons.location_on_rounded),
              label: Text(_loading ? 'Mengambil lokasi...' : 'Check-in Sekarang'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
