import 'package:get/get.dart';
import '../cutout_burst_history/cutout_burst_history_logic.dart';
import '../cutout_burst_home/cutout_burst_home_logic.dart';
class CutoutBurstTabLogic extends GetxController {
  final currentIndex = 0.obs;
  void onTabChange(int index) {
    if (currentIndex.value == index) return;
    currentIndex.value = index;
    if (index == 0) {
      try {
        final homeLogic = Get.find<CutoutBurstHomeLogic>();
        homeLogic.loadRecentWorks();
      } catch (e) {
      }
    } else if (index == 1) {
      try {
        final historyLogic = Get.find<CutoutBurstHistoryLogic>();
        historyLogic.loadHistories();
      } catch (e) {
      }
    }
  }
}
