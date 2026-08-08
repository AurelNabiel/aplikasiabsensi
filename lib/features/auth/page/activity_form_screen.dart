import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/activity.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../providers/activity_providers.dart';


class ActivityFormScreen extends ConsumerStatefulWidget {
  const ActivityFormScreen({super.key, this.activity});

  /// null = mode tambah, terisi = mode edit.
  final Activity? activity;

  @override
  ConsumerState<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends ConsumerState<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late DateTime _start;
  late DateTime _end;
  late ActivityMethod _method;
  bool _saving = false;

  bool get _isEdit => widget.activity != null;

  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    _title = TextEditingController(text: a?.title ?? '');
    _description = TextEditingController(text: a?.description ?? '');
    final now = DateTime.now();
    _start = a?.startTime ?? DateTime(now.year, now.month, now.day, 9, 0);
    _end = a?.endTime ?? _start.add(const Duration(hours: 1));
    _method = a?.method ?? ActivityMethod.any;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_end.isAfter(_start)) {
      _showError('Waktu selesai harus setelah waktu mulai');
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(activityRepositoryProvider);
      if (_isEdit) {
        await repo.updateActivity(
          widget.activity!.id,
          title: _title.text.trim(),
          description: _description.text.trim(),
          startTime: _start,
          endTime: _end,
          method: _method,
        );
      } else {
        await repo.createActivity(
          title: _title.text.trim(),
          description: _description.text.trim(),
          startTime: _start,
          endTime: _end,
          method: _method,
        );
      }
      ref.invalidate(activitiesProvider);
      if (mounted) context.pop();
    } catch (_) {
      _showError('Gagal menyimpan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Kegiatan' : 'Kegiatan Baru'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Judul kegiatan',
                    prefixIcon: Icon(Icons.event_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Judul wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (opsional)',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                _DateTimeTile(
                  label: 'Mulai',
                  value: _start,
                  onTap: () async {
                    final picked = await _pickDateTime(_start);
                    if (picked != null) {
                      setState(() {
                        _start = picked;
                        if (!_end.isAfter(_start)) {
                          _end = _start.add(const Duration(hours: 1));
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                _DateTimeTile(
                  label: 'Selesai',
                  value: _end,
                  onTap: () async {
                    final picked = await _pickDateTime(_end);
                    if (picked != null) setState(() => _end = picked);
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<ActivityMethod>(
                  initialValue: _method,
                  decoration: const InputDecoration(
                    labelText: 'Metode absensi',
                    prefixIcon: Icon(Icons.fingerprint_rounded),
                  ),
                  items: ActivityMethod.values
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.label),
                          ))
                      .toList(),
                  onChanged: (m) => setState(() => _method = m ?? _method),
                ),
                const SizedBox(height: 8),
              
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white),
                        )
                      : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded,
                color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(formatTanggalJam(value),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.edit_calendar_rounded,
                size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
