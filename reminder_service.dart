import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Jika menggunakan flutter_native_timezone untuk zona waktu yang lebih akurat:
import 'package:flutter_native_timezone/flutter_native_timezone.dart'; 
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// ReminderService (Local Scheduler)
/// Bertanggung jawab penuh untuk interaksi teknis dengan platform notifikasi.

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();

  factory ReminderService() => _instance;

  ReminderService._internal();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  
  /// Menginisialisasi timezone dan local notifications plugin
  Future<void> initialize({String? timezone}) async {
    if (_initialized) return;

    // 1. Inisialisasi Timezone
    tzdata.initializeTimeZones();
    try {
      final String localTimezone = timezone ?? await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone));
    } catch (e) {
      debugPrint('Gagal mendapatkan zona waktu: $e. Menggunakan tz.local.');
      tz.setLocalLocation(tz.local);
    }

    // 2. Pengaturan Notifikasi
    final androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse resp) {
        if (resp.payload != null) {
          debugPrint('Notifikasi diketuk dengan Payload: ${resp.payload}');
          // Tambahkan logika navigasi ke detail expense di sini
        }
      },
    );

    _initialized = true;
  }

  /// Menjadwalkan pengingat satu kali.
  /// uniqueNotificationKey harus berupa String unik (misalnya 'expenseId_memberId').
  Future<int> scheduleReminderForExpense(
    String uniqueNotificationKey, 
    DateTime scheduledAt, {
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // Menggunakan hash dari uniqueNotificationKey untuk ID notifikasi lokal yang unik.
    final int id = uniqueNotificationKey.hashCode & 0x7fffffff;

    final androidDetail = AndroidNotificationDetails(
      'expense_reminder_channel',
      'Pengingat Piutang',
      channelDescription: 'Channel khusus untuk pengingat pembayaran expense.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    final iosDetail = DarwinNotificationDetails();

    final details = NotificationDetails(android: androidDetail, iOS: iosDetail);

    final tzSchedule = tz.TZDateTime.from(scheduledAt, tz.local);

    // Jangan menjadwalkan jika waktu sudah lewat
    if (tzSchedule.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint('Peringatan: Gagal menjadwalkan karena waktu sudah lewat ($tzSchedule).');
      return -1; 
    }

    await _local.zonedSchedule(
      id,
      title,
      body,
      tzSchedule,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload ?? uniqueNotificationKey, 
    );
    // Simpan mapping key -> id agar bisa dibatalkan/diupdate nanti
    await _saveNotificationId(uniqueNotificationKey, id);

    debugPrint('Pengingat $uniqueNotificationKey berhasil dijadwalkan. ID: $id');
    return id;
  }

  /// Membatalkan pengingat berdasarkan kunci unik (expenseId_memberId)
  Future<void> cancelReminderForExpense(String uniqueNotificationKey) async {
    final int? storedId = await _getNotificationId(uniqueNotificationKey);
    if (storedId != null) {
      await _local.cancel(storedId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notif:$uniqueNotificationKey');
      debugPrint('Pengingat dengan kunci $uniqueNotificationKey dibatalkan (id: $storedId).');
      return;
    }

    // Fallback: cancel by hash id jika mapping tidak ditemukan
    final fallbackId = uniqueNotificationKey.hashCode & 0x7fffffff;
    await _local.cancel(fallbackId);
    debugPrint('Pengingat dengan kunci $uniqueNotificationKey dibatalkan (fallback id: $fallbackId).');
  }

  /// Cancel semua reminder lokal
  Future<void> cancelAllReminders() async {
    await _local.cancelAll();
  }

  /// Mendapatkan daftar pending scheduled notifications
  Future<List<PendingNotificationRequest>> getScheduledReminders() async {
    return await _local.pendingNotificationRequests();
  }

  // ---------------- helpers ----------------
  Future<void> _saveNotificationId(String key, int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notif:$key', id);
  }

  Future<int?> _getNotificationId(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('notif:$key');
  }
}