//lib\app\modules\home\controllers\home_controller.dart
// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:sholat/app/modules/dzikir/views/dzikir_view.dart';
import 'package:sholat/app/modules/prayer_times/views/prayer_times_view.dart';
import 'package:sholat/app/modules/qibla/views/qibla_view.dart';
import 'package:sholat/app/modules/settings/views/settings_view.dart';
import 'package:sholat/app/utils/permission_helper.dart';

class HomeController extends GetxController {
  final _selectedIndex = 0.obs;
  int get selectedIndex => _selectedIndex.value;
  set selectedIndex(int index) => _selectedIndex.value = index;

  final List<Widget> pages = [
    PrayerTimesView(),
    DzikirView(),
    QiblaView(),
    SettingsView(),
  ];

  void onItemTapped(int index) {
    selectedIndex = index;
  }

  @override
  void onReady() {
    super.onReady();
    print('onReady requestExactAlarmPermissionOnce');
    requestExactAlarmPermissionOnce();
  }
}
