import 'package:get/get.dart';
import 'cutout_burst_portrait_cutout_logic.dart';
class CutoutBurstPortraitCutoutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CutoutBurstPortraitCutoutLogic());
  }
}
