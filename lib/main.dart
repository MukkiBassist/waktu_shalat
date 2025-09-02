// lib/main.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sholat/app/initial_binding.dart';
import 'package:sholat/app/services/prayer_cache_service.dart';
import 'package:sholat/app/services/prayer_times_service.dart';
import 'package:sholat/app/utils/logger.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'package:sholat/app/utils/notification_controller.dart';
import 'package:sholat/app/modules/prayer_times/controllers/prayer_times_controller.dart';
import 'package:sholat/app/modules/settings/controllers/settings_controller.dart';
import 'package:sholat/app/theme/theme_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/services/location_service.dart';
import 'app/utils/permission_helper.dart';

const String workManagerTaskReschedule = 'reschedulePrayerNotifications';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    Get.put(PrayerCacheService());
    Get.put(PrayerTimesService());
    Get.put(LocationService());
    Get.put(SettingsController());
    Get.put(PrayerTimesController());
    Get.put(NotificationController());

    logInfo('⚙️ WorkManager: Starting daily task [$task] ...');
    final prayerTimesController = Get.find<PrayerTimesController>();
    await prayerTimesController.fetchAndSetPrayerTimes(forceRefresh: true);
    logSuccess('✅ Workmanager: Daily task completed successfully.');
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await checkAllPermissions();

  await initializeDateFormatting('id', null);
  tz.initializeTimeZones();
  try {
    tz.setLocalLocation(tz.getLocation(tz.local.name));
  } catch (e) {
    logError('Gagal mengatur timezone lokal: $e');
  }

  // ✅ Daftarkan ThemeController lebih awal
  final themeController = Get.put(ThemeController());
  await themeController.loadTheme();

  // ✅ Inisialisasi Workmanager (wajib await biar tidak balapan)
  await Workmanager().initialize(callbackDispatcher);

  // ✅ Pastikan tidak dobel: hapus dulu task lama, lalu daftarkan ulang
  await Workmanager().cancelByUniqueName(workManagerTaskReschedule);
  await Workmanager().registerPeriodicTask(
    workManagerTaskReschedule, // uniqueName
    workManagerTaskReschedule, // taskName
    frequency: const Duration(days: 1),
    initialDelay: _initialDelayToNextMidnight(),
    constraints: Constraints(networkType: NetworkType.notRequired),
  );

  runApp(const MyApp());
}

Duration _initialDelayToNextMidnight() {
  final now = DateTime.now();
  final nextMidnight = DateTime(
    now.year,
    now.month,
    now.day,
    0,
    1,
  ).add(const Duration(days: 1));
  final delay = nextMidnight.difference(now);
  logInfo(
    '⏰ Initial delay to next midnight (00:01): $nextMidnight. Delay: $delay',
  );
  return delay;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    // ✅ Gunakan Get.find() untuk ambil ThemeController
    final themeController = Get.find<ThemeController>();
    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sholat',
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
        initialBinding: InitialBinding(),
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeController.isDarkMode.value
            ? ThemeMode.dark
            : ThemeMode.light,
      ),
    );
  }
}
