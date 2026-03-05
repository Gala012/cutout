import 'package:get/get.dart';
import 'cutout_burst_shape_cutout_logic.dart';
class CutoutBurstShapeCutoutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CutoutBurstShapeCutoutLogic());
  }
}
