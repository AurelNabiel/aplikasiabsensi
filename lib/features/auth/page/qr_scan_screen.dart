import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/models/activity.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/attendance_providers.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key, required this.activity});
  final Activity activity;

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final _controller = MobileScannerController();
  bool _processing = false;
  String? _lastCode; // kode yang terakhir diproses (hindari pindai ganda)
  String? _result;
  bool _ok = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    // Jangan proses ulang kode yang sama (QR masih di depan kamera).
    if (code == _lastCode) return;

    setState(() {
      _processing = true;
      _lastCode = code;
    });

    try {
      final res = await ref.read(attendanceRepositoryProvider).checkinQr(
            activityId: widget.activity.id,
            token: code,
          );
      if (!mounted) return;
      setState(() {
        _ok = true;
        _result = res.already
            ? '${res.userName} sudah absen sebelumnya'
            : '${res.userName} ditandai HADIR';
      });
      ref.invalidate(attendancesProvider(widget.activity.id));
      // Sukses: tetap _processing=true sampai petugas tekan "Scan Berikutnya".
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ok = false;
        _result = '$e'.replaceFirst('Exception: ', '');
      });
      // Gagal: izinkan mencoba kode LAIN setelah jeda singkat.
      // (_lastCode dibiarkan agar QR gagal yang sama tak spam berulang.)
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _processing = false);
      });
    }
  }

  void _scanNext() {
    setState(() {
      _processing = false;
      _lastCode = null;
      _result = null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pindai QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _result == null
                      ? Colors.white
                      : (_ok ? AppColors.success : AppColors.danger),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Column(
              children: [
                if (_result != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _ok ? AppColors.success : AppColors.danger,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            _ok
                                ? Icons.check_circle_rounded
                                : Icons.error_rounded,
                            color: Colors.white,
                            size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(_result!,
                              style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                // Setelah sukses, tampilkan tombol lanjut; sebelumnya, petunjuk.
                if (_ok && _result != null)
                  ElevatedButton.icon(
                    onPressed: _scanNext,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Scan Berikutnya'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                    ),
                  )
                else
                  const Text('Arahkan ke QR anggota',
                      style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
