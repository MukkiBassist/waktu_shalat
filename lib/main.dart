// lib/main.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sholat/app/utils/logger.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'package:sholat/app/services/notification_service.dart';
import 'package:sholat/app/modules/prayer_times/controllers/prayer_times_controller.dart';
import 'package:sholat/app/modules/settings/controllers/settings_controller.dart';
import 'package:sholat/app/theme/theme_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/utils/permission_helper.dart';

const String workManagerTaskReschedule = 'reschedulePrayerNotifications';

/// Setup timezone agar sesuai lokasi perangkat
Future<void> setupTimeZone() async {
  tz.initializeTimeZones();
  try {
    tz.setLocalLocation(tz.getLocation(tz.local.name));
  } catch (_) {}
}

/// Callback untuk Workmanager (background task)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await setupTimeZone();

    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.performReschedule();

    return Future.value(true);
  });
}

// Fungsi inisialisasi terpusat
Future<void> initDependencies() async {
  // Inisialisasi service
  logInfo('Inisialisasi service...');
  await NotificationService().initialize();
  await setupTimeZone();
  await initializeDateFormatting('id', null);

  // Inisialisasi controller
  logInfo('Inisialisasi controller...');
  Get.put(SettingsController());
  await Get.find<SettingsController>().loadSettings();

  Get.put(PrayerTimesController());
  Get.put(ThemeController());
  await Get.find<ThemeController>().loadTheme();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(callbackDispatcher);

  // Inisialisasi
  await initDependencies();

  // Setup Workmanager untuk penjadwalan ulang harian
  await Workmanager().registerPeriodicTask(
    "reschedule_task_id",
    workManagerTaskReschedule,
    frequency: const Duration(days: 1),
    initialDelay: _initialDelayToNextMidnight(),
  );

  // Cek izin setelah semua dependensi diinisialisasi
  await checkAllPermissions();

  runApp(const MyApp());
}

/// Hitung delay ke tengah malam berikutnya
Duration _initialDelayToNextMidnight() {
  final now = DateTime.now();
  final next = DateTime(
    now.year,
    now.month,
    now.day,
  ).add(const Duration(days: 1, minutes: 1));
  logInfo('Initial delay to next midnight: $next');
  return next.difference(now);
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
