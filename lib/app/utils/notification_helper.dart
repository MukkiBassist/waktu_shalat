// ignore_for_file: avoid_print

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:sholat/app/modules/prayer_times/controllers/prayer_times_controller.dart';

/// Menyimpan status apakah jadwal notifikasi hari ini sudah dijadwalkan
Future<void> setTodayScheduledStatus(bool status) async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateTime.now().toIso8601String().substring(0, 10);
  await prefs.setBool('scheduled_today_$today', status);
}

/// Mengecek apakah notifikasi hari ini sudah dijadwalkan
Future<bool> checkIfTodayScheduled() async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateTime.now().toIso8601String().substring(0, 10);
  return prefs.getBool('scheduled_today_$today') ?? false;
}

/// Menjadwalkan notifikasi dummy setiap 00:01 untuk menjadwalkan ulang notifikasi harian
Future<void> scheduleDailyRescheduled() async {
  final tzString = await AwesomeNotifications().getLocalTimeZoneIdentifier();
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 1001,
      channelKey: 'prayer_time_channel',
      title: 'Jadwal Sholat diperbarui',
      body: 'Memriksa ulang Jadwal Sholat hari ini...',
      notificationLayout: NotificationLayout.Default,
      displayOnForeground: false,
      displayOnBackground: true,
      autoDismissible: true,
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

/// Jika notifikasi belum dijadwalkan hari ini, maka lakukan penjadwalan
Future<void> handleRescheduleIfNeeded() async {
  bool alreadyScheduled = await checkIfTodayScheduled();
  if (!alreadyScheduled) {
    final controller = Get.find<PrayerTimesController>();

    // ⛑ Tambahan safety: Jika jadwal kosong, paksa ambil ulang
    if (controller.prayerTimes.isEmpty) {
      await controller.fetchPrayerTimes();
    }

    final prayers = controller.prayerTimes;
    final prefs = controller.notificationPrefs;

    await cancelTodayPrayerNotifications();
    await schedulePrayerNotifications(prayers, prefs);
    await setTodayScheduledStatus(true);
  }
}

/// Membatalkan notifikasi yang dijadwalkan untuk hari ini
Future<void> cancelTodayPrayerNotifications() async {
  final now = DateTime.now();
  final today = '${now.day}-${now.month}-${now.year}';

  final prayerNames = [
    'Subuh',
    'Terbit Matahari',
    'Dzuhur',
    'Ashar',
    'Maghrib',
    'Isya',
  ];

  for (var name in prayerNames) {
    final int id = '$name-$today'.hashCode;
    await AwesomeNotifications().cancel(id);
    print('Cancelled notification ID $id for $name on $today');
  }
}

/// Menjadwalkan notifikasi waktu sholat untuk hari ini
Future<void> schedulePrayerNotifications(
  List<PrayerTime> prayerTimes,
  RxMap<String, bool> notificationPrefs,
) async {
  print('NotificationHelper: Scheduling prayer notifications...');

  final String tzString = await AwesomeNotifications()
      .getLocalTimeZoneIdentifier();
  final now = DateTime.now();
  final buffer = Duration(minutes: 10); // 👈 Tambahan buffer 10 menit

  for (var p in prayerTimes) {
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      p.dateTime.hour,
      p.dateTime.minute,
      p.dateTime.second,
    );

    final bool isEnabled = notificationPrefs[p.name] ?? true;

    // 💡 Gunakan buffer agar Subuh tidak dilewatkan
    if (scheduledTime.isAfter(now.subtract(buffer)) && isEnabled) {
      final tz.TZDateTime scheduledTzTime = tz.TZDateTime(
        tz.local,
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        scheduledTime.hour,
        scheduledTime.minute,
        scheduledTime.second,
      );

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: '${p.name}-${scheduledTime.day}-${scheduledTime.month}-${scheduledTime.year}'
              .hashCode,
          channelKey: 'prayer_time_channel',
          title: 'Waktu ${p.name}',
          body: 'Saatnya ${p.name} - ${p.time}',
          notificationLayout: NotificationLayout.Default,
          autoDismissible: true,
          category: NotificationCategory.Reminder,
        ),
        schedule: NotificationCalendar(
          year: scheduledTime.year,
          month: scheduledTime.month,
          day: scheduledTime.day,
          hour: scheduledTime.hour,
          minute: scheduledTime.minute,
          second: 0,
          millisecond: 0,
          repeats: false,
          allowWhileIdle: true,
          preciseAlarm: true,
          timeZone: tzString,
        ),
      );

      print('✅ Scheduled ${p.name} notification for $scheduledTzTime');
    } else {
      print(
        '⚠️ Skipping ${p.name}. Already passed or disabled: $scheduledTime',
      );
    }
  }
}

//keterangan : ======================================================
//| Fungsi                             | Keterangan                                                                  |
//| ---------------------------------- | --------------------------------------------------------------------------- |
//| `setTodayScheduledStatus()`        | Menyimpan status sudah menjadwalkan notifikasi hari ini                     |
//| `checkIfTodayScheduled()`          | Mengecek apakah sudah dijadwalkan hari ini                                  |
//| `scheduleDailyRescheduled()`       | Notifikasi dummy jam 00:01 untuk trigger `handleRescheduleIfNeeded()`       |
//| `handleRescheduleIfNeeded()`       | Cek dan jadwalkan ulang hanya jika belum dilakukan hari ini                 |
//| `cancelTodayPrayerNotifications()` | Menghapus notifikasi hari ini saja berdasarkan ID hashCode unik per hari    |
//| `schedulePrayerNotifications()`    | Menjadwalkan notifikasi satu per satu hanya jika waktu valid dan diaktifkan |
