import 'package:get/get.dart';
import 'cutout_burst_history_logic.dart';
class CutoutBurstHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CutoutBurstHistoryLogic());
  }
}
