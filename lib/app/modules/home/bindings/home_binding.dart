import 'package:get/get.dart';
import 'package:sholat/app/modules/dzikir/controllers/dzikir_controller.dart';
import 'package:sholat/app/modules/qibla/controllers/qibla_controller.dart';

import '../../prayer_times/controllers/prayer_times_controller.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<PrayerTimesController>(() => PrayerTimesController());
    Get.lazyPut<DzikirController>(() => DzikirController());
    Get.lazyPut<QiblaController>(() => QiblaController());
  }
}
