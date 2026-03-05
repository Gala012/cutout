import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import 'cutout_burst_change_bg_logic.dart';
class CutoutBurstChangeBgView extends GetView<CutoutBurstChangeBgLogic> {
  const CutoutBurstChangeBgView({super.key});
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(child: _buildPreviewArea()),
            _buildBackgroundSelector(),
          ],
        ),
      ),
    );
  }
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Change Background'),
      actions: [
        IconButton(
          onPressed: controller.resetImagePosition,
          padding: EdgeInsets.all(6.w),
          constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.w),
          icon: Icon(Icons.refresh, size: 20.w, color: Colors.white70),
          tooltip: 'Reset Position',
        ),
        Padding(
          padding: EdgeInsets.only(right: 4.w),
          child: Center(
            child: Obx(() {
              final isProcessing = controller.isProcessing.value;
              return GestureDetector(
                onTap: isProcessing ? null : controller.onSaveTap,
                child: Container(
                  margin: EdgeInsets.only(left: 4.w),
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    gradient: isProcessing
                        ? LinearGradient(
                            colors: [Colors.grey[600]!, Colors.grey[700]!],
                          )
                        : CutoutBurstColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16.h),
                  ),
                  child: isProcessing
                      ? SizedBox(
                          width: 38.w,
                          height: 18.h,
                          child: const Center(
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
  Widget _buildPreviewArea() {
    return Obx(() {
      final image = controller.uiImage.value;
      final isLoading = controller.isLoading.value;
      if (isLoading || image == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16.h),
              Text(
                'Loading image...',
                style: TextStyle(fontSize: 14.sp, color: Colors.white38),
              ),
            ],
          ),
        );
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          double displayWidth, displayHeight;
          if (controller.displayWidth > 0 && controller.displayHeight > 0) {
            displayWidth = controller.displayWidth;
            displayHeight = controller.displayHeight;
          } else {
            final imgWidth = image.width.toDouble();
            final imgHeight = image.height.toDouble();
            final containerWidth = constraints.maxWidth;
            final containerHeight = constraints.maxHeight;
            final scaleWidth = containerWidth / imgWidth;
            final scaleHeight = containerHeight / imgHeight;
            final scale = min(scaleWidth, scaleHeight);
            displayWidth = imgWidth * scale;
            displayHeight = imgHeight * scale;
          }
          return Stack(
            children: [
              Positioned.fill(
                child: Obx(() {
                  if (controller.selectedBgType.value == BgType.color) {
                    return Container(
                      color: CutoutBurstChangeBgLogic.colorBackgrounds[
                          controller.selectedColorIndex.value],
                    );
                  } else {
                    return Image.asset(
                      CutoutBurstChangeBgLogic.imageBackgrounds[
                          controller.selectedImageIndex.value],
                      fit: BoxFit.cover,
                    );
                  }
                }),
              ),
              Obx(() {
                final offsetX = controller.imageOffsetX.value;
                final offsetY = controller.imageOffsetY.value;
                return Positioned(
                  left: (constraints.maxWidth - displayWidth) / 2 + offsetX,
                  top: (constraints.maxHeight - displayHeight) / 2 + offsetY,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      controller.onPanUpdate(
                          details.delta.dx, details.delta.dy);
                    },
                    child: SizedBox(
                      width: displayWidth,
                      height: displayHeight,
                      child: RawImage(
                        image: image,
                        width: displayWidth,
                        height: displayHeight,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      );
    });
  }
  Widget _buildBackgroundSelector() {
    return Container(
      color: const Color(0xFF111118),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12.h),
          _buildColorSelector(),
          SizedBox(height: 16.h),
          _buildImageSelector(),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }
  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Color Background',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 50.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            itemCount: CutoutBurstChangeBgLogic.colorBackgrounds.length,
            itemBuilder: (context, index) {
              return Obx(() {
                final isSelected =
                    controller.selectedBgType.value == BgType.color &&
                        controller.selectedColorIndex.value == index;
                return GestureDetector(
                  onTap: () => controller.selectColorBackground(index),
                  child: Container(
                    width: 44.w,
                    height: 44.w,
                    margin: EdgeInsets.only(right: 8.w),
                    decoration: BoxDecoration(
                      color: CutoutBurstChangeBgLogic.colorBackgrounds[index],
                      borderRadius: BorderRadius.circular(8.w),
                      border: Border.all(
                        color: isSelected
                            ? CutoutBurstColors.primary
                            : Colors.white30,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }
  Widget _buildImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Image Background',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 80.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            itemCount: CutoutBurstChangeBgLogic.imageBackgrounds.length,
            itemBuilder: (context, index) {
              return Obx(() {
                final isSelected =
                    controller.selectedBgType.value == BgType.image &&
                        controller.selectedImageIndex.value == index;
                return GestureDetector(
                  onTap: () => controller.selectImageBackground(index),
                  child: Container(
                    width: 70.w,
                    height: 70.w,
                    margin: EdgeInsets.only(right: 8.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.w),
                      border: Border.all(
                        color: isSelected
                            ? CutoutBurstColors.primary
                            : Colors.white30,
                        width: isSelected ? 3 : 1,
                      ),
                      image: DecorationImage(
                        image: AssetImage(
                          CutoutBurstChangeBgLogic.imageBackgrounds[index],
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }
}
