// lib/main.dart (VERSI FINAL)

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'package:sholat/app/utils/notification_controller.dart';
import 'package:sholat/app/modules/prayer_times/controllers/prayer_times_controller.dart';
import 'package:sholat/app/theme/theme_controller.dart';
import 'app/routes/app_pages.dart';

/// Inisialisasi timezone lokal berdasarkan perangkat
Future<void> setupTimeZone() async {
  tz.initializeTimeZones();
  final String timeZoneName = await AwesomeNotifications()
      .getLocalTimeZoneIdentifier();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
  print('TimeZone set to: $timeZoneName');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // HAPUS PANGGILAN INI DARI SINI
  // await checkAllNotificationPermissions();

  // 1. Inisialisasi framework dasar (cepat dan minimal)
  await setupTimeZone();
  await initializeDateFormatting('id', null);
  await AndroidAlarmManager.initialize();

  // 2. Inisialisasi AwesomeNotifications channel
  await AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelKey: 'prayer_time_channel',
      channelName: 'Prayer Notifications',
      channelDescription: 'Notification for daily prayer times',
      importance: NotificationImportance.Max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      channelShowBadge: true,
      defaultColor: const Color(0xFF2196f3),
      ledColor: const Color(0xFFFFFFFF),
      locked: true,
    ),
  ], debug: true);

  // 3. Pasang listener notifikasi
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    onNotificationDisplayedMethod:
        NotificationController.onNotificationDisplayedMethod,
    onDismissActionReceivedMethod:
        NotificationController.onDismissActionReceivedMethod,
  );

  // 4. Put Controller yang bersifat global dan permanen
  Get.put(PrayerTimesController());
  Get.put(ThemeController());
  await Get.find<ThemeController>().loadTheme();

  // 5. Jalankan aplikasi.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sholat',
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeController.isDarkMode.value
            ? ThemeMode.dark
            : ThemeMode.light,
      ),
    );
  }
}
