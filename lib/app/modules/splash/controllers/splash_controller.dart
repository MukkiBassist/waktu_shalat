// lib/app/modules/splash/controllers/splash_controller.dart

// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:sholat/app/routes/app_pages.dart';
import 'package:sholat/app/modules/prayer_times/controllers/prayer_times_controller.dart';
import 'package:sholat/app/utils/permission_helper.dart';
import 'package:sholat/app/utils/notification_helper.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _initializeAndNavigate();
  }

  void _initializeAndNavigate() async {
    final controller = Get.find<PrayerTimesController>();

    try {
      // 1. Meminta izin lokasi dan layanan lokasi terlebih dahulu
      print('SplashController: Meminta izin lokasi...');
      await controller.requestLocationPermission();

      // 2. Kemudian, meminta semua izin notifikasi
      print('SplashController: Memeriksa dan meminta izin notifikasi...');
      await checkAllNotificationPermissions();

      // 3. Setelah semua izin diberikan, baru memuat data sholat dan lokasi
      print('SplashController: Memuat data sholat dan lokasi...');
      await controller.fetchPrayerTimes();

      // 4. Menjadwalkan notifikasi harian dummy (pukul 00:01)
      print('SplashController: Menjadwalkan notifikasi dummy harian...');
      await scheduleDailyRescheduler();

      // 5. Memastikan notifikasi sholat hari ini dijadwalkan (jika belum)
      print('SplashController: Memeriksa penjadwalan hari ini...');
      await handleRescheduleIfNeeded();

      print('SplashController: Semua inisialisasi berhasil.');
    } catch (e) {
      print('SplashController: Inisialisasi gagal: $e');
      // Anda bisa menampilkan error di UI atau mencoba lagi
    }

    // Pindah ke halaman utama setelah semua selesai
    await Future.delayed(const Duration(seconds: 1));
    Get.offAllNamed(Routes.HOME);
  }
}
