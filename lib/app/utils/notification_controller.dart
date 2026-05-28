// lib/app/utils/notification_controller.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sholat/app/services/prayer_cache_service.dart';
import 'package:sholat/app/utils/logger.dart';
import '../data/models/prayer_time.dart';
import '../services/notification_service.dart';

class NotificationController {
  static final NotificationController _instance =
      NotificationController._internal();
  factory NotificationController() => _instance;
  NotificationController._internal();

  /// Dipanggil di main untuk set listener yang valid saat app hidup
  static Future<void> initialize() async {
    await NotificationService().initialize();
  }

  /// Membatalkan semua notifikasi sholat yang sudah terjadwal
  Future<void> cancelAllPrayerNotifications() async {
    await NotificationService().cancelAllNotifications();
  }

  /// Dipanggil baik di FG maupun di BG
  Future<void> performReschedule() async {
    try {
      logLoading('NotificationController.performReschedule start');

      // 1. Batalkan semua notifikasi lama
      await cancelAllPrayerNotifications();

      // 2. Ambil data sholat terbaru dari cache
      final prayerTimes = await PrayerCacheService().getPrayerTimes();

      if (prayerTimes.isEmpty) {
        logWarning('No prayer times found in cache for reschedule');
        return;
      }

      // 3. Ambil preferensi notifikasi pengguna dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('prayerNotifPrefs');
      final Map<String, bool> userPrefs = stored != null
          ? Map<String, bool>.from(jsonDecode(stored))
          : {
              'Subuh': true,
              'Terbit Matahari': false,
              'Dzuhur': true,
              'Ashar': true,
              'Maghrib': true,
              'Isya': true,
            };

      // 4. Jadwalkan notifikasi menggunakan helper
      await _schedulePrayerNotificationsWithCatchup(
        prayerTimes.cast<PrayerTime>(),
        userPrefs,
      );

      // 5. Tandai bahwa penjadwalan hari ini sudah selesai
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await prefs.setString('last_scheduled_date', today);

      logSuccess('performReschedule done');
    } catch (e) {
      logError('performReschedule failed: $e');
    }
  }

  /// Menampilkan notifikasi peringatan jika cache kosong dan gagal fetch
  Future<void> showCacheEmptyWarning() async {
    await NotificationService().showWarningNotification(
      id: 888, // ID statis untuk notifikasi peringatan ini
      title: 'Gagal Memuat Jadwal Sholat',
      body:
          'Data di cache kosong & gagal mengambil data baru. Cek koneksi internet & coba lagi.',
    );
  }

  /// Helper method untuk menjadwalkan notifikasi satu per satu
  Future<void> _schedulePrayerNotificationsWithCatchup(
    List<PrayerTime> prayerTimes,
    Map<String, bool> userPrefs,
  ) async {
    final now = DateTime.now();

    for (final prayer in prayerTimes) {
      // Pastikan notifikasi diaktifkan oleh pengguna dan waktunya belum terlewat
      if (userPrefs[prayer.name] != false && prayer.dateTime.isAfter(now)) {
        await NotificationService().schedulePrayerNotification(
          id: prayer.id,
          title: 'Waktu Sholat',
          body: 'Sudah masuk waktu ${prayer.name}',
          dateTime: prayer.dateTime,
        );
        logInfo('Scheduled ${prayer.name} at ${prayer.dateTime}');
      } else {
        logInfo(
          'Skipped ${prayer.name} notification (already passed or disabled)',
        );
      }
    }
  }
}
