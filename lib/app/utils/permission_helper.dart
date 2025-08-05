// ignore_for_file: avoid_print

import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Fungsi utama yang bisa dipanggil dari mana saja.
/// Memeriksa dan meminta semua izin penting untuk notifikasi & alarm.
Future<void> checkAllNotificationPermissions() async {
  await _requestNotificationPermission();
  await _requestExactAlarmPermissionOnce();
}

/// Meminta izin notifikasi (untuk Android 13 / SDK 33+)
Future<void> _requestNotificationPermission() async {
  if (Platform.isAndroid) {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }
}

/// Membuka pengaturan "Exact Alarm" hanya sekali saja saat pertama kali (Android 12 / SDK 31+)
Future<void> _requestExactAlarmPermissionOnce() async {
  if (!Platform.isAndroid) return;

  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  final sdkInt = androidInfo.version.sdkInt;

  if (sdkInt < 31) return;

  final prefs = await SharedPreferences.getInstance();
  final alreadyOpened = prefs.getBool('alarmPermissionOpened') ?? false;

  if (!alreadyOpened) {
    await Future.delayed(const Duration(seconds: 2)); // UX delay

    const intent = AndroidIntent(
      action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );

    try {
      await intent.launch();
      await prefs.setBool('alarmPermissionOpened', true);
      print('Membuka pengaturan Exact Alarm.');
    } catch (e) {
      print('Gagal membuka pengaturan Exact Alarm: $e');
    }
  }
}
