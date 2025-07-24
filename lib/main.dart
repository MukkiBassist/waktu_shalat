// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sholat/app/utils/notification_helper.dart';
import 'package:sholat/app/utils/permission_helper.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:awesome_notifications/awesome_notifications.dart';

import 'package:sholat/app/modules/home/bindings/home_binding.dart';
import 'package:sholat/app/theme/theme_controller.dart';
import 'app/routes/app_pages.dart';

/// Inisialisasi timezone lokal berdasarkan perangkat
Future<void> setupTimeZone() async {
  tz.initializeTimeZones();
  final String timeZoneName = await AwesomeNotifications()
      .getLocalTimeZoneIdentifier();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}

void main() async {
  /// 1. Wajib untuk async di main()
  WidgetsFlutterBinding.ensureInitialized();

  /// 2. Inisialisasi Timezone lokal
  await setupTimeZone();

  /// 3. Inisialisasi format tanggal lokal (untuk Intl)
  await initializeDateFormatting('id', null);

  /// 4. Minta semua izin penting (notifikasi & alarm)
  await checkAllNotificationPermissions();

  /// 5. Inisialisasi channel notifikasi
  AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelKey: 'prayer_time_channel',
      channelName: 'Waktu Sholat',
      channelDescription: 'Notifikasi untuk waktu sholat harian',
      defaultColor: const Color(0xFF9D50DD),
      ledColor: Colors.white,
      importance: NotificationImportance.High,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      channelShowBadge: true,
    ),
  ], debug: true);

  /// 6. Jadwal dummy harian jam 00:01 untuk refresh jadwal sholat
  await scheduleDailyRescheduled();

  /// 7. Pastikan sistem mengizinkan notifikasi
  if (!await AwesomeNotifications().isNotificationAllowed()) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  /// 8. Inisialisasi theme dan preferensi
  final themeController = Get.put(ThemeController());
  await themeController.loadTheme();

  /// 9. Jalankan aplikasi
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sholat',
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
        initialBinding: HomeBinding(),
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeController.isDarkMode.value
            ? ThemeMode.dark
            : ThemeMode.light,
      ),
    );
  }
}
//| Fungsi                                           | Tujuan                                                                |
//| ------------------------------------------------ | --------------------------------------------------------------------- |
//| `setupTimeZone()`                                | Menyamakan zona waktu lokal untuk waktu notifikasi akurat             |
//| `checkAllNotificationPermissions()`              | Gabungan pengecekan dan request izin notifikasi & exact alarm         |
//| `AwesomeNotifications().initialize()`            | Inisialisasi channel notifikasi utama                                 |
//| `scheduleDailyRescheduled()`                     | Menjadwalkan dummy notifikasi 00:01 untuk mengecek & refresh otomatis |
//| `AwesomeNotifications().isNotificationAllowed()` | Pastikan sistem Android mengizinkan pengiriman notifikasi             |
//| `ThemeController().loadTheme()`                  | Memuat preferensi tema terang/gelap                                   |

//
