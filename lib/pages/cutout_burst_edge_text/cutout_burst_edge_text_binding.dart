import 'package:get/get.dart';
import 'cutout_burst_edge_text_logic.dart';
class CutoutBurstEdgeTextBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CutoutBurstEdgeTextLogic());
  }
}
