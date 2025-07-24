import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Memeriksa dan meminta semua izin penting untuk notifikasi dan alarm
Future<void> checkAllNotificationPermissions() async {
  await _requestNotificationPermission();
  await _requestExactAlarmPermissionOnce();
}

/// Meminta izin notifikasi (hanya berlaku untuk Android 13+)
Future<void> _requestNotificationPermission() async {
  if (Platform.isAndroid && await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

/// Membuka pengaturan "Exact Alarm" sekali saja (Android 12+)
Future<void> _requestExactAlarmPermissionOnce() async {
  if (!Platform.isAndroid) return;

  final prefs = await SharedPreferences.getInstance();
  final alreadyOpened = prefs.getBool('alarmPermissionOpened') ?? false;

  if (!alreadyOpened) {
    await prefs.setBool('alarmPermissionOpened', true);
    await Future.delayed(const Duration(seconds: 3));

    const intent = AndroidIntent(
      action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );

    await intent.launch();
  }
}
