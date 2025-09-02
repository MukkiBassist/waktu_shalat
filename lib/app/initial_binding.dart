// lib/app/initial_binding.dart

import 'package:get/get.dart';
import 'package:sholat/app/services/prayer_cache_service.dart';
import 'package:sholat/app/modules/prayer_times/controllers/prayer_times_controller.dart';
import 'package:sholat/app/modules/settings/controllers/settings_controller.dart';
import 'package:sholat/app/theme/theme_controller.dart';
import 'package:sholat/app/utils/notification_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services
    Get.put(PrayerCacheService());

    // Core controllers
    Get.put(SettingsController());
    Get.put(PrayerTimesController());
    Get.put(ThemeController());
    Get.put(NotificationController());
  }
}
