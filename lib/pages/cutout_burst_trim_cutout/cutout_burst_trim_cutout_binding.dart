import 'package:get/get.dart';
import 'cutout_burst_trim_cutout_logic.dart';
class CutoutBurstTrimCutoutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CutoutBurstTrimCutoutLogic());
  }
}
