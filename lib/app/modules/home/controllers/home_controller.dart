//lib\app\modules\home\controllers\home_controller.dart
// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:sholat/app/modules/dzikir/views/dzikir_view.dart';
import 'package:sholat/app/modules/prayer_times/views/prayer_times_view.dart';
import 'package:sholat/app/modules/qibla/views/qibla_view.dart';
import 'package:sholat/app/modules/settings/views/settings_view.dart';
import 'package:sholat/app/modules/quran/views/quran_view.dart';

class HomeController extends GetxController {
  final _selectedIndex = 0.obs;
  int get selectedIndex => _selectedIndex.value;
  set selectedIndex(int index) => _selectedIndex.value = index;

  final List<Widget> pages = [
    PrayerTimesView(activePrayerColor: Colors.transparent),
    QuranView(),
    DzikirView(),
    QiblaView(),
    SettingsView(),
  ];

  void onItemTapped(int index) {
    selectedIndex = index;
  }

  @override
  // ignore: unnecessary_overrides
  void onReady() {
    super.onReady();
    //logInfo('onReady requestExactAlarmPermissionOnce');
    //requestExactAlarmPermissionOnce();
  }
}
