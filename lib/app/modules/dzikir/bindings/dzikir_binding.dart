import 'package:get/get.dart';

import '../controllers/dzikir_controller.dart';

class DzikirBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DzikirController>(
      () => DzikirController(),
    );
  }
}
