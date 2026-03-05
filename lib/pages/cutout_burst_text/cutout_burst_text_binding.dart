import 'package:get/get.dart';

import 'cutout_burst_text_logic.dart';

class CutoutBurstTextBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(
      CutoutBurstTextLogic(),
      permanent: true,
    );
  }
}
