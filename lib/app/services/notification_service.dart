import 'package:awesome_notifications/awesome_notifications.dart';

/// Fungsi worker utama untuk menjadwalkan satu notifikasi sholat
Future<void> schedulePrayerNotification({
  required int id,
  required String title,
  required String body,
  required DateTime dateTime,
}) async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: id,
      channelKey: 'prayer_time_channel', // Diseragamkan
      title: title,
      body: body,
      notificationLayout: NotificationLayout.Default,
    ),
    schedule: NotificationCalendar.fromDate(date: dateTime, preciseAlarm: true),
  );
}
