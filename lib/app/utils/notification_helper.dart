// lib/app/utils/notification_helper.dart
// ignore_for_file: avoid_print

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sholat/app/utils/logger.dart';

/// Mengecek apakah jadwal notifikasi hari ini sudah diset
Future<bool> checkIfTodayScheduled() async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  return prefs.getString('last_scheduled_date') == today;
}

/// Menandai bahwa notifikasi hari ini sudah dijadwalkan
Future<void> markTodayAsScheduled() async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  await prefs.setString('last_scheduled_date', today);
  logSuccess('✅ markTodayAsScheduled -> $today');
}

/// Memaksa reset tanggal jadwal terakhir menjadi kemarin (untuk pengujian)
Future<void> forceResetLastScheduledToYesterday() async {
  final prefs = await SharedPreferences.getInstance();
  final yesterday = DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime.now().subtract(const Duration(days: 1)));
  await prefs.setString('last_scheduled_date', yesterday);
  logInfo('🔄 forceResetLastScheduledToYesterday -> $yesterday');
}
