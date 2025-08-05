// lib/app/helpers/preferences_helper.dart

import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, bool>> loadUserPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  final Map<String, bool> userPrefs = {
    'subuh': prefs.getBool('notif_subuh') ?? true,
    'dzuhur': prefs.getBool('notif_dzuhur') ?? true,
    'ashar': prefs.getBool('notif_ashar') ?? true,
    'maghrib': prefs.getBool('notif_maghrib') ?? true,
    'isya': prefs.getBool('notif_isya') ?? true,
  };
  return userPrefs;
}
