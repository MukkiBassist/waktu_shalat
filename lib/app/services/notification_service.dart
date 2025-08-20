// lib/app/services/notification_service.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sholat/app/services/prayer_cache_service.dart';
import 'package:sholat/app/utils/logger.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import '../helpers/notification_scheduler.dart';
import '../utils/notification_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int dummyNotificationId = 999999;
  static const String channelId = 'prayer_time_channel';
  static const String channelName = 'Jadwal Sholat';
  static const String channelDescription = 'Notifikasi waktu sholat harian';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Ensure timezone is already initialized from main
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) async {
        logInfo('Notification tapped id=${resp.id}, payload=${resp.payload}');
        // handle action payloads:
        // payload = 'refresh' -> refetch & reschedule
        if (resp.payload == 'refresh') {
          await PrayerCacheService().fetchAndCachePrayerTimes();
          await performReschedule();
        } else if (resp.payload == 'reschedule') {
          await performReschedule();
        } else if (resp.payload == 'close') {
          await _flutterLocalNotificationsPlugin.cancel(resp.id ?? 0);
        }
      },
    );

    // create channel
    const androidChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
    logSynced('✅ NotificationService initialized');
  }

  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    String? payload,
  }) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(dateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exact,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> performReschedule() async {
    try {
      logLoading('NotificationService.performReschedule start');
      // cancel previously scheduled notifications (we cancel all for simplicity)
      await _cancelAllPrayerNotifications();

      // Recompute using cached coords
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('last_lat');
      final lon = prefs.getDouble('last_lon');

      if (lat == null || lon == null) {
        logWarning('No cached coords available for reschedule');
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

      // read prefs for user notification prefs (this is used by scheduler)
      final stored = prefs.getString('prayerNotifPrefs');
      final Map<String, bool> userPrefs = stored != null
          ? Map<String, bool>.from(jsonDecode(stored))
          : {
              'Subuh': true,
              'Terbit Matahari': false,
              'Dzuhur': true,
              'Ashar': true,
              'Maghrib': true,
              'Isya': true,
            };

      // schedule via helper that uses NotificationService.schedulePrayerNotification
      await schedulePrayerNotificationsWithCatchup(
        newPrayerTimes
            .map(
              (e) => PrayerTime(id: e.id, name: e.name, dateTime: e.dateTime),
            )
            .toList(),
        userPrefs,
      );

      await markTodayAsScheduled();
      logSuccess('performReschedule done');
    } catch (e) {
      logError('❌ performReschedule failed: $e');
    }
  }

  Future<void> _cancelAllPrayerNotifications() async {
    final pending = await _flutterLocalNotificationsPlugin
        .pendingNotificationRequests();
    for (var p in pending) {
      await _flutterLocalNotificationsPlugin.cancel(p.id);
    }
    logInfo('All pending notifications cancelled');
  }
}
