// lib/app/utils/notification_controller.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sholat/app/utils/logger.dart';
import '../services/notification_service.dart';
import '../helpers/notification_scheduler.dart';

class NotificationController {
  static const int dummyNotificationId = 999999;

  /// Dipanggil di main untuk set listener yang valid saat app hidup
  static Future<void> initialize() async {
    await NotificationService().initialize();
  }

  /// Dipanggil baik di FG maupun di BG
  @pragma('vm:entry-point')
  static Future<void> performReschedule({bool background = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final lat = prefs.getDouble('last_lat');
      final lon = prefs.getDouble('last_lon');

      if (lat == null || lon == null) {
        logWarning(
          'performReschedule: no cached location available, skipping. (background=$background)',
        );
        return;
      }

      final prayerTimesResult = PrayerTimes(
        Coordinates(lat, lon),
        DateComponents.from(DateTime.now()),
        CalculationMethod.muslim_world_league.getParameters()
          ..madhab = Madhab.shafi,
      );

      final newPrayerTimes = [
        PrayerTime(id: 1, name: 'Subuh', dateTime: prayerTimesResult.fajr),
        PrayerTime(id: 2, name: 'Dzuhur', dateTime: prayerTimesResult.dhuhr),
        PrayerTime(id: 3, name: 'Ashar', dateTime: prayerTimesResult.asr),
        PrayerTime(id: 4, name: 'Maghrib', dateTime: prayerTimesResult.maghrib),
        PrayerTime(id: 5, name: 'Isya', dateTime: prayerTimesResult.isha),
      ];

      final stored = prefs.getString('prayerNotifPrefs');
      final Map<String, bool> notificationPrefs = stored != null
          ? Map<String, bool>.from(jsonDecode(stored))
          : {
              'Subuh': true,
              'Terbit Matahari': false,
              'Dzuhur': true,
              'Ashar': true,
              'Maghrib': true,
              'Isya': true,
            };

      await cancelAllPrayerNotifications();

      await schedulePrayerNotificationsWithCatchup(
        newPrayerTimes,
        notificationPrefs,
      );

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await prefs.setString('last_scheduled_date', today);

      logSuccess('performReschedule done (background=$background)');
    } catch (e) {
      logError('performReschedule failed: $e');
    }
  }
}

Future<void> cancelAllPrayerNotifications() async {
  final plugin = FlutterLocalNotificationsPlugin();
  final pending = await plugin.pendingNotificationRequests();
  for (var notif in pending) {
    if (notif.id != NotificationController.dummyNotificationId) {
      await plugin.cancel(notif.id);
    }
  }
  print('🔄 All old prayer notifications cancelled');
}
