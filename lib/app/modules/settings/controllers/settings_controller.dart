// lib/app/modules/settings/controllers/settings_controller.dart
// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sholat/app/utils/logger.dart';

class SettingsController extends GetxController {
  static const _cacheDaysKey = 'prayer_cache_days';
  final cacheDays = 7.obs;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Load cache days from SharedPreferences, default to 3 if not set
    cacheDays.value = prefs.getInt(_cacheDaysKey) ?? 7;
    logSynced('Settings loaded: cacheDays=${cacheDays.value}');
  }

  Future<void> updateCacheDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cacheDaysKey, days);
    cacheDays.value = days;
    logSuccess('Settings updated: cacheDays=$days');
  }

  Future<int> getCacheDaysOrDefault() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_cacheDaysKey) ?? 3;
  }
}
