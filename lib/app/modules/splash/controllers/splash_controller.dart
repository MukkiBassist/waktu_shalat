// lib/app/modules/splash/controllers/splash_controller.dart
// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:sholat/app/routes/app_pages.dart';
import 'package:sholat/app/utils/logger.dart';

import '../../prayer_times/controllers/prayer_times_controller.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Inisialisasi PrayerTimesController menggunakan Get.put
      Get.put(PrayerTimesController());

      // 2. Tunggu sebentar untuk efek splash screen
      await Future.delayed(const Duration(seconds: 2));

      // 3. Navigasi ke rute HOME
      Get.offNamed(Routes.HOME);
      logSuccess('Navigating to HomePage');
    } catch (e) {
      logError('Initialization failed: $e');
      // Navigasi ke halaman utama meskipun ada error
      Get.offNamed(Routes.HOME);
    }
  }
}
