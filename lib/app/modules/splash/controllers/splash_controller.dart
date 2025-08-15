// lib/app/modules/splash/controllers/splash_controller.dart
// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:sholat/app/routes/app_pages.dart';
import 'package:sholat/app/modules/prayer_times/controllers/prayer_times_controller.dart';
import 'package:sholat/app/services/prayer_cache_service.dart';
import 'package:sholat/app/utils/logger.dart';
import 'package:sholat/app/utils/notification_helper.dart';
//import 'package:sholat/app/utils/permission_helper.dart';
import 'package:sholat/app/utils/notification_controller.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    final prayerController = Get.find<PrayerTimesController>();
    final cacheService = PrayerCacheService();
    final needsUpdate = await cacheService.isCacheExpired();
    try {
      //1. Memeriksa apakah cache sholat perlu diperbarui
      logInfo('SplashController: Memeriksa cache sholat...');
      if (needsUpdate) {
        await cacheService.fetchAndCachePrayerTimes();
      }

      // 2. Memuat data sholat (sekalian minta izin lokasi di dalamnya)
      logInfo('SplashController: Memuat data sholat dan lokasi...');
      await prayerController.loadPrayerTimes();

      // 3. Memastikan notifikasi sholat hari ini dijadwalkan
      print('SplashController: Memeriksa penjadwalan hari ini...');
      final alreadyScheduled = await checkIfTodayScheduled();
      if (!alreadyScheduled) {
        await NotificationController.performReschedule();
      }

      logSuccess('SplashController: Semua inisialisasi berhasil.');
    } catch (e) {
      print('❌ SplashController: Inisialisasi gagal: $e');
    }

    // 4. Navigasi ke halaman utama
    await Future.delayed(const Duration(seconds: 2));
    Get.offAllNamed(Routes.HOME);
  }
}
