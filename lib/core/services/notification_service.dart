import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/activity.dart';
import '../models/task.dart';
import '../utils/date_format.dart';

/// Notifikasi lokal (tanpa server/Firebase): menjadwalkan pengingat
/// kegiatan yang akan mulai & tugas yang mendekati deadline langsung di HP.
/// Pengingat dijadwalkan ulang setiap data terbaru dimuat (mis. di Home),
/// sehingga tetap muncul walau aplikasi ditutup untuk item yang sudah diketahui.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {}

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    await _requestPermission();
    _inited = true;
  }

  static Future<void> _requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    // Izin tampilkan notifikasi (Android 13+).
    await android?.requestNotificationsPermission();
    // Izin alarm tepat waktu (Android 12+). Tanpa ini, zonedSchedule exact
    // akan ditolak sistem dan notifikasi tidak muncul tepat waktu.
    await android?.requestExactAlarmsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Notifikasi langsung — untuk menguji apakah izin & channel sudah benar.
  static Future<void> showTestNow() async {
    await init();
    await _plugin.show(
      999,
      'Tes notifikasi',
      'Jika ini muncul, izin & channel sudah benar.',
      _details('kegiatan', 'Pengingat Kegiatan'),
    );
  }

  static NotificationDetails _details(String channelId, String channelName) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  static int _idFor(String prefix, String uuid) =>
      (prefix + uuid).hashCode & 0x7fffffff;

  static Future<void> _scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
  }) async {
    if (!when.isAfter(DateTime.now())) return; // lewat → lewati
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        _details(channelId, channelName),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // gagal menjadwalkan (mis. platform tak didukung) — abaikan.
    }
  }

  /// Jadwalkan ulang semua pengingat dari data terkini.
  /// Kegiatan: 60 menit sebelum mulai.
  /// Tugas belum dikerjakan: 24 jam & 1 jam sebelum deadline.
  static Future<void> syncReminders({
    required List<UpcomingActivity> activities,
    required List<TaskItem> tasks,
  }) async {
    await init();
    await _plugin.cancelAll();

    for (final a in activities) {
      await _scheduleAt(
        id: _idFor('act', a.id),
        when: a.startTime.subtract(const Duration(minutes: 60)),
        title: 'Kegiatan sebentar lagi',
        body: '${a.title} mulai ${formatJam(a.startTime)}',
        channelId: 'kegiatan',
        channelName: 'Pengingat Kegiatan',
      );
    }

    for (final t in tasks) {
      final dl = t.deadline;
      if (dl == null) continue;
      // Lewati yang sudah dikumpulkan / disetujui.
      if (t.mySubmission == SubmissionStatus.submitted ||
          t.mySubmission == SubmissionStatus.approved) {
        continue;
      }
      await _scheduleAt(
        id: _idFor('task24', t.id),
        when: dl.subtract(const Duration(hours: 24)),
        title: 'Deadline tugas besok',
        body: '${t.title} — deadline ${formatTanggalJam(dl)}',
        channelId: 'tugas',
        channelName: 'Pengingat Tugas',
      );
      await _scheduleAt(
        id: _idFor('task1', t.id),
        when: dl.subtract(const Duration(hours: 1)),
        title: 'Deadline tugas 1 jam lagi',
        body: '${t.title} — segera kumpulkan',
        channelId: 'tugas',
        channelName: 'Pengingat Tugas',
      );
    }
  }
}
