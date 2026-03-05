import 'package:get/get.dart';
import '../cutout_burst_home/cutout_burst_home_logic.dart';
import '../cutout_burst_history/cutout_burst_history_logic.dart';
import '../cutout_burst_settings/cutout_burst_settings_logic.dart';
import 'cutout_burst_tab_logic.dart';
class CutoutBurstTabBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CutoutBurstTabLogic());
    Get.lazyPut(() => CutoutBurstHomeLogic());
    Get.lazyPut(() => CutoutBurstHistoryLogic());
    Get.lazyPut(() => CutoutBurstSettingsLogic());
  }
}
