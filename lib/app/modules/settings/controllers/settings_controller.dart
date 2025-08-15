// lib/app/modules/settings/controllers/settings_controller.dart
// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  static const _cacheDaysKey = 'prayer_cache_days';
  final cacheDays = 3.obs;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    cacheDays.value = prefs.getInt(_cacheDaysKey) ?? 3;
    print('Settings loaded: cacheDays=${cacheDays.value}');
  }

  Future<void> updateCacheDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cacheDaysKey, days);
    cacheDays.value = days;
    print('Settings updated: cacheDays=$days');
  }

  Future<int> getCacheDaysOrDefault() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_cacheDaysKey) ?? 3;
  }
}
