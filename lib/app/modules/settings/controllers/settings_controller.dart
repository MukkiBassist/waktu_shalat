// lib/app/modules/settings/controllers/settings_controller.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sholat/app/utils/logger.dart';

import '../../prayer_times/controllers/prayer_times_controller.dart';

class SettingsController extends GetxController {
  static const _cacheDaysKey = 'prayer_cache_days';
  static const _alwaysCacheKey = 'prayer_always_cache';
  RxInt cacheDays = 7.obs; // Nilai default yang konsisten
  RxBool alwaysCache = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Muat jumlah hari cache dari SharedPreferences, default ke 7
    cacheDays.value = prefs.getInt(_cacheDaysKey) ?? 7;
    // Muat setting always cache
    alwaysCache.value = prefs.getBool(_alwaysCacheKey) ?? false;
    logSynced(
      'Settings loaded: cacheDays=${cacheDays.value}, alwaysCache=${alwaysCache.value}',
    );
  }

  Future<void> setCacheDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cacheDaysKey, days);
    cacheDays.value = days;

    logSuccess('Cache days updated to $days days.');

    // Memanggil PrayerTimesController untuk memperbarui data
    await Get.find<PrayerTimesController>().fetchAndSetPrayerTimes(
      forceRefresh: true,
    );

    Get.snackbar(
      "Berhasil",
      "Jumlah hari cache diubah menjadi $days",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
    Future.delayed(const Duration(seconds: 2), () {
      Get.back(); // Tutup dialog setelah 2 detik
      Get.back();
    });
  }

  Future<void> toggleAlwaysCache(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_alwaysCacheKey, value);
    alwaysCache.value = value;
    logSuccess('Always cache updated to $value.');
  }
}
