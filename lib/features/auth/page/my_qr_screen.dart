import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/attendance_providers.dart';

/// QR personal anggota yang berotasi (kedaluwarsa ~45 detik).
class MyQrScreen extends ConsumerStatefulWidget {
  const MyQrScreen({super.key});

  @override
  ConsumerState<MyQrScreen> createState() => _MyQrScreenState();
}

class _MyQrScreenState extends ConsumerState<MyQrScreen> {
  String? _token;
  String? _error;
  Timer? _timer;
  int _countdown = 40;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _countdown--);
      if (_countdown <= 0) _refresh();
    });
  }

  Future<void> _refresh() async {
    try {
      final token = await ref.read(attendanceRepositoryProvider).issueQrToken();
      if (!mounted) return;
      setState(() {
        _token = token;
        _error = null;
        _countdown = 40;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal membuat QR');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Saya')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _error != null
                    ? SizedBox(
                        width: 240,
                        height: 240,
                        child: Center(child: Text(_error!)),
                      )
                    : _token == null
                        ? const SizedBox(
                            width: 240,
                            height: 240,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : QrImageView(
                            data: _token!,
                            version: QrVersions.auto,
                            size: 240,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppColors.textPrimary,
                            ),
                          ),
              ),
              const SizedBox(height: 24),
              const Text('Tunjukkan ke petugas untuk dipindai',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text('Berganti dalam $_countdown detik',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Perbarui sekarang'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
