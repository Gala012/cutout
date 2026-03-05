import 'package:get/get.dart';
import 'cutout_burst_change_bg_logic.dart';
class CutoutBurstChangeBgBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CutoutBurstChangeBgLogic());
  }
}
