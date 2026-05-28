// lib/app/services/prayer_cache_service.dart
// Hapus semua import yang tidak relevan (notification_service, settings_controller, prayer_times_service)

import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sholat/app/data/models/prayer_time.dart';
import 'package:sholat/app/utils/logger.dart';

import '../modules/settings/controllers/settings_controller.dart';

class PrayerCacheService {
  static const _cacheKey = 'prayer_times_cache';
  static const _expiryKey = 'prayer_times_expiry';

  Future<List<PrayerTime>> getPrayerTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cacheKey);
    if (jsonString == null) {
      logWarning('No prayer times found in cache.');
      return [];
    }
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => PrayerTime.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('Failed to load prayer times from cache: $e');
      return [];
    }
  }

  // Menghapus semua metode yang tidak relevan dan tidak digunakan

  Future<bool> isCacheExpired() async {
    final prefs = await SharedPreferences.getInstance();

    // Jika tidak ada data cache, maka dianggap expired (perlu fetch)
    if (!prefs.containsKey(_cacheKey)) {
      return true;
    }

    // Cek setting always cache
    try {
      if (Get.isRegistered<SettingsController>()) {
        final settingsController = Get.find<SettingsController>();
        if (settingsController.alwaysCache.value) {
          logSuccess('Always cache is enabled. Skipping expiry check.');
          return false;
        }
      }
    } catch (e) {
      logError('Error checking always cache setting: $e');
    }

    final expiryString = prefs.getString(_expiryKey);
    if (expiryString == null) return true;
    final expiryDate = DateTime.tryParse(expiryString);
    if (expiryDate == null) return true;
    return DateTime.now().isAfter(expiryDate);
  }

  /// Ambil dan cache jadwal sholat
  /// Sekarang hanya bertugas mengambil dan menyimpan ke cache
  /*  Future<void> loadPrayerTimesAndSavetoCache() async {
    // Di sini, Anda perlu memanggil service lain yang bertugas mengambil data.
    // Kode ini harus dipindahkan ke controller yang lebih tinggi.
    // Contoh:
    // final service = PrayerTimesService();
    // final items = await service.fetchPrayerTimesForDays(days);
    // await savePrayerTimes(items);
  } */

  /// Ambil jadwal sholat dari cache.
  /// Mengembalikan null jika tidak ada cache
  Future<List<Map<String, dynamic>>?> getCachedPrayerTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_cacheKey);
    if (json == null) return null;
    final List decoded = jsonDecode(json);
    logSuccess('Retrieved cached prayer times: ${decoded.length} entries');
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Menyimpan data jadwal sholat ke cache.
  Future<void> savePrayerTimes(List<PrayerTime> prayerTimes) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(prayerTimes.map((e) => e.toJson()).toList());
    await prefs.setString(_cacheKey, jsonString);

    // Ambil jumlah hari cache dari SettingsController
    final settingsController = Get.find<SettingsController>();
    final days = settingsController.cacheDays.value;

    final expiryDate = DateTime.now().add(Duration(days: days));
    await prefs.setString(_expiryKey, expiryDate.toIso8601String());
    logSuccess('Prayer times saved to cache until $expiryDate.');
  }
}
