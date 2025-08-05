// lib/app/utils/notification_controller.dart

// ignore_for_file: avoid_print

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:sholat/app/utils/notification_helper.dart';

class NotificationController {
  static const int dummyNotificationId = 1001;

  @pragma('vm:entry-point')
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'prayer_time_channel',
        channelName: 'Jadwal Sholat',
        channelDescription: 'Notifikasi waktu sholat harian',
        importance: NotificationImportance.High,
      ),
    ], debug: true);
    AwesomeNotifications().setListeners(
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onActionReceivedMethod: onActionReceivedMethod,
    );
  }

  /// Method global yang akan dipanggil ketika ada aksi pada notifikasi
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    // Hanya tangani notifikasi dummy jam 00:01
    if (action.id == dummyNotificationId ||
        action.payload?['reschedule'] == 'true') {
      print('📌 Dummy notification received ➜ Rescheduling...');
      await handleRescheduleIfNeeded();
    }
  }

  // Jika Anda tidak membutuhkan event ini, cukup hapus atau buat metode kosong
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    print('Notification created: ${receivedNotification.id}');
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification notif,
  ) async {
    if (notif.id == dummyNotificationId &&
        notif.channelKey == 'prayer_time_channel') {
      print('Dummy Display Detected --> Trigger reschedule');
    }
    await handleRescheduleIfNeeded();
  }

  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    print('Notification dismissed: ${receivedNotification.id}');
  }
}
