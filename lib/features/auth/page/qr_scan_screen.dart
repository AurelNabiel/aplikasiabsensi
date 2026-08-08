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
  String? _lastResult;
  bool _lastOk = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _processing = true);
    try {
      final att = await ref.read(attendanceRepositoryProvider).checkinQr(
            activityId: widget.activity.id,
            token: code,
          );
      final name = att.userName ?? 'Anggota';
      _showResult('$name ditandai HADIR', ok: true);
      ref.invalidate(attendancesProvider(widget.activity.id));
    } catch (e) {
      _showResult('$e'.replaceFirst('Exception: ', ''), ok: false);
    }
  }

  void _showResult(String msg, {required bool ok}) {
    if (!mounted) return;
    setState(() {
      _lastResult = msg;
      _lastOk = ok;
    });
    // Izinkan scan lagi setelah jeda singkat.
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _processing = false);
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
          // Bingkai pemindai
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
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
                if (_lastResult != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _lastOk ? AppColors.success : AppColors.danger,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            _lastOk
                                ? Icons.check_circle_rounded
                                : Icons.error_rounded,
                            color: Colors.white,
                            size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(_lastResult!,
                              style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
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
