// lib/app/utils/notification_helper.dart

// ignore_for_file: avoid_print

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sholat/app/modules/prayer_times/controllers/prayer_times_controller.dart';

/// ID notifikasi dummy untuk trigger reschedule
const int dummyNotificationId = 999999;

/// Cek apakah hari ini sudah dijadwalkan
Future<bool> checkIfTodayScheduled() async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  return prefs.getString('last_scheduled_date') == today;
}

/// Tandai hari ini sudah dijadwalkan
Future<void> markTodayAsScheduled() async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  await prefs.setString('last_scheduled_date', today);
  print('✅ [NotificationHelper] Ditandai hari ini ($today) sudah dijadwalkan.');
}

/// Jadwalkan notifikasi dummy setiap hari jam 00:01
/// Ini akan memicu fungsi onActionReceivedMethod di NotificationController
Future<void> scheduleDailyRescheduler() async {
  final tzString = await AwesomeNotifications().getLocalTimeZoneIdentifier();
  final now = DateTime.now();

  var scheduledTime = DateTime(now.year, now.month, now.day, 0, 1, 0);

  if (scheduledTime.isBefore(now)) {
    scheduledTime = scheduledTime.add(const Duration(days: 1));
  }

  await AwesomeNotifications().cancel(dummyNotificationId);

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: dummyNotificationId,
      channelKey: 'prayer_time_channel',
      title: 'Auto-Reschedule Sholat',
      body: 'Notifikasi ini memicu pembaruan jadwal sholat harian.',
      notificationLayout: NotificationLayout.Default,
      autoDismissible: true,
      locked: true,
      payload: {'reschedule': 'true'},
    ),
    schedule: NotificationCalendar(
      year: scheduledTime.year,
      month: scheduledTime.month,
      day: scheduledTime.day,
      hour: scheduledTime.hour,
      minute: scheduledTime.minute,
      second: 0,
      repeats: false,
      allowWhileIdle: true,
      preciseAlarm: true,
      timeZone: tzString,
    ),
  );
  print(
    '✅ [NotificationHelper] Dummy rescheduler dijadwalkan pada: $scheduledTime.',
  );
}

/// Memastikan notifikasi sholat dijadwalkan jika aplikasi dibuka manual dan belum dijadwalkan
Future<void> handleRescheduleIfNeeded() async {
  print('🔎 [NotificationHelper] Memeriksa apakah perlu menjadwalkan ulang...');
  if (!await checkIfTodayScheduled()) {
    print(
      '⚠️ [NotificationHelper] Jadwal hari ini belum dibuat. Memicu penjadwalan ulang...',
    );
    try {
      final prayerTimesController = PrayerTimesController.instance;
      await prayerTimesController.fetchPrayerTimes();
      print('✅ [NotificationHelper] Penjadwalan ulang berhasil!');
    } catch (e) {
      print('❌ [NotificationHelper] Gagal menjadwalkan ulang: $e');
    }
  } else {
    print('✅ [NotificationHelper] Jadwal hari ini sudah dibuat.');
  }
}

/// Jadwalkan notifikasi untuk semua waktu sholat
Future<void> schedulePrayerNotifications(
  List<PrayerTime> times,
  RxMap<String, bool> prefs,
) async {
  print('🔄 [NotificationHelper] Memulai penjadwalan notifikasi sholat...');
  await AwesomeNotifications().cancelAll();
  final tzString = await AwesomeNotifications().getLocalTimeZoneIdentifier();

  for (var p in times) {
    final scheduledTime = p.dateTime;
    final enabled = prefs[p.name] ?? true;

    if (scheduledTime.isAfter(DateTime.now()) && enabled) {
      final notifId =
          '${p.name}-${scheduledTime.day}-${scheduledTime.month}-${scheduledTime.year}'
              .hashCode;

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notifId,
          channelKey: 'prayer_time_channel',
          title: 'Waktu ${p.name}',
          body: 'Saatnya ${p.name} - ${p.time}',
          autoDismissible: true,
          category: NotificationCategory.Alarm,
        ),
        schedule: NotificationCalendar(
          year: scheduledTime.year,
          month: scheduledTime.month,
          day: scheduledTime.day,
          hour: scheduledTime.hour,
          minute: scheduledTime.minute,
          second: 0,
          millisecond: 0,
          timeZone: tzString,
          repeats: false,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );

      print(
        '✅ [NotificationHelper] Dijadwalkan ${p.name} pada ${scheduledTime.toIso8601String()} (ID: $notifId)',
      );
    } else {
      print(
        '⚠️ [NotificationHelper] Dilewati ${p.name} - Sudah lewat waktu atau dinonaktifkan.',
      );
    }
  }
  await markTodayAsScheduled();
}
