import 'package:get/get.dart';
import 'cutout_burst_select_photo_logic.dart';
class CutoutBurstSelectPhotoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CutoutBurstSelectPhotoLogic());
  }
}
