// lib/app/utils/notification_controller.dart

// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get_utils/src/platform/platform.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sholat/app/modules/prayer_times/controllers/prayer_times_controller.dart';
import 'package:sholat/app/utils/notification_helper.dart';

import '../helpers/notification_scheduler.dart';

class NotificationController {
  static const int dummyNotificationId = 999999;

  @pragma('vm:entry-point')
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'prayer_time_channel',
        channelName: 'Jadwal Sholat',
        channelDescription: 'Notifikasi waktu sholat harian',
        importance: NotificationImportance.High,
      ),
    ], debug: true);

    /*  AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    ); */
  }

  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    print(
      '🔔 Notifikasi diterima: ${receivedAction.channelKey} | ID: ${receivedAction.id}',
    );
    print(
      '===> [onActionReceivedMethod] DIPANGGIL: channel=${receivedAction.channelKey}, id=${receivedAction.id}',
    );

    if (receivedAction.id == dummyNotificationId &&
        receivedAction.channelKey == 'prayer_time_channel') {
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastScheduled = prefs.getString('last_scheduled_date');

      if (lastScheduled != today) {
        print('✅ Belum dijadwalkan hari ini ➜ menjadwalkan ulang...');
        await NotificationController.performReschedule();
      } else {
        print('⏭️ Sudah dijadwalkan hari ini ($today), skip reschedule.');
      }
    }
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification notif,
  ) async {
    print(
      '🔔 Notifikasi ditampilkan: id=${notif.id}, channel=${notif.channelKey}, title=${notif.title}',
    );

    if (notif.id == dummyNotificationId &&
        notif.channelKey == 'prayer_time_channel') {
      print('🕐 Dummy notification displayed ➜ Triggering reschedule check...');

      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastScheduled = prefs.getString('last_scheduled_date');

      if (lastScheduled != today) {
        print('✅ Belum dijadwalkan hari ini ➜ menjadwalkan ulang...');
        await NotificationController.performReschedule();
      } else {
        print('⏭️ Sudah dijadwalkan hari ini ($today), skip reschedule.');
      }
    }
  }

  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    print('Notification dismissed: ${receivedNotification.id}');
  }

  // PENTING: Pindahkan semua logika fetching & scheduling ke sini
  @pragma("vm:entry-point")
  static Future<void> performReschedule() async {
    try {
      await cancelAllPrayerNotifications();
      // 1. Dapatkan posisi saat ini secara mandiri

      // Tentukan pengaturan akurasi yang disesuaikan untuk Android atau platform lainnya.
      final LocationSettings locationSettings = (GetPlatform.isAndroid)
          ? AndroidSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 0,
              forceLocationManager: true,
              intervalDuration: const Duration(seconds: 10),
            )
          : AppleSettings(
              accuracy: LocationAccuracy.best,
              activityType: ActivityType.other,
              distanceFilter: 0,
              pauseLocationUpdatesAutomatically: true,
              showBackgroundLocationIndicator: false,
            );
      // Dapatkan posisi saat ini menggunakan settings baru
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      // 2. Hitung waktu sholat secara mandiri
      final prayerTimesResult = PrayerTimes(
        Coordinates(position.latitude, position.longitude),
        DateComponents.from(DateTime.now()),
        CalculationMethod.muslim_world_league.getParameters()
          ..madhab = Madhab.shafi,
      );

      // 3. Buat daftar waktu sholat
      final newPrayerTimes = [
        PrayerTime(id: 1, name: 'Subuh', dateTime: prayerTimesResult.fajr),
        PrayerTime(id: 2, name: 'Dzuhur', dateTime: prayerTimesResult.dhuhr),
        PrayerTime(id: 3, name: 'Ashar', dateTime: prayerTimesResult.asr),
        PrayerTime(id: 4, name: 'Maghrib', dateTime: prayerTimesResult.maghrib),
        PrayerTime(id: 5, name: 'Isya', dateTime: prayerTimesResult.isha),
      ];

      // 4. Dapatkan preferensi notifikasi secara mandiri dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedPrefs = prefs.getString('prayerNotifPrefs');
      final Map<String, bool> notificationPrefs = storedPrefs != null
          ? Map<String, bool>.from(jsonDecode(storedPrefs))
          : {
              'Subuh': true,
              'Terbit Matahari': false,
              'Dzuhur': true,
              'Ashar': true,
              'Maghrib': true,
              'Isya': true,
            };

      // 5. Panggil fungsi penjadwalan notifikasi dengan argumen yang lengkap
      await schedulePrayerNotificationsWithCatchup(
        newPrayerTimes,
        notificationPrefs,
      );
      await markTodayAsScheduled();

      print('✅ Penjadwalan ulang notifikasi berhasil.');
    } catch (e) {
      print('❌ Gagal menjadwalkan ulang: $e');
    }
  }
}

Future<void> cancelAllPrayerNotifications() async {
  // Membatalkan semua notifikasi dengan channel prayer_time_channel
  List<NotificationModel> scheduled = await AwesomeNotifications()
      .listScheduledNotifications();
  for (var notif in scheduled) {
    if (notif.content?.channelKey == 'prayer_time_channel') {
      await AwesomeNotifications().cancel(notif.content!.id!);
    }
  }
  print('🔄 Semua notifikasi jadwal sebelumnya telah dibatalkan.');
}
