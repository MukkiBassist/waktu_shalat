// lib/app/modules/splash/controllers/splash_controller.dart
// ignore_for_file: avoid_print
// lib/app/modules/splash/controllers/splash_controller.dart

import 'package:get/get.dart';
import 'package:sholat/app/routes/app_pages.dart';
import 'dart:async';

class SplashController extends GetxController {
  // Constructor akan dipanggil pertama kali saat objek dibuat
  /* SplashController() {
    print('SplashController: Constructor called.');
  } */

  @override
  void onInit() {
    super.onInit();
    print('SplashController: onInit called. About to start navigation logic.');
    //_initializeAndNavigate();
    Timer(Duration(seconds: 2), () {
      Get.offNamed(Routes.HOME);
    });
  }
}
