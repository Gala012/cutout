import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import 'cutout_burst_settings_logic.dart';
class CutoutBurstSettingsView extends GetView<CutoutBurstSettingsLogic> {
  const CutoutBurstSettingsView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CutoutBurstColors.bg,
      appBar: _buildAppBar(),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        children: [
          _buildSectionTitle('DATA'),
          SizedBox(height: 8.h),
          _buildSettingsCard([
            Obx(() => _buildActionRow(
                  Icons.cleaning_services_outlined,
                  'Clear All Data',
                  controller.cacheSize.value,
                  CutoutBurstColors.danger,
                  onTap: controller.onClearDataTap,
                )),
          ]),
          SizedBox(height: 20.h),
          _buildSectionTitle('ABOUT'),
          SizedBox(height: 8.h),
          _buildSettingsCard([
            Obx(() => _buildInfoRow(
                  Icons.info_outline_rounded,
                  'Version',
                  controller.appVersion.value,
                )),
          ]),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: CutoutBurstColors.card,
      automaticallyImplyLeading: false,
      title: Center(
        child: ShaderMask(
          shaderCallback: (bounds) =>
              CutoutBurstColors.titleGradient.createShader(bounds),
          child: Text(
            'Settings',
            style: TextStyle(
              fontSize: 21.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        color: CutoutBurstColors.textSecondary,
        letterSpacing: 1.0,
      ),
    );
  }
  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: CutoutBurstColors.card,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: CutoutBurstColors.border),
      ),
      child: Column(children: children),
    );
  }
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Icon(icon, size: 20.w, color: CutoutBurstColors.textSecondary),
          SizedBox(width: 12.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: CutoutBurstColors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              color: CutoutBurstColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildActionRow(
    IconData icon,
    String title,
    String value,
    Color actionColor, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Icon(icon, size: 20.w, color: actionColor),
            SizedBox(width: 12.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: actionColor,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                color: CutoutBurstColors.textSecondary,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.chevron_right_rounded,
              size: 18.w,
              color: CutoutBurstColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
