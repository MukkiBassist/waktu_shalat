import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../modules/dzikir/bindings/dzikir_binding.dart';
import '../modules/dzikir/views/dzikir_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
//import '../modules/prayer_times/bindings/prayer_times_binding.dart';
import '../modules/prayer_times/views/prayer_times_view.dart';
import '../modules/qibla/bindings/qibla_binding.dart';
import '../modules/qibla/views/qibla_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';

// ignore_for_file: constant_identifier_names

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH; //.HOME;

  static final routes = [
    GetPage(name: _Paths.HOME, page: () => HomeView(), binding: HomeBinding()),
    GetPage(
      name: _Paths.DZIKIR,
      page: () => DzikirView(),
      binding: DzikirBinding(),
    ),
    GetPage(
      name: _Paths.PRAYER_TIMES,
      page: () => PrayerTimesView(activePrayerColor: Colors.transparent),
      //binding: PrayerTimesBinding(),
    ),
    GetPage(
      name: _Paths.QIBLA,
      page: () => QiblaView(),
      binding: QiblaBinding(),
    ),
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
  ];
}
