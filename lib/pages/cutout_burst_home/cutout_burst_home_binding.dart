import 'package:get/get.dart';
import 'cutout_burst_home_logic.dart';
class CutoutBurstHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CutoutBurstHomeLogic());
  }
}
