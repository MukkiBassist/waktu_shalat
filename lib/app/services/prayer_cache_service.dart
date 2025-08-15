// lib/app/services/prayer_cache_service.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:sholat/app/services/prayer_times_service.dart';
import 'package:sholat/app/services/notification_service.dart';
import 'package:sholat/app/modules/settings/controllers/settings_controller.dart';
import 'package:sholat/app/utils/logger.dart';

class PrayerCacheService {
  static const _cacheKey = 'prayer_times_cache';
  static const _expiryKey = 'prayer_times_expiry';

  /// is cache expired or absent
  Future<bool> isCacheExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryString = prefs.getString(_expiryKey);
    if (expiryString == null) return true;
    final expiryDate = DateTime.tryParse(expiryString);
    if (expiryDate == null) return true;
    return DateTime.now().isAfter(expiryDate);
  }

  /// fetch via service and save. Also schedules notifications for all days fetched.
  Future<void> fetchAndCachePrayerTimes() async {
    final settings = Get.find<SettingsController>();
    final days = settings.cacheDays.value;

    // fetch times (uses Adhan inside)
    final service = PrayerTimesService();
    final items = await service.fetchPrayerTimesForDays(days);

    // convert to simple json list grouped per day
    final Map<String, Map<String, String>> perDay = {};
    for (var item in items) {
      final dayKey = DateTime(
        item.dateTime.year,
        item.dateTime.month,
        item.dateTime.day,
      ).toIso8601String();
      perDay.putIfAbsent(dayKey, () => {});
      perDay[dayKey]![item.name] = DateTime(
        item.dateTime.year,
        item.dateTime.month,
        item.dateTime.day,
        item.dateTime.hour,
        item.dateTime.minute,
      ).toIso8601String();
    }

    final listToSave = perDay.entries.map((e) {
      logInfo('Saving prayer time for ${e.key}: ${e.value}');
      return {'date': e.key, ...e.value};
    }).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(listToSave));
    final expiryDate = DateTime.now().add(Duration(days: days));
    await prefs.setString(_expiryKey, expiryDate.toIso8601String());

    // schedule notifications for all cached entries
    await _scheduleAllPrayerNotifications(listToSave);
    logSuccess('✅ Cached prayer times for $days days until $expiryDate');
  }

  Future<void> _scheduleAllPrayerNotifications(
    List<Map<String, dynamic>> prayerTimes,
  ) async {
    final notifService = NotificationService();
    int notifId = 1000;

    for (var dayData in prayerTimes) {
      final _ = DateTime.parse(dayData['date']);

      final entries = [
        {'name': 'Subuh', 'field': 'Subuh'},
        {'name': 'Dzuhur', 'field': 'Dzuhur'},
        {'name': 'Ashar', 'field': 'Ashar'},
        {'name': 'Maghrib', 'field': 'Maghrib'},
        {'name': 'Isya', 'field': 'Isya'},
      ];

      for (var entry in entries) {
        final iso = dayData[entry['field']];
        if (iso == null) continue;
        final dt = DateTime.parse(iso);
        if (dt.isBefore(DateTime.now())) continue;
        await notifService.schedulePrayerNotification(
          id: notifId++,
          title: 'Pengingat Sholat ${entry['name']}',
          body: 'Waktunya Sholat ${entry['name']}',
          dateTime: dt,
          payload: 'prayer_${entry['name']}',
        );
        logSuccess('Scheduled notification for ${entry['name']} at $dt');
      }
    }
  }

  // Get cached prayer times
  Future<List<Map<String, dynamic>>?> getCachedPrayerTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_cacheKey);
    if (json == null) return null;
    final List decoded = jsonDecode(json);
    logInfo('✅ Retrieved cached prayer times: ${decoded.length} entries');
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> setCacheDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('prayer_cache_days', days);
  }

  Future<int> getCacheDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('prayer_cache_days') ?? 3;
  }

  Future<void> savePrayerTimesToCache(
    // Save a list of prayer times to cache with expiry
    List<Map<String, dynamic>> prayerTimes,
    int days,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(prayerTimes));

    final expiryDate = DateTime.now().add(Duration(days: days));
    await prefs.setString(_expiryKey, expiryDate.toIso8601String());

    logSuccess('✅ Saved prayer times to cache with expiry: $expiryDate');
  }
}
