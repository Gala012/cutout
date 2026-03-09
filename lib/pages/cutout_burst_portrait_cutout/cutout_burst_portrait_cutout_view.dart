import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:ui' as ui;
import '../../utils/colors.dart';
import 'cutout_burst_portrait_cutout_logic.dart';

class CutoutBurstPortraitCutoutView
    extends GetView<CutoutBurstPortraitCutoutLogic> {
  const CutoutBurstPortraitCutoutView({super.key});
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('Portrait Cutout'),
          actions: [
            Obx(
                  () => GestureDetector(
                onTap:
                controller.isProcessing.value ? null : controller.onSaveTap,
                child: Container(
                  margin: EdgeInsets.only(left: 4.w, right: 8.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: controller.isProcessing.value
                        ? null
                        : CutoutBurstColors.primaryGradient,
                    color: controller.isProcessing.value
                        ? Colors.grey.shade700
                        : null,
                    borderRadius: BorderRadius.circular(16.h),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildColorPaletteBar(),
              Expanded(child: _buildImagePreview()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPaletteBar() {
    return Container(
      height: 44.h,
      color: const Color(0xFF1A1A24),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: controller.onHelpTap,
            child: Icon(
              Icons.info_outline_rounded,
              size: 18.w,
              color: Colors.white54,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            'Background:',
            style: TextStyle(fontSize: 12.sp, color: Colors.white60),
          ),
          SizedBox(width: 10.w),
          ...CutoutBurstPortraitCutoutLogic.bgColors.map(
                (c) => _buildColorDot(c),
          ),
        ],
      ),
    );
  }

  Widget _buildColorDot(Color color) {
    return Obx(() {
      final isSelected = controller.selectedBgColor.value.value == color.value;
      return GestureDetector(
        onTap: () => controller.onBgColorChange(color),
        child: Container(
          width: 22.w,
          height: 22.w,
          margin: EdgeInsets.only(right: 8.w),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? CutoutBurstColors.primary : Colors.white30,
              width: isSelected ? 2 : 1,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildImagePreview() {
    return Obx(() {
      final bgColor = controller.selectedBgColor.value;
      final isProcessing = controller.isProcessing.value;
      final segmentedImage = controller.segmentedImage.value;
      return Container(
        color: bgColor.withOpacity(0.3),
        child: Stack(
          children: [
            if (segmentedImage != null)
              InteractiveViewer(
                transformationController: controller.transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: CustomPaint(
                    painter: _PortraitCutoutPainter(
                      image: segmentedImage,
                      backgroundColor: bgColor,
                    ),
                    size: Size.infinite,
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outlined,
                      size: 80.w,
                      color: Colors.white24,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      isProcessing
                          ? 'Processing...'
                          : 'Processing portrait...',
                      style: TextStyle(fontSize: 12.sp, color: Colors.white38),
                    ),
                  ],
                ),
              ),
            if (isProcessing)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          CutoutBurstColors.primary,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'AI Processing...',
                        style: TextStyle(fontSize: 14.sp, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _PortraitCutoutPainter extends CustomPainter {
  final ui.Image image;
  final Color backgroundColor;
  _PortraitCutoutPainter({required this.image, required this.backgroundColor});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor.withOpacity(0.5),
    );
    final imgAspect = image.width / image.height;
    final canvasAspect = size.width / size.height;
    double displayW, displayH, displayL, displayT;
    if (imgAspect > canvasAspect) {
      displayW = size.width * 0.9;
      displayH = displayW / imgAspect;
    } else {
      displayH = size.height * 0.9;
      displayW = displayH * imgAspect;
    }
    displayL = (size.width - displayW) / 2;
    displayT = (size.height - displayH) / 2;
    final displayRect = Rect.fromLTWH(displayL, displayT, displayW, displayH);
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.drawImageRect(image, srcRect, displayRect, Paint());
  }

  @override
  bool shouldRepaint(_PortraitCutoutPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
