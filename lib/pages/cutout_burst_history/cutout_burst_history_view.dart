import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import 'cutout_burst_history_logic.dart';
class CutoutBurstHistoryView extends GetView<CutoutBurstHistoryLogic> {
  const CutoutBurstHistoryView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CutoutBurstColors.bg,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value && controller.histories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Expanded(
              child: controller.histories.isEmpty
                  ? _buildEmptyState()
                  : _buildGrid(),
            ),
            Obx(() => controller.isEditMode.value
                ? _buildEditToolbar()
                : const SizedBox.shrink()),
          ],
        );
      }),
    );
  }
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: CutoutBurstColors.card,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              gradient: CutoutBurstColors.primaryGradient,
              borderRadius: BorderRadius.circular(10.w),
              boxShadow: [
                BoxShadow(
                  color: CutoutBurstColors.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(Icons.history, color: Colors.white, size: 20.w),
          ),
          const Spacer(),
          ShaderMask(
            shaderCallback: (bounds) =>
                CutoutBurstColors.titleGradient.createShader(bounds),
            child: Text(
              'History',
              style: TextStyle(
                fontSize: 21.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Spacer(),
          Obx(() => TextButton(
                onPressed: controller.toggleEditMode,
                child: Text(
                  controller.isEditMode.value ? 'Done' : 'Edit',
                  style: TextStyle(
                    color: CutoutBurstColors.primary,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )),
        ],
      ),
    );
  }
  Widget _buildGrid() {
    return Obx(() => GridView.builder(
          padding: EdgeInsets.all(12.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 8.h,
            childAspectRatio: 0.82,
          ),
          itemCount: controller.histories.length,
          itemBuilder: (_, i) => _buildWorkCard(controller.histories[i]),
        ));
  }
  Widget _buildWorkCard(dynamic history) {
    return Obx(() {
      final isSelected = controller.selectedIds.contains(history.id);
      final modeColor = controller.getModeColor(history.cutoutMode);
      final modeName = controller.getModeDisplayName(history.cutoutMode);
      return GestureDetector(
        onTap: () => controller.onPreviewTap(history),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: CutoutBurstColors.card,
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(
                  color: isSelected
                      ? CutoutBurstColors.primary
                      : CutoutBurstColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: CutoutBurstColors.elevated,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12.w),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12.w),
                        ),
                        child: Image.file(
                          File(history.thumbnailPath),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: CutoutBurstColors.textTertiary,
                              size: 26.w,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          modeName,
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: modeColor,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          history.createdAt,
                          style: TextStyle(
                            fontSize: 8.sp,
                            color: CutoutBurstColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (controller.isEditMode.value)
              Positioned(
                top: 6.w,
                right: 6.w,
                child: Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? CutoutBurstColors.primary
                        : CutoutBurstColors.elevated,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? CutoutBurstColors.primary
                          : CutoutBurstColors.textTertiary,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 13.w,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
          ],
        ),
      );
    });
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64.w,
            color: CutoutBurstColors.textTertiary,
          ),
          SizedBox(height: 16.h),
          Text(
            'No records yet.',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: CutoutBurstColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Go to Home to start your first cutout.',
            style: TextStyle(
              fontSize: 13.sp,
              color: CutoutBurstColors.textTertiary,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: controller.onGoToHomeTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: CutoutBurstColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.w),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 28.w,
                vertical: 12.h,
              ),
            ),
            child: Text(
              'Go to Home',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildEditToolbar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: CutoutBurstColors.card,
        border: Border(
          top: BorderSide(color: CutoutBurstColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            TextButton.icon(
              onPressed: controller.selectAll,
              icon: Icon(
                Icons.select_all_rounded,
                size: 18.w,
                color: CutoutBurstColors.primary,
              ),
              label: Text(
                'Select All',
                style: TextStyle(
                  color: CutoutBurstColors.primary,
                  fontSize: 14.sp,
                ),
              ),
            ),
            const Spacer(),
            Obx(() => ElevatedButton.icon(
                  onPressed: controller.selectedIds.isEmpty
                      ? null
                      : controller.onDeleteSelectedTap,
                  icon: Icon(Icons.delete_outline_rounded, size: 18.w),
                  label: Text(
                    'Delete (${controller.selectedIds.length})',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CutoutBurstColors.danger,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        CutoutBurstColors.danger.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.w),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
