import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/profile.dart';
import '../../../core/models/task.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/utils/date_format.dart';
import '../auth/providers/task_provider.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.task});

  /// null = tambah, terisi = edit.
  final TaskItem? task;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _startDate;
  DateTime? _deadline;
  final Set<Division> _divisions = {};
  final Set<String> _members = {}; // anggota tambahan (individual)
  bool _saving = false;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    if (t != null) {
      _title.text = t.title;
      _description.text = t.description ?? '';
      _priority = t.priority;
      _startDate = t.startDate;
      _deadline = t.deadline;
      _loadAssignees(t.id);
    }
  }

  Future<void> _loadAssignees(String taskId) async {
    try {
      final ids = await ref.read(taskRepositoryProvider).fetchAssigneeIds(taskId);
      if (mounted) setState(() => _members.addAll(ids));
    } catch (_) {}
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final base = initial ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Set<String> _resolveAssignees(List<Profile> all) {
    final ids = <String>{};
    for (final m in all) {
      if (m.division != null && _divisions.contains(m.division)) ids.add(m.id);
    }
    ids.addAll(_members);
    return ids;
  }

  Future<void> _save(List<Profile> all) async {
    if (!_formKey.currentState!.validate()) return;
    final assignees = _resolveAssignees(all);
    if (assignees.isEmpty) {
      _err('Pilih minimal satu divisi atau anggota');
      return;
    }
    if (_startDate != null &&
        _deadline != null &&
        !_deadline!.isAfter(_startDate!)) {
      _err('Deadline harus setelah waktu mulai');
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(taskRepositoryProvider);
      if (_isEdit) {
        await repo.updateTask(
          taskId: widget.task!.id,
          title: _title.text.trim(),
          description: _description.text.trim(),
          priority: _priority,
          startDate: _startDate,
          deadline: _deadline,
          assigneeIds: assignees.toList(),
        );
      } else {
        await repo.createTask(
          title: _title.text.trim(),
          description: _description.text.trim(),
          priority: _priority,
          startDate: _startDate,
          deadline: _deadline,
          assigneeIds: assignees.toList(),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      _err('Gagal menyimpan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _err(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(assignableMembersProvider);
    final members = membersAsync.asData?.value ?? const <Profile>[];

    // Hitung berapa anggota yang efektif menerima (untuk info).
    final effective = _resolveAssignees(members).length;

    return Scaffold(
      appBar: GradientAppBar(title: _isEdit ? 'Edit Tugas' : 'Tugas Baru'),
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
                    labelText: 'Judul tugas',
                    prefixIcon: Icon(Icons.title_rounded),
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
                const SizedBox(height: 14),
                DropdownButtonFormField<TaskPriority>(
                  value: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Prioritas',
                    prefixIcon: Icon(Icons.priority_high_rounded),
                  ),
                  items: TaskPriority.values
                      .map((p) =>
                          DropdownMenuItem(value: p, child: Text(p.label)))
                      .toList(),
                  onChanged: (p) => setState(() => _priority = p ?? _priority),
                ),
                const SizedBox(height: 18),
                _DateTile(
                  label: 'Mulai (opsional)',
                  value: _startDate,
                  onTap: () async {
                    final d = await _pickDateTime(_startDate);
                    if (d != null) setState(() => _startDate = d);
                  },
                  onClear: () => setState(() => _startDate = null),
                ),
                const SizedBox(height: 12),
                _DateTile(
                  label: 'Deadline (opsional)',
                  value: _deadline,
                  onTap: () async {
                    final d = await _pickDateTime(_deadline);
                    if (d != null) setState(() => _deadline = d);
                  },
                  onClear: () => setState(() => _deadline = null),
                ),
                const SizedBox(height: 22),
                const Text('Kirim ke Divisi',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final d in Division.values)
                      FilterChip(
                        avatar: DivisionLogo(asset: d.asset, size: 20),
                        label: Text(d.label),
                        selected: _divisions.contains(d),
                        onSelected: (sel) => setState(() {
                          if (sel) {
                            _divisions.add(d);
                          } else {
                            _divisions.remove(d);
                          }
                        }),
                        selectedColor: AppColors.primaryLight,
                        checkmarkColor: AppColors.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Anggota tambahan (opsional)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text(
                  'Semua anggota dari divisi terpilih otomatis menerima tugas.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 10),
                membersAsync.when(
                  loading: () => const Center(
                      child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  )),
                  error: (_, __) => const Text('Gagal memuat anggota'),
                  data: (list) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in list)
                        FilterChip(
                          label: Text(
                            m.division != null
                                ? '${m.fullName.isEmpty ? 'Tanpa nama' : m.fullName} · ${m.division!.label}'
                                : (m.fullName.isEmpty ? 'Tanpa nama' : m.fullName),
                          ),
                          selected: _members.contains(m.id) ||
                              (m.division != null &&
                                  _divisions.contains(m.division)),
                          onSelected: (sel) => setState(() {
                            if (sel) {
                              _members.add(m.id);
                            } else {
                              _members.remove(m.id);
                            }
                          }),
                          selectedColor: AppColors.primaryLight,
                          checkmarkColor: AppColors.primary,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (effective > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.group_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('$effective anggota akan menerima tugas ini',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saving ? null : () => _save(members),
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

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

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
            const Icon(Icons.event_rounded, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(value == null ? 'Belum diatur' : formatTanggalJam(value!),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (value != null)
              IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: onClear,
              )
            else
              const Icon(Icons.edit_calendar_rounded,
                  size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
