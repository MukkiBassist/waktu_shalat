import 'package:sholat/app/modules/prayer_times/controllers/prayer_times_controller.dart';
import 'package:sholat/app/services/notification_service.dart';

/// Fungsi utama untuk menjadwalkan notifikasi, termasuk catch-up
Future<void> schedulePrayerNotificationsWithCatchup(
  List<PrayerTime> newPrayerTimes,
  Map<String, bool> notificationPrefs,
) async {
  final controller = PrayerTimesController.instance;
  final prayerTimes = controller.prayerTimes;
  final userPrefs = controller.notificationPrefs;

  final now = DateTime.now();

  final List<PrayerTime> scheduled = [];

  for (var prayer in prayerTimes) {
    // Lewati 'Terbit Matahari' jika dimatikan
    if (prayer.name == 'Terbit Matahari') continue;

    final shouldNotify = userPrefs[prayer.name] ?? true;

    if (!shouldNotify) continue;

    // 1. Catch-up: Jadwalkan Isya kemarin jika sudah lewat tengah malam
    if (prayer.name == 'Isya' &&
        now.hour < 4 &&
        prayer.dateTime.isBefore(now)) {
      final isyaYesterday = PrayerTime(
        id: prayer.id,
        name: prayer.name,
        dateTime: prayer.dateTime,
      );
      scheduled.add(isyaYesterday);
    }

    // 2. Normal scheduling untuk yang belum lewat
    if (prayer.dateTime.isAfter(now)) {
      scheduled.add(prayer);
    }
  }

  // Eksekusi penjadwalan
  for (var p in scheduled) {
    await schedulePrayerNotification(
      id: p.id,
      title: 'Waktu Sholat ${p.name}',
      body: 'Sudah masuk waktu sholat ${p.name}.',
      dateTime: p.dateTime,
    );
  }
}
