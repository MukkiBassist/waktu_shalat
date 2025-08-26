// lib/app/utils/permission_helper.dart
// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:device_info_plus/device_info_plus.dart';
import 'package:sholat/app/utils/logger.dart';

/// Memeriksa dan meminta semua izin penting.
/// Gunakan satu fungsi ini di awal aplikasi, misalnya di `onReady` SplashController.
Future<void> checkAllPermissions() async {
  logPermission('Memeriksa semua izin penting...');

  // Periksa dan minta izin lokasi
  logPermission('Meminta izin lokasi...');
  await _requestLocationPermission();

  // Periksa dan minta izin notifikasi
  logPermission('Meminta izin notifikasi...');
  await _requestNotificationPermission();

  // Periksa dan minta izin Exact Alarm
  //logPermission('Memeriksa dan meminta izin Exact Alarm...');
  //await _requestExactAlarmPermission();
}

/// Meminta izin lokasi (digunakan oleh Geolocator)
Future<void> _requestLocationPermission() async {
  if (!Platform.isAndroid) return;

  // Minta izin lokasi
  var status = await Permission.location.request();

  if (status.isGranted) {
    logSuccess("User memberikan izin lokasi");
    // lanjut akses lokasi
  } else if (status.isDenied) {
    logError("User menolak izin lokasi");
    // mungkin tampilkan dialog edukasi kenapa izin dibutuhkan
  } else if (status.isPermanentlyDenied) {
    logWarning("User blokir izin lokasi secara permanen 🚫");
    // arahkan ke settings
    openAppSettings();
  }
}

/// Meminta izin notifikasi (Android 13 / SDK 33+)
Future<void> _requestNotificationPermission() async {
  if (!Platform.isAndroid) return;
  final notif = await Permission.notification.request();
  if (!notif.isGranted) {
    logWarning('Izin notifikasi ditolak.');
  } else if (notif.isDenied) {
    logError("User menolak izin notifikasi");
    // mungkin tampilkan dialog edukasi kenapa izin dibutuhkan
  } else if (notif.isPermanentlyDenied) {
    logWarning("User blokir izin notifikasi secara permanen 🚫");
    // arahkan ke settings
    openAppSettings();
  }
}

/// Memeriksa dan meminta izin "Exact Alarm" (Android 12 / SDK 31+)
/* Future<void> _requestExactAlarmPermission() async {
  if (!Platform.isAndroid) return;

  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  final sdkInt = androidInfo.version.sdkInt;

  // Lewati jika versi Android < 12
  if (sdkInt < 31) return;

  // Menggunakan permission_handler untuk memeriksa status izin
  final status = await Permission.scheduleExactAlarm.status;

  // Jika izin ditolak, tampilkan dialog
  if (status.isDenied) {
    logWarning('Izin Exact Alarm ditolak.');

    // Periksa apakah dialog sudah pernah ditampilkan sebelumnya
    final prefs = await SharedPreferences.getInstance();
    final alreadyOpened = prefs.getBool('alarmPermissionDialogOpened') ?? false;

    if (!alreadyOpened) {
      logInfo('Menampilkan dialog permintaan Exact Alarm...');
      await showMyDialog();
    }
  } else if (status.isGranted) {
    logSuccess('SUKSES! Izin Exact Alarm GRANTED');
  }
} */

/// Dialog untuk meminta izin "Exact Alarm"
Future<void> showMyDialog() async {
  return showDialog<void>(
    context: Get.context!,
    barrierColor: Colors.black54,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Buka Pengaturan Alarm'),
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                'Untuk mengaktifkan notifikasi waktu sholat yang akurat, Anda perlu mengizinkan aplikasi ini untuk mengatur alarm secara tepat.',
              ),
              Text(
                'Buka pengaturan dan aktifkan "Izinkan alarm dan pengingat" untuk aplikasi ini.',
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Ya'),
            onPressed: () async {
              Navigator.of(context).pop();
              final prefs = await SharedPreferences.getInstance();
              const intent = AndroidIntent(
                action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
                flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
                package: 'com.natapradja.project.waktu_shalat',
              );

              try {
                await intent.launch();
                await prefs.setBool('alarmPermissionDialogOpened', true);
                logInfo('Pengaturan Exact Alarm dibuka.');
              } catch (e) {
                logError('Gagal membuka pengaturan Exact Alarm: $e');
              }
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
