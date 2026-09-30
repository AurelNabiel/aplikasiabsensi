import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/activity.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/geo.dart';
import '../auth/providers/attendance_providers.dart';

class LocationCheckinScreen extends ConsumerStatefulWidget {
  const LocationCheckinScreen({super.key, required this.activity});
  final Activity activity;

  @override
  ConsumerState<LocationCheckinScreen> createState() =>
      _LocationCheckinScreenState();
}

class _LocationCheckinScreenState
    extends ConsumerState<LocationCheckinScreen> {
  final _mapController = MapController();
  StreamSubscription<GeoResult>? _sub;
  GeoResult? _userPos;
  String? _locError;

  bool _loading = false;
  String? _message;
  bool _success = false;
  bool _followUser = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final first = await getCurrentLocation();
      if (!mounted) return;
      setState(() => _userPos = first);
      _moveTo(LatLng(first.lat, first.lng));
      _sub = watchLocation().listen((p) {
        if (!mounted) return;
        setState(() => _userPos = p);
        if (_followUser) _moveTo(LatLng(p.lat, p.lng));
      });
    } catch (e) {
      if (mounted) {
        setState(() => _locError = '$e'.replaceFirst('Exception: ', ''));
      }
    }
  }

  void _moveTo(LatLng target) {
    try {
      _mapController.move(target, _mapController.camera.zoom);
    } catch (_) {
      // controller belum siap (map belum dibangun) — abaikan.
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

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
        _userPos = pos;
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
    final locId = widget.activity.locationId;
    final targetAsync = locId == null
        ? const AsyncValue.data(null)
        : ref.watch(activityLocationProvider(locId));
    final target = targetAsync.asData?.value;

    // Titik tengah awal peta: lokasi target bila ada, jika tidak posisi user.
    final LatLng? center = target != null
        ? LatLng(target.lat, target.lng)
        : (_userPos != null ? LatLng(_userPos!.lat, _userPos!.lng) : null);

    double? dist;
    if (target != null && _userPos != null) {
      dist = distanceMeters(
          _userPos!.lat, _userPos!.lng, target.lat, target.lng);
    }
    final inside = (dist != null && target != null) ? dist <= target.radius : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in Lokasi')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (center == null)
                  const Center(child: CircularProgressIndicator())
                else
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 16,
                      onPositionChanged: (pos, hasGesture) {
                        if (hasGesture && _followUser) {
                          setState(() => _followUser = false);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.umalink.app',
                      ),
                      if (target != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: LatLng(target.lat, target.lng),
                              radius: target.radius.toDouble(),
                              useRadiusInMeter: true,
                              color: AppColors.primary.withOpacity(0.12),
                              borderColor: AppColors.primary,
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          if (target != null)
                            Marker(
                              point: LatLng(target.lat, target.lng),
                              width: 44,
                              height: 44,
                              child: const _TargetMarker(),
                            ),
                          if (_userPos != null)
                            Marker(
                              point:
                                  LatLng(_userPos!.lat, _userPos!.lng),
                              width: 28,
                              height: 28,
                              child: const _UserMarker(),
                            ),
                        ],
                      ),
                    ],
                  ),
                if (_locError != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    top: 16,
                    child: _InfoBanner(
                      color: AppColors.danger,
                      icon: Icons.location_off_rounded,
                      text: _locError!,
                    ),
                  ),
                // Tombol recenter ke posisi user.
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter',
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    onPressed: _userPos == null
                        ? null
                        : () {
                            setState(() => _followUser = true);
                            _moveTo(
                                LatLng(_userPos!.lat, _userPos!.lng));
                          },
                    child: const Icon(Icons.my_location_rounded),
                  ),
                ),
              ],
            ),
          ),
          _BottomPanel(
            title: widget.activity.title,
            target: target,
            distance: dist,
            inside: inside,
            message: _message,
            success: _success,
            loading: _loading,
            onCheckin: _checkin,
          ),
        ],
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.title,
    required this.target,
    required this.distance,
    required this.inside,
    required this.message,
    required this.success,
    required this.loading,
    required this.onCheckin,
  });

  final String title;
  final ActivityLocation? target;
  final double? distance;
  final bool? inside;
  final String? message;
  final bool success;
  final bool loading;
  final VoidCallback onCheckin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            target == null
                ? 'Lokasi kegiatan belum diatur.'
                : 'Radius ${target!.radius} m dari ${target!.name}.',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (distance != null && inside != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (inside! ? AppColors.success : AppColors.warning)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    inside!
                        ? Icons.check_circle_rounded
                        : Icons.directions_walk_rounded,
                    size: 16,
                    color:
                        inside! ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    inside!
                        ? 'Kamu di dalam radius (${distance!.round()} m)'
                        : '${distance!.round()} m dari titik — mendekatlah',
                    style: TextStyle(
                      color:
                          inside! ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (success ? AppColors.success : AppColors.danger)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                      success
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      color: success ? AppColors.success : AppColors.danger),
                  const SizedBox(width: 10),
                  Expanded(child: Text(message!)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: loading ? null : onCheckin,
              icon: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white))
                  : const Icon(Icons.location_on_rounded),
              label: Text(
                  loading ? 'Mengambil lokasi...' : 'Check-in Sekarang'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetMarker extends StatelessWidget {
  const _TargetMarker();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6),
        ],
      ),
      child: const Icon(Icons.flag_rounded, color: Colors.white, size: 22),
    );
  }
}

class _UserMarker extends StatelessWidget {
  const _UserMarker();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.color,
    required this.icon,
    required this.text,
  });
  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
