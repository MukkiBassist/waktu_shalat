import 'package:get/get.dart';

import '../controllers/qibla_controller.dart';

class QiblaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<QiblaController>(
      () => QiblaController(),
    );
  }
}
