import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import 'cutout_burst_crop_logic.dart';
class CutoutBurstCropView extends GetView<CutoutBurstCropLogic> {
  const CutoutBurstCropView({super.key});
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildHint(),
            Expanded(child: _buildCropArea()),
            _buildRatioPanel(),
          ],
        ),
      ),
    );
  }
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Crop',
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 12.w),
          child: Center(
            child: Obx(() {
              final isProcessing = controller.isProcessing.value;
              return GestureDetector(
                onTap: isProcessing ? null : controller.onCutoutTap,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    gradient: isProcessing
                        ? LinearGradient(
                            colors: [
                              Colors.grey[600]!,
                              Colors.grey[700]!,
                            ],
                          )
                        : CutoutBurstColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20.h),
                  ),
                  child: isProcessing
                      ? SizedBox(
                          width: 40.w,
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
                          'Cutout',
                          style: TextStyle(
                            fontSize: 14.sp,
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
  Widget _buildHint() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      color: Colors.white.withOpacity(0.05),
      child: Text(
        'Crop the image but keep enough background',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12.sp, color: Colors.white70),
      ),
    );
  }
  Widget _buildCropArea() {
    return Obx(() {
      final file = controller.imageFile.value;
      if (file == null) {
        return _buildNoImagePlaceholder();
      }
      return _buildImageWithCropOverlay(file);
    });
  }
  Widget _buildNoImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 64.w, color: Colors.white24),
          SizedBox(height: 12.h),
          Text(
            'Loading image...',
            style: TextStyle(fontSize: 14.sp, color: Colors.white38),
          ),
        ],
      ),
    );
  }
  Widget _buildImageWithCropOverlay(File file) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.updateContainerSize(
            constraints.maxWidth,
            constraints.maxHeight,
          );
        });
        return Stack(
          children: [
            InteractiveViewer(
              transformationController: controller.transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              panEnabled: true,
              scaleEnabled: true,
              boundaryMargin: const EdgeInsets.all(500),
              constrained: false,
              child: Container(
                width: constraints.maxWidth,
                color: Colors.black,
                alignment: Alignment.center,
                child: _buildImageWithMeasurement(
                  file,
                  constraints,
                ),
              ),
            ),
            _buildCropOverlay(),
          ],
        );
      },
    );
  }
  Widget _buildImageWithMeasurement(
    File imageFile,
    BoxConstraints constraints,
  ) {
    return Image.file(
      imageFile,
      fit: BoxFit.contain,
      width: constraints.maxWidth,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame == null) return child;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null && renderBox.hasSize) {
            final displayRect = Rect.fromLTWH(
              0,
              0,
              renderBox.size.width,
              renderBox.size.height,
            );
            controller.updateImageDisplayRect(displayRect);
          }
        });
        return child;
      },
    );
  }
  Widget _buildCropOverlay() {
    return Obx(() {
      if (controller.cropBoxWidth.value == 0 ||
          controller.cropBoxHeight.value == 0) {
        return const SizedBox.shrink();
      }
      final cropLeft = controller.cropBoxLeft.value;
      final cropTop = controller.cropBoxTop.value;
      final cropBoxWidth = controller.cropBoxWidth.value;
      final cropBoxHeight = controller.cropBoxHeight.value;
      return Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _CropMaskPainter(
                  cropRect: Rect.fromLTWH(
                    cropLeft,
                    cropTop,
                    cropBoxWidth,
                    cropBoxHeight,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: cropLeft,
            top: cropTop,
            width: cropBoxWidth,
            height: cropBoxHeight,
            child: GestureDetector(
              onScaleStart: controller.onCropBoxScaleStart,
              onScaleUpdate: controller.onCropBoxScaleUpdate,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                children: [
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: CutoutBurstColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(child: _buildGridLines()),
                  ..._buildCornerHandles(),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
  Widget _buildGridLines() {
    return Column(
      children: List.generate(
        3,
        (_) => Expanded(
          child: Row(
            children: List.generate(
              3,
              (_) => Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  List<Widget> _buildCornerHandles() {
    return [
      Positioned(top: -10.w, left: -10.w, child: _buildHandle('topLeft')),
      Positioned(top: -10.w, right: -10.w, child: _buildHandle('topRight')),
      Positioned(bottom: -10.w, left: -10.w, child: _buildHandle('bottomLeft')),
      Positioned(
        bottom: -10.w,
        right: -10.w,
        child: _buildHandle('bottomRight'),
      ),
    ];
  }
  Widget _buildHandle(String corner) {
    return GestureDetector(
      onPanStart: (details) {
        controller.onCornerResizeStart(details.globalPosition, corner);
      },
      onPanUpdate: (details) {
        controller.onCornerResizeUpdate(details.globalPosition, corner);
      },
      onPanEnd: (_) {
        controller.onCornerResizeEnd();
      },
      child: Container(
        width: 28.w,
        height: 28.w,
        decoration: BoxDecoration(
          gradient: CutoutBurstColors.primaryGradient,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.open_in_full, size: 14.w, color: Colors.white),
      ),
    );
  }
  Widget _buildRatioPanel() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 20.h),
      color: Colors.white.withOpacity(0.05),
      child: SizedBox(
        height: 68.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: CutoutBurstCropLogic.ratios.length,
          separatorBuilder: (_, __) => SizedBox(width: 6.w),
          itemBuilder: (_, i) {
            final ratio = CutoutBurstCropLogic.ratios[i];
            return Obx(() => _buildRatioItem(ratio));
          },
        ),
      ),
    );
  }
  Widget _buildRatioItem(String ratio) {
    final isSelected = controller.selectedRatio.value == ratio;
    double ar;
    if (ratio == 'Free') {
      ar = 3 / 4;
    } else {
      final parts = ratio.split(':');
      ar = double.parse(parts[0]) / double.parse(parts[1]);
    }
    const maxDim = 28.0;
    final shapeW = ar >= 1 ? maxDim : maxDim * ar;
    final shapeH = ar >= 1 ? maxDim / ar : maxDim;
    return GestureDetector(
      onTap: () => controller.onRatioSelect(ratio),
      child: Container(
        width: 56.w,
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: isSelected
              ? CutoutBurstColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.w),
          border: isSelected
              ? Border.all(
                  color: CutoutBurstColors.primary.withOpacity(0.5),
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: (maxDim + 4).w,
              height: (maxDim + 4).w,
              child: Center(
                child: Container(
                  width: shapeW.w,
                  height: shapeH.w,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? CutoutBurstColors.primary
                          : Colors.white54,
                      width: isSelected ? 2 : 1.5,
                    ),
                    color: isSelected
                        ? CutoutBurstColors.primary.withOpacity(0.1)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              ratio,
              style: TextStyle(
                fontSize: 9.sp,
                color: isSelected ? CutoutBurstColors.primary : Colors.white60,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _CropMaskPainter extends CustomPainter {
  final Rect cropRect;
  const _CropMaskPainter({required this.cropRect});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.55)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, cropRect.top),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
          0, cropRect.bottom, size.width, size.height - cropRect.bottom),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, cropRect.top, cropRect.left, cropRect.height),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(cropRect.right, cropRect.top, size.width - cropRect.right,
          cropRect.height),
      paint,
    );
  }
  @override
  bool shouldRepaint(covariant _CropMaskPainter old) =>
      old.cropRect != cropRect;
}
