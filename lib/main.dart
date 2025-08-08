// main.dart (versi final aman)
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sholat/app/modules/prayer_times/controllers/prayer_times_controller.dart';
import 'package:sholat/app/theme/theme_controller.dart';
import 'package:sholat/app/utils/notification_controller.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'app/routes/app_pages.dart';

Future<void> setupTimeZone() async {
  tz.initializeTimeZones();
  final String timeZoneName = await AwesomeNotifications()
      .getLocalTimeZoneIdentifier();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
  print('TimeZone set to: $timeZoneName');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupTimeZone();
  await initializeDateFormatting('id', null);
  await AndroidAlarmManager.initialize();
  await Workmanager().initialize(callbackDispatcher);

  await Workmanager().registerPeriodicTask(
    "reschedulePrayerNotifications",
    "reschedulePrayerNotifications",
    frequency: const Duration(days: 1),
    initialDelay: getInitialDelayToNextMidnight(),
  );

  await AndroidAlarmManager.periodic(
    const Duration(hours: 24),
    1001,
    androidAlarmRescheduler,
    startAt: DateTime.now().add(getInitialDelayToNextMidnight()),
    exact: true,
    wakeup: true,
  );

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

  AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    onNotificationDisplayedMethod:
        NotificationController.onNotificationDisplayedMethod,
    onDismissActionReceivedMethod:
        NotificationController.onDismissActionReceivedMethod,
  );

  Get.put(PrayerTimesController());
  Get.put(ThemeController());
  await Get.find<ThemeController>().loadTheme();

  runApp(const MyApp());
}

void androidAlarmRescheduler() async {
  print(
    '===> AndroidAlarmManager trigger: Rescheduling prayer notifications (background)',
  );
  // Pastikan AwesomeNotifications & plugin diinisialisasi di isolate ini:
  await NotificationController.initialize();
  await NotificationController.performReschedule();
}

//callbackDispatcher untuk Workmanager:
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('===> Workmanager callback terpanggil: $task');
    await NotificationController.initialize();
    await NotificationController.performReschedule();
    return Future.value(true);
  });
}

Duration getInitialDelayToNextMidnight() {
  final now = DateTime.now();
  final next = DateTime(
    now.year,
    now.month,
    now.day,
  ).add(const Duration(days: 1, minutes: 5));
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
