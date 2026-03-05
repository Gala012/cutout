import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import '../cutout_burst_home/cutout_burst_home_view.dart';
import '../cutout_burst_history/cutout_burst_history_view.dart';
import '../cutout_burst_settings/cutout_burst_settings_view.dart';
import 'cutout_burst_tab_logic.dart';
class CutoutBurstTabView extends GetView<CutoutBurstTabLogic> {
  const CutoutBurstTabView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CutoutBurstColors.bg,
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            CutoutBurstHomeView(),
            CutoutBurstHistoryView(),
            CutoutBurstSettingsView(),
          ],
        ),
      ),
      bottomNavigationBar: Obx(() => _buildBottomNav()),
    );
  }
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: CutoutBurstColors.card,
        border: Border(
          top: BorderSide(color: CutoutBurstColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h).copyWith(bottom: 24.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                index: 0,
              ),
              _buildTabItem(
                icon: Icons.history_outlined,
                activeIcon: Icons.history_rounded,
                label: 'History',
                index: 1,
              ),
              _buildTabItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: 'Settings',
                index: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildTabItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = controller.currentIndex.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.onTabChange(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Container(
                width: 20.w,
                height: 2.h,
                margin: EdgeInsets.only(bottom: 2.h),
                decoration: BoxDecoration(
                  gradient: CutoutBurstColors.primaryGradient,
                  borderRadius: BorderRadius.circular(1.w),
                ),
              )
            else
              SizedBox(height: 4.h),
            Icon(
              isActive ? activeIcon : icon,
              size: 24.w,
              color: isActive
                  ? CutoutBurstColors.primary
                  : CutoutBurstColors.textTertiary,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive
                    ? CutoutBurstColors.primary
                    : CutoutBurstColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
