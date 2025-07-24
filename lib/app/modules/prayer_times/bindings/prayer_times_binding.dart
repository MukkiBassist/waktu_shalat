import 'package:get/get.dart';
import '../controllers/prayer_times_controller.dart';

class PrayerTimesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PrayerTimesController>(() => PrayerTimesController());
  }
}
