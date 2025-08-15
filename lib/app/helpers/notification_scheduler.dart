// lib/app/helpers/notification_scheduler.dart
// ignore_for_file: avoid_print

import 'package:sholat/app/services/notification_service.dart';

/// Minimal model to match your app's PrayerTime if needed
class PrayerTime {
  final int id;
  final String name;
  final DateTime dateTime;
  PrayerTime({required this.id, required this.name, required this.dateTime});
}

/// Entry point used both from foreground and background isolates.
/// Schedules one-shot notifications for given list; skips past times & respects user prefs.
Future<void> schedulePrayerNotificationsWithCatchup(
  List<PrayerTime> times,
  Map<String, bool> notificationPrefs,
) async {
  final notif = NotificationService();

  // cancel only previous prayer notifications (done upstream usually)
  // schedule new ones
  int nextId = 1000;
  final now = DateTime.now();

  for (final p in times) {
    final enabled = notificationPrefs[p.name] ?? true;

    if (!enabled) continue;
    if (!p.dateTime.isAfter(now)) {
      // skip past times, except special catch-up rules if you want (e.g. Isya after midnight)
      continue;
    }

    await notif.schedulePrayerNotification(
      id: nextId++,
      title: 'Waktu ${p.name}',
      body:
          'Saatnya ${p.name} - ${p.dateTime.hour.toString().padLeft(2, '0')}:${p.dateTime.minute.toString().padLeft(2, '0')}',
      dateTime: p.dateTime,
      payload: 'prayer_${p.name}',
    );
  }
}
