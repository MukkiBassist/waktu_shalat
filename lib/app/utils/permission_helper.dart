// lib/app/utils/permission_helper.dart
// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:sholat/app/utils/logger.dart';

Future<void> checkAllPermissions() async {
  logPermission('Memeriksa semua izin penting...');
  await Future.delayed(Duration(seconds: 1));
  logPermission('Meminta izin lokasi...');
  _requestLocationPermission();
  await Future.delayed(Duration(seconds: 2));
  logPermission('Meminta izin notifikasi...');
  _requestNotificationPermission();
  /* await Future.delayed(Duration(seconds: 3));
  requestExactAlarmPermissionOnce();
  print('✅ Semua izin penting telah diperiksa dan diminta.'); */
}

/// Meminta izin lokasi (digunakan oleh Geolocator)
Future<void> _requestLocationPermission() async {
  // Hanya untuk Android, iOS tidak perlu izin lokasi eksplisit
  if (!Platform.isAndroid) return;
  final status = await Permission.location.status;
  if (status.isDenied) {
    await Permission.location.request();
  }
}

/// Dialog untuk meminta izin notifikasi (Android 13 / SDK 33+)
Future<void> showMyDialog() async {
  return showDialog<void>(
    context: Get.context!,
    barrierColor: Colors.black54,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Buka Pengaturan Alarm'),
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                'Untuk mengaktifkan notifikasi waktu sholat, Anda perlu mengizinkan aplikasi ini untuk mengatur alarm secara tepat.',
              ),
              Text(
                'Buka pengaturan dan aktifkan "Exact Alarm" untuk aplikasi ini?',
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Ya'),
            onPressed: () async {
              Navigator.of(context).pop();

              const intent = AndroidIntent(
                action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
                flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
                package: 'com.natapradja.project.waktu_shalat',
              );

              try {
                await intent.launch();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('alarmPermissionOpened', true);
                logInfo('Pengaturan Exact Alarm dibuka.');
              } catch (e) {
                logError('Gagal membuka pengaturan Exact Alarm: $e');
              }
              //}
            },
          ),
          TextButton(
            child: const Text('Tidak'),
            onPressed: () {
              Navigator.of(context).pop();
              logWarning(
                'Pengguna memilih tidak membuka pengaturan Exact Alarm.',
              );
            },
          ),
        ],
      );
    },
  );
}

/// Meminta izin notifikasi (Android 13 / SDK 33+)
Future<void> _requestNotificationPermission() async {
  if (!Platform.isAndroid) return;
  final status = await Permission.notification.status;
  if (!status.isGranted) {
    final newStatus = await Permission.notification.request();
    if (!newStatus.isGranted) {
      logWarning('⚠️ Izin notifikasi ditolak.');
      //minta kembali
      await Permission.notification.request();
    }
  }
}

/// Membuka pengaturan "Exact Alarm" hanya sekali (Android 12 / SDK 31+)
Future<void> requestExactAlarmPermissionOnce() async {
  if (!Platform.isAndroid) return;
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  final sdkInt = androidInfo.version.sdkInt;

  if (sdkInt < 31) return;

  final prefs = await SharedPreferences.getInstance();
  final alreadyOpened = prefs.getBool('alarmPermissionOpened') ?? false;

  if (!alreadyOpened) {
    await showMyDialog();
  }
}
