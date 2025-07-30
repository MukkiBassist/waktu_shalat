// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sholat/app/modules/prayer_times/controllers/prayer_times_controller.dart';
import 'package:sholat/app/utils/permission_helper.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'package:sholat/app/utils/notification_controller.dart';
import 'package:sholat/app/utils/notification_helper.dart';
import 'package:sholat/app/modules/home/bindings/home_binding.dart';
import 'package:sholat/app/theme/theme_controller.dart';
import 'package:timezone/timezone.dart' as tz;
import 'app/routes/app_pages.dart';

/// Inisialisasi timezone lokal berdasarkan perangkat
Future<void> setupTimeZone() async {
  tz.initializeTimeZones();
  final String timeZoneName = await AwesomeNotifications()
      .getLocalTimeZoneIdentifier();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(PrayerTimesController());

  // 1. Setup timezone dan lokal format
  await setupTimeZone();
  await initializeDateFormatting('id', null);

  // 2. Inisialisasi notifikasi dan listener
  await NotificationController.initialize();

  // 3. Pastikan izin diberikan
  await checkAllNotificationPermissions();
  if (!await AwesomeNotifications().isNotificationAllowed()) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  // 4. Jadwalkan notifikasi dummy harian (00:01)
  await scheduleDailyRescheduled();

  // 5. Safety: Jika aplikasi dibuka manual, jadwalkan ulang jika belum
  await handleRescheduleIfNeeded();

  // 6. Load Theme
  final themeController = Get.put(ThemeController());
  await themeController.loadTheme();

  // 7. Jalankan aplikasi

  // Inisialisasi alarm manager
  await AndroidAlarmManager.initialize();

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    //await dailyRescheduleCallback(); // safe check saat app dibuka
  });
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
        initialBinding: HomeBinding(),
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeController.isDarkMode.value
            ? ThemeMode.dark
            : ThemeMode.light,
      ),
    );
  }
}
