import 'package:get/get.dart';
import 'cutout_burst_crop_logic.dart';
class CutoutBurstCropBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CutoutBurstCropLogic());
  }
}
