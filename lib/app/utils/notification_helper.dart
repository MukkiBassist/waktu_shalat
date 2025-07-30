// ignore_for_file: avoid_print

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:timezone/timezone.dart' as tz;
import 'package:sholat/app/modules/prayer_times/controllers/prayer_times_controller.dart';

/// ID notifikasi dummy jam 00:01
const int dummyNotificationId = 1001;

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
}

/// Jadwalkan dummy notifikasi setiap hari jam 00:01
Future<void> scheduleDailyRescheduler() async {
  final tzString = await AwesomeNotifications().getLocalTimeZoneIdentifier();

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: dummyNotificationId,
      channelKey: 'prayer_time_channel',
      title: 'Perbarui Jadwal Sholat',
      body: 'Memeriksa ulang jadwal sholat hari ini...',
      autoDismissible: true,
      displayOnBackground: true,
      displayOnForeground: false,
      payload: {'trigger': 'reschedule'},
    ),
    schedule: NotificationCalendar(
      hour: 0,
      minute: 1,
      second: 0,
      repeats: true,
      timeZone: tzString,
      preciseAlarm: true,
      allowWhileIdle: true,
    ),
  );
}

/// Hapus semua notifikasi sholat hari ini
Future<void> cancelTodayPrayerNotifications() async {
  final now = DateTime.now();
  final today = '${now.day}-${now.month}-${now.year}';
  final names = [
    'Subuh',
    'Terbit Matahari',
    'Dzuhur',
    'Ashar',
    'Maghrib',
    'Isya',
  ];

  for (var name in names) {
    final id = '$name-$today'.hashCode;
    await AwesomeNotifications().cancel(id);
    print('❌ Cancelled $name (ID: $id)');
  }
}

Future<void> handleRescheduleIfNeeded() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String todayKey = 'lastRescheduleDate';
  final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  if (prefs.getString(todayKey) == today) {
    print('[✅] Notifikasi sholat sudah dijadwalkan hari ini.');
    return;
  }

  final controller = Get.find<PrayerTimesController>();
  final prayerTimes = controller.prayerTimes;
  final notificationPrefs = controller.notificationPrefs;

  await schedulePrayerNotifications(prayerTimes, notificationPrefs);

  await prefs.setString(todayKey, today);
  print('[🔁] Notifikasi sholat berhasil dijadwalkan ulang.');
}

/// Jadwalkan notifikasi untuk semua waktu sholat
Future<void> schedulePrayerNotifications(
  List<PrayerTime> times,
  RxMap<String, bool> prefs,
) async {
  final now = DateTime.now();
  final tzString = await AwesomeNotifications().getLocalTimeZoneIdentifier();

  for (var p in times) {
    final scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      p.dateTime.hour,
      p.dateTime.minute,
    );
    final enabled = prefs[p.name] ?? true;

    if (scheduled.isAfter(now) && enabled) {
      final notifId = '${p.name}-${now.day}-${now.month}-${now.year}'.hashCode;

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notifId,
          channelKey: 'prayer_time_channel',
          title: 'Waktu ${p.name}',
          body: 'Saatnya ${p.name} - ${p.time}',
          autoDismissible: true,
          category: NotificationCategory.Reminder,
        ),
        schedule: NotificationCalendar(
          year: scheduled.year,
          month: scheduled.month,
          day: scheduled.day,
          hour: scheduled.hour,
          minute: scheduled.minute,
          second: 0,
          millisecond: 0,
          timeZone: tzString,
          repeats: false,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );

      print('✅ Scheduled ${p.name} at $scheduled (ID: $notifId)');
    } else {
      print('⚠️ Skipped ${p.name} - Lewat waktu atau dinonaktifkan');
    }
  }
}

Future<void> scheduleDailyRescheduled() async {
  const int dummyId = 999999;
  //final now = DateTime.now();
  //final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 1);

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: dummyId,
      channelKey: 'prayer_time_channel',
      title: 'Daily Scheduler',
      body: 'Auto-reschedule prayer notifications.',
      notificationLayout: NotificationLayout.Default,
      autoDismissible: true,
      locked: true,
      displayOnForeground: false,
      displayOnBackground: false,
      wakeUpScreen: false,
    ),
    schedule: NotificationCalendar(
      hour: 0,
      minute: 1,
      second: 0,
      repeats: true,
      allowWhileIdle: true,
      preciseAlarm: true,
    ),
  );
}
