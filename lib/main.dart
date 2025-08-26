// lib/main.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sholat/app/services/prayer_cache_service.dart';
import 'package:sholat/app/utils/logger.dart';
//import 'package:sholat/app/utils/permission_helper.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'package:sholat/app/services/notification_service.dart';
import 'package:sholat/app/modules/prayer_times/controllers/prayer_times_controller.dart';
import 'package:sholat/app/modules/settings/controllers/settings_controller.dart';
import 'package:sholat/app/theme/theme_controller.dart';
import 'app/routes/app_pages.dart';
//import 'app/utils/permission_helper.dart';

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

    final cacheService = PrayerCacheService();
    final notificationService = NotificationService();

    // Inisialisasi service yang dibutuhkan di background
    await notificationService.initialize();

    try {
      logInfo('⚙️ WorkManager: Memulai tugas harian...');
      final isCacheExpired = await cacheService.isCacheExpired();

      if (isCacheExpired) {
        logWarning(
          'WorkManager: Cache kadaluarsa atau tidak ada. Memperbarui data dari jaringan...',
        );
        // Ambil data terbaru dari jaringan dan simpan ke cache
        await cacheService.loadPrayerTimesAndSavetoCache();
      } else {
        logSuccess(
          'WorkManager: Cache masih valid. Menggunakan data yang ada.',
        );
        // Tidak perlu melakukan apa-apa karena data di cache sudah cukup
      }

      // Jadwalkan ulang semua notifikasi berdasarkan data yang ada di cache
      await notificationService.performReschedule();

      logSuccess('WorkManager: Tugas harian berhasil diselesaikan.');
      return Future.value(true);
    } catch (e) {
      logError('WorkManager: Tugas gagal: $e');
      return Future.value(false);
    }
  });
}
/* @pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await setupTimeZone();

    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.performReschedule();

    return Future.value(true);
  });
} */

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
  // Cek izin setelah semua dependensi diinisialisasi
  //await checkAllPermissions();
  // Inisialisasi
  // Hapus semua task yang sudah terdaftar sebelumnya
  await Workmanager().cancelAll();
  await initDependencies();

  // Setup Workmanager untuk penjadwalan ulang harian
  await Workmanager().registerPeriodicTask(
    "daily_update_and_reschedule_task",
    "daily_prayer_update_reschedule",
    frequency: const Duration(days: 1),
    initialDelay: _initialDelayToNextMidnight(),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  runApp(const MyApp());
}

/// Hitung delay ke tengah malam berikutnya
Duration _initialDelayToNextMidnight() {
  final now = DateTime.now();
  // set ke tengah malam besok + 1 menit (00:01)
  final nextMidnight = DateTime(
    now.year,
    now.month,
    now.day,
    0,
    1,
  ).add(const Duration(days: 1));
  final delay = nextMidnight.difference(now);

  logInfo(
    'Initial delay to next midnight (00:01): $nextMidnight. Delay: $delay',
  );

  return delay;
}
/* Duration _initialDelayToNextMidnight() {
  final now = DateTime.now();
  final next = DateTime(
    now.year,
    now.month,
    now.day,
  ).add(const Duration(days: 1, minutes: 1));
  logInfo('Initial delay to next midnight: $next');
  return next.difference(now);
} */

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
