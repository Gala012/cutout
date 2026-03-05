import 'package:get/get.dart';
import 'cutout_burst_settings_logic.dart';
class CutoutBurstSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CutoutBurstSettingsLogic());
  }
}
