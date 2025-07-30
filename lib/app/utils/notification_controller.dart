// notification_controller.dart
// ignore_for_file: avoid_print

import 'dart:ui';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:sholat/app/utils/notification_helper.dart';

class NotificationController {
  @pragma('vm:entry-point')
  static Future<void> initialize() async {
    // Inisialisasi channel notifikasi
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'prayer_time_channel',
        channelName: 'Prayer Notifications',
        channelDescription: 'Notification for daily prayer times',
        importance: NotificationImportance.High,
        channelShowBadge: true,
        defaultColor: const Color(0xFF2196f3),
        ledColor: const Color(0xFFFFFFFF),
        locked: true,
      ),
    ], debug: true);

    // Listener untuk menerima aksi dari notifikasi
    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );
  }

  /// Method global yang akan dipanggil ketika ada aksi pada notifikasi
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    // Hanya tangani notifikasi dummy jam 00:01
    if (action.id == 999999 || action.payload?['reschedule'] == 'true') {
      print('📌 Dummy notification received ➜ Rescheduling...');
      await handleRescheduleIfNeeded();
    }
  }
}
