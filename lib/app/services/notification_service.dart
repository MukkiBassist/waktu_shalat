import 'package:awesome_notifications/awesome_notifications.dart';
import '../modules/prayer_times/controllers/prayer_times_controller.dart';

Future<void> scheduleNotification({
  required int id,
  required String title,
  required String body,
  required DateTime dateTime,
}) async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: id,
      channelKey: 'prayer_channel',
      title: title,
      body: body,
      notificationLayout: NotificationLayout.Default,
    ),
    schedule: NotificationCalendar.fromDate(date: dateTime, preciseAlarm: true),
  );
}

Future<void> schedulePrayerNotifications(
  List<PrayerTime> prayerTimes,
  Map<String, bool> userPrefs,
) async {
  for (var prayer in prayerTimes) {
    if (userPrefs[prayer.name] == true &&
        prayer.dateTime.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: prayer.id,
        title: 'Waktu Sholat ${prayer.name}',
        body: 'Sudah masuk waktu sholat ${prayer.name}.',
        dateTime: prayer.dateTime,
      );
    }
  }
}
