// lib/app/modules/splash/controllers/splash_controller.dart
// ignore_for_file: avoid_print

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:sholat/app/routes/app_pages.dart';
import 'package:sholat/app/modules/prayer_times/controllers/prayer_times_controller.dart';
import 'package:sholat/app/services/prayer_cache_service.dart';
import 'package:sholat/app/utils/logger.dart';
import 'package:sholat/app/utils/notification_helper.dart';
import 'package:sholat/app/utils/notification_controller.dart';
import 'package:sholat/app/utils/permission_helper.dart';

class SplashController extends GetxController with WidgetsBindingObserver {
  @override
  void onInit() {
    super.onInit();
    //_initializeAndNavigate();
    WidgetsBinding.instance.addObserver(this);
    Get.put(PrayerTimesController());
  }

  @override
  Future<void> onReady() async {
    super.onReady();
    logInfo('SplashController: onReady - Memulai inisialisasi...');
    //_initializeAndNavigate();
    //start perubahan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndNavigate();
    });

    //checkAllPermissions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      logInfo("App kembali dari background → melanjutkan alur inisialisasi");
      // _initializeAndNavigate();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  Future<void> _initializeAndNavigate() async {
    // 1. Dapatkan instance PrayerTimesController
    final prayerController = Get.find<PrayerTimesController>();
    final cacheService = PrayerCacheService();

    try {
      await checkAllPermissions();
      //1. Memeriksa apakah cache sholat perlu diperbarui
      final isCacheExpired = await cacheService.isCacheExpired();
      // Jika cache sudah kadaluarsa, ambil data sholat baru
      logInfo('SplashController: Memeriksa cache sholat...');
      if (isCacheExpired) {
        logInfo('SplashController: Cache sholat kadaluarsa, memperbarui...');

        await cacheService.loadPrayerTimesAndSavetoCache();
        // 2. Muat data yang baru di-fetch ke PrayerTimesController
        await prayerController.loadPrayerTimesFromCache();
      } else {
        // Jika cache masih valid, muat data dari cache ke PrayerTimesController
        await prayerController.loadPrayerTimesFromCache();
        logInfo(
          'SplashController: Cache sholat masih valid, menggunakan cache.',
        );
        /* await cacheService.getCachedPrayerTimes();
        logInfo(
          'SplashController: Cache sholat masih valid, menggunakan cache.',
        ); */
      }

      // 2. Memuat data sholat (sekalian minta izin lokasi di dalamnya)
      /* logInfo('SplashController: Memuat data sholat dan lokasi...');
      await prayerController.loadPrayerTimes(); */

      // 3. Memastikan notifikasi sholat hari ini dijadwalkan
      logLoading('SplashController: Memeriksa penjadwalan hari ini...');
      final alreadyScheduled = await checkIfTodayScheduled();
      if (!alreadyScheduled) {
        await NotificationController.performReschedule();
      }

      logSuccess('SplashController: Semua inisialisasi berhasil.');
    } catch (e) {
      logError('SplashController: Inisialisasi gagal: $e');
    }

    // 4. Navigasi ke halaman utama
    //await Future.delayed(const Duration(seconds: 2));
    Get.offAllNamed(Routes.HOME);
  }
}
