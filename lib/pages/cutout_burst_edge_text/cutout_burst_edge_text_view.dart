import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import 'cutout_burst_edge_text_logic.dart';
class CutoutBurstEdgeTextView extends GetView<CutoutBurstEdgeTextLogic> {
  const CutoutBurstEdgeTextView({super.key});
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            Column(
              children: [
                _buildInfoBar(),
                Expanded(child: _buildImagePreview()),
                Obx(() => controller.selectedTool.isNotEmpty
                    ? _buildSubToolbar()
                    : const SizedBox.shrink()),
                _buildMainToolbar(),
                SizedBox(height: 12.h),
              ],
            ),
            Obx(() => controller.showHelp.value
                ? _buildHelpOverlay()
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Edge + Text'),
      actions: [
        Obx(() => IconButton(
              onPressed: controller.canUndo ? controller.onUndo : null,
              padding: EdgeInsets.all(6.w),
              constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.w),
              icon: Icon(
                Icons.undo_rounded,
                size: 20.w,
                color: controller.canUndo ? Colors.white70 : Colors.white24,
              ),
            )),
        Obx(() => IconButton(
              onPressed: controller.canRedo ? controller.onRedo : null,
              padding: EdgeInsets.all(6.w),
              constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.w),
              icon: Icon(
                Icons.redo_rounded,
                size: 20.w,
                color: controller.canRedo ? Colors.white70 : Colors.white24,
              ),
            )),
        IconButton(
          onPressed: controller.onInfoTap,
          padding: EdgeInsets.all(6.w),
          constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.w),
          icon: Icon(Icons.info_outline_rounded,
              size: 20.w, color: Colors.white70),
        ),
        Obx(() {
          final isProcessing = controller.isProcessing.value;
          return GestureDetector(
            onTap: isProcessing ? null : controller.onShareTap,
            child: Container(
              margin: EdgeInsets.only(left: 4.w, right: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                gradient: isProcessing
                    ? LinearGradient(
                        colors: [Colors.grey[600]!, Colors.grey[700]!])
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
      ],
    );
  }
  Widget _buildInfoBar() {
    return Container(
      height: 30.h,
      color: const Color(0xFF1A1A24),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Obx(() {
            final image = controller.uiImage.value;
            if (image == null) {
              return Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.white54,
                  fontFamily: 'monospace',
                ),
              );
            }
            final imageWidth = image.width.toDouble();
            final displayWidth = controller.imageDisplayWidth.value;
            final zoomPercent = displayWidth > 0
                ? ((displayWidth / imageWidth) * 100).toInt()
                : 100;
            return Text(
              '$zoomPercent%  ${image.width}×${image.height}',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.white54,
                fontFamily: 'monospace',
              ),
            );
          }),
          const Spacer(),
          Obx(() {
            if (controller.selectedTool.value == 'light') {
              final params = controller.lightParams.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (controller.isApplyingEffects.value) ...[
                    SizedBox(
                      width: 10.w,
                      height: 10.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor:
                            AlwaysStoppedAnimation(CutoutBurstColors.primary),
                      ),
                    ),
                    SizedBox(width: 6.w),
                  ],
                  Text(
                    'B:${params.brightness.toStringAsFixed(1)} C:${params.contrast.toStringAsFixed(1)} '
                    'R:${params.red.toStringAsFixed(1)} G:${params.green.toStringAsFixed(1)} B:${params.blue.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: CutoutBurstColors.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              );
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.isApplyingEffects.value) ...[
                  SizedBox(
                    width: 10.w,
                    height: 10.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor:
                          AlwaysStoppedAnimation(CutoutBurstColors.primary),
                    ),
                  ),
                  SizedBox(width: 6.w),
                ],
                Text(
                  controller.selectedTool.isEmpty
                      ? ''
                      : 'Tool: ${controller.selectedTool.value}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: CutoutBurstColors.primary,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
  Widget _buildImagePreview() {
    return Obx(() {
      final image = controller.processedImage.value;
      if (image == null) {
        return _buildLoadingPlaceholder();
      }
      return Stack(
        children: [
          _buildImageCanvas(image),
          if (controller.isApplyingEffects.value)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(24.h),
                      boxShadow: [
                        BoxShadow(
                          color: CutoutBurstColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(
                                CutoutBurstColors.primary),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Processing...',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
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
      ),
    );
  }
  Widget _buildImageCanvas(ui.Image image) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final rect = controller.calcImageDisplayRect(size);
          controller.updateImageDisplayRect(rect);
        });
        return Container(
          color: Colors.black,
          child: GestureDetector(
            onTapDown: (details) {
              if (controller.selectedTextId.value != null) {
                controller.onDeselectText();
              }
            },
            child: Stack(
              children: [
                Obx(() {
                  controller.textObjects.length;
                  return CustomPaint(
                    size: size,
                    painter: _EdgeTextPainter(
                      image: image,
                      imageDisplayRect: Rect.fromLTWH(
                        controller.imageDisplayLeft.value,
                        controller.imageDisplayTop.value,
                        controller.imageDisplayWidth.value,
                        controller.imageDisplayHeight.value,
                      ),
                      textObjects: controller.textObjects.toList(),
                      selectedTextId: controller.selectedTextId.value,
                      selectedEdge: controller.selectedEdge.value,
                    ),
                  );
                }),
                Obx(() => _buildGridOverlay()),
                Obx(() => _buildTextInteractionLayer()),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildTextInteractionLayer() {
    if (controller.textObjects.isEmpty) return const SizedBox.shrink();
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) {
          final tapPosition = details.localPosition;
          for (var i = controller.textObjects.length - 1; i >= 0; i--) {
            final textObj = controller.textObjects[i];
            if (_isPointInText(tapPosition, textObj)) {
              controller.onTextTap(textObj.id);
              return;
            }
          }
          controller.onDeselectText();
        },
        onScaleStart: (details) {
          controller.resetTextPinchGestures();
          final position = details.localFocalPoint;
          for (var i = controller.textObjects.length - 1; i >= 0; i--) {
            final textObj = controller.textObjects[i];
            if (_isPointInText(position, textObj)) {
              controller.onTextTap(textObj.id);
              controller.onTextHandleDragStart(textObj.id, 'move', position);
              return;
            }
          }
        },
        onScaleUpdate: (details) {
          final selectedId = controller.selectedTextId.value;
          if (selectedId == null) return;
          final isMultiFinger = details.scale != 1.0 || details.rotation != 0.0;
          if (isMultiFinger) {
            if (details.scale != 1.0) {
              controller.onTextPinchScale(selectedId, details.scale);
            }
            if (details.rotation.abs() > 0.01) {
              controller.onTextPinchRotate(selectedId, details.rotation);
            }
          } else {
            controller.onTextHandleDragUpdate(details.localFocalPoint);
          }
        },
        onScaleEnd: (details) {
          controller.onTextHandleDragEnd();
        },
      ),
    );
  }
  bool _isPointInText(Offset point, TextObject textObj) {
    final textWidth = textObj.content.length * 20.0 * textObj.scale;
    final textHeight = 40.0 * textObj.scale;
    final rect = Rect.fromCenter(
      center: textObj.position,
      width: textWidth,
      height: textHeight,
    );
    return rect.contains(point);
  }
  Widget _buildGridOverlay() {
    final rect = Rect.fromLTWH(
      controller.imageDisplayLeft.value,
      controller.imageDisplayTop.value,
      controller.imageDisplayWidth.value,
      controller.imageDisplayHeight.value,
    );
    if (rect.isEmpty) return const SizedBox.shrink();
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: IgnorePointer(
        child: CustomPaint(
          painter: _GridPainter(),
        ),
      ),
    );
  }
  Widget _buildSubToolbar() {
    return Container(
      height: 70.h,
      color: const Color(0xFF1A1A24),
      child: Obx(() {
        switch (controller.selectedTool.value) {
          case 'light':
            return _buildLightTools();
          case 'filter':
            return _buildFilterTools();
          case 'edge':
            return _buildEdgeTools();
          case 'text':
            return _buildTextTools();
          default:
            return const SizedBox.shrink();
        }
      }),
    );
  }
  Widget _buildLightTools() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      itemCount: 11,
      separatorBuilder: (_, __) => SizedBox(width: 4.w),
      itemBuilder: (_, i) {
        switch (i) {
          case 0:
            return _buildSubToolItem(
                Icons.refresh_rounded, 'Reset', controller.onLightReset);
          case 1:
            return _buildSubToolItem(Icons.brightness_low_rounded, 'Bright -',
                () => controller.onBrightnessAdjust(-0.05));
          case 2:
            return _buildSubToolItem(Icons.brightness_high_rounded, 'Bright +',
                () => controller.onBrightnessAdjust(0.05));
          case 3:
            return _buildSubToolItem(Icons.contrast_rounded, 'Contrast -',
                () => controller.onContrastAdjust(-0.05));
          case 4:
            return _buildSubToolItem(Icons.contrast_rounded, 'Contrast +',
                () => controller.onContrastAdjust(0.05));
          case 5:
            return _buildSubToolItem(
                Icons.circle, 'Red -', () => controller.onRedAdjust(-0.05),
                iconColor: Colors.red[400]);
          case 6:
            return _buildSubToolItem(
                Icons.circle, 'Red +', () => controller.onRedAdjust(0.05),
                iconColor: Colors.red[400]);
          case 7:
            return _buildSubToolItem(
                Icons.circle, 'Green -', () => controller.onGreenAdjust(-0.05),
                iconColor: Colors.green[400]);
          case 8:
            return _buildSubToolItem(
                Icons.circle, 'Green +', () => controller.onGreenAdjust(0.05),
                iconColor: Colors.green[400]);
          case 9:
            return _buildSubToolItem(
                Icons.circle, 'Blue -', () => controller.onBlueAdjust(-0.05),
                iconColor: Colors.blue[400]);
          case 10:
            return _buildSubToolItem(
                Icons.circle, 'Blue +', () => controller.onBlueAdjust(0.05),
                iconColor: Colors.blue[400]);
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
  Widget _buildFilterTools() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      itemCount: controller.filterLabels.length,
      separatorBuilder: (_, __) => SizedBox(width: 8.w),
      itemBuilder: (_, i) {
        return Obx(() {
          final isSelected = controller.selectedFilter.value == i;
          return GestureDetector(
            onTap: () => controller.onFilterSelect(i),
            child: Container(
              width: 56.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? CutoutBurstColors.primary.withOpacity(0.2)
                    : CutoutBurstColors.elevated,
                borderRadius: BorderRadius.circular(8.w),
                border: Border.all(
                  color: isSelected
                      ? CutoutBurstColors.primary
                      : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected
                          ? CutoutBurstColors.primaryGradient
                          : const LinearGradient(
                              colors: [Colors.grey, Colors.blueGrey]),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    controller.filterLabels[i],
                    style: TextStyle(
                      fontSize: 8.sp,
                      color: isSelected
                          ? CutoutBurstColors.primary
                          : Colors.white54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
  Widget _buildEdgeTools() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      itemCount: CutoutBurstEdgeTextLogic.edgeLabels.length,
      separatorBuilder: (_, __) => SizedBox(width: 8.w),
      itemBuilder: (_, i) {
        return Obx(() {
          final isSelected = controller.selectedEdge.value == i;
          return GestureDetector(
            onTap: () => controller.onEdgeSelect(i),
            child: Container(
              width: 56.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? CutoutBurstColors.primary.withOpacity(0.2)
                    : CutoutBurstColors.elevated,
                borderRadius: BorderRadius.circular(8.w),
                border: Border.all(
                  color: isSelected
                      ? CutoutBurstColors.primary
                      : CutoutBurstColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (i == 0)
                    Icon(
                      Icons.close_rounded,
                      size: 20.w,
                      color: isSelected
                          ? CutoutBurstColors.primary
                          : Colors.white38,
                    )
                  else
                    SizedBox(
                      width: 26.w,
                      height: 26.w,
                      child: CustomPaint(
                        painter: _EdgeShapePainter(
                          shapeIndex:
                              i - 1,
                          color: isSelected
                              ? CutoutBurstColors.primary
                              : Colors.white38,
                        ),
                      ),
                    ),
                  SizedBox(height: 4.h),
                  Text(
                    CutoutBurstEdgeTextLogic.edgeLabels[i],
                    style: TextStyle(
                      fontSize: 8.sp,
                      color: isSelected
                          ? CutoutBurstColors.primary
                          : Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
  Widget _buildTextTools() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      itemCount: 6 + controller.textColors.length,
      separatorBuilder: (_, __) => SizedBox(width: 4.w),
      itemBuilder: (_, i) {
        if (i == 0) {
          return _buildSubToolItem(
              Icons.add_rounded, 'Add Text', controller.onAddText);
        } else if (i == 1) {
          return _buildSubToolItem(
              Icons.shuffle_rounded, 'Random', controller.onRandomText);
        } else if (i == 2) {
          return _buildSubToolItem(
              Icons.edit_rounded, 'Edit', controller.onEditText);
        } else if (i == 3) {
          return _buildSubToolItem(Icons.text_increase_rounded, 'Spacing +',
              () => controller.onLetterSpacingAdjust(1.0));
        } else if (i == 4) {
          return _buildSubToolItem(Icons.text_decrease_rounded, 'Spacing -',
              () => controller.onLetterSpacingAdjust(-1.0));
        } else if (i == 5) {
          return _buildColorLabel();
        } else {
          final colorIndex = i - 6;
          return _buildColorPicker(controller.textColors[colorIndex]);
        }
      },
    );
  }
  Widget _buildColorLabel() {
    return Container(
      width: 60.w,
      padding: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        color: CutoutBurstColors.elevated,
        borderRadius: BorderRadius.circular(10.w),
      ),
      child: Center(
        child: Text(
          'Color',
          style: TextStyle(fontSize: 10.sp, color: Colors.white54),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
  Widget _buildColorPicker(Color color) {
    return GestureDetector(
      onTap: () => controller.onTextColorChange(color),
      child: Container(
        width: 40.w,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10.w),
          border: Border.all(color: Colors.white30, width: 1),
        ),
      ),
    );
  }
  Widget _buildHelpOverlay() {
    return GestureDetector(
      onTap: controller.onCloseHelp,
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Container(
            margin: EdgeInsets.all(24.w),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A24),
              borderRadius: BorderRadius.circular(16.w),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.help_outline_rounded,
                        size: 24.w, color: CutoutBurstColors.primary),
                    SizedBox(width: 8.w),
                    Text(
                      'How to Use',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: controller.onCloseHelp,
                      icon: Icon(Icons.close_rounded,
                          size: 24.w, color: Colors.white70),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                _buildHelpItem(
                    '1. Use Light to adjust brightness, contrast, and color'),
                _buildHelpItem('2. Apply Filters to change image style'),
                _buildHelpItem('3. Add Edge cutout for decorative borders'),
                _buildHelpItem('4. Add Border effects around image'),
                _buildHelpItem('5. Add Text - tap to select, drag to move'),
                _buildHelpItem('6. Two fingers to scale & rotate text'),
                _buildHelpItem('7. Move text far outside to delete it'),
                _buildHelpItem('8. Use Undo/Redo to manage changes'),
                SizedBox(height: 16.h),
                Center(
                  child: GestureDetector(
                    onTap: controller.onCloseHelp,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        gradient: CutoutBurstColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20.h),
                      ),
                      child: Text(
                        'Got it',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildHelpItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline,
              size: 16.w, color: CutoutBurstColors.primary),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13.sp, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSubToolItem(IconData icon, String label, VoidCallback? onTap,
      {Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60.w,
        padding: EdgeInsets.symmetric(vertical: 6.h),
        decoration: BoxDecoration(
          color: CutoutBurstColors.elevated,
          borderRadius: BorderRadius.circular(10.w),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18.w, color: iconColor ?? Colors.white70),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(fontSize: 8.sp, color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildMainToolbar() {
    final mainTools = [
      ('light', Icons.lightbulb_outline_rounded, 'Light'),
      ('filter', Icons.filter_rounded, 'Filter'),
      ('edge', Icons.favorite_border_rounded, 'Edge'),
      ('text', Icons.text_fields_rounded, 'Text'),
    ];
    return Container(
      height: 64.h,
      color: const Color(0xFF111118),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        itemCount: mainTools.length,
        separatorBuilder: (_, __) => SizedBox(width: 4.w),
        itemBuilder: (_, i) {
          return Obx(() {
            final isActive = controller.selectedTool.value == mainTools[i].$1;
            return GestureDetector(
              onTap: () => controller.onToolSelect(mainTools[i].$1),
              child: Container(
                width: 58.w,
                decoration: BoxDecoration(
                  color: isActive
                      ? CutoutBurstColors.primary.withOpacity(0.2)
                      : CutoutBurstColors.elevated,
                  borderRadius: BorderRadius.circular(10.w),
                  border: isActive
                      ? Border.all(
                          color: CutoutBurstColors.primary.withOpacity(0.5),
                        )
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      mainTools[i].$2,
                      size: 18.w,
                      color:
                          isActive ? CutoutBurstColors.primary : Colors.white70,
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      mainTools[i].$3,
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: isActive
                            ? CutoutBurstColors.primary
                            : Colors.white54,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }
}
class _EdgeTextPainter extends CustomPainter {
  final ui.Image image;
  final Rect imageDisplayRect;
  final List<TextObject> textObjects;
  final String? selectedTextId;
  final int selectedEdge;
  const _EdgeTextPainter({
    required this.image,
    required this.imageDisplayRect,
    required this.textObjects,
    this.selectedTextId,
    required this.selectedEdge,
  });
  void _drawCheckerboard(Canvas canvas, Size size) {
    const tileSize = 12.0;
    final cols = (size.width / tileSize).ceil() + 1;
    final rows = (size.height / tileSize).ceil() + 1;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final isLight = (row + col) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(col * tileSize, row * tileSize, tileSize, tileSize),
          Paint()
            ..color =
                isLight ? const Color(0xFFEEEEEE) : const Color(0xFFCCCCCC),
        );
      }
    }
  }
  @override
  void paint(Canvas canvas, Size size) {
    _drawCheckerboard(canvas, size);
    if (imageDisplayRect.isEmpty) return;
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    if (selectedEdge > 0) {
      canvas.drawRect(imageDisplayRect, Paint()..color = Colors.white);
      _drawImageClippedToShape(canvas, srcRect);
      _drawEdgePreview(canvas);
    } else {
      canvas.drawImageRect(image, srcRect, imageDisplayRect, Paint());
    }
    for (final textObj in textObjects) {
      _drawText(canvas, textObj, textObj.id == selectedTextId);
    }
  }
  void _drawImageClippedToShape(Canvas canvas, Rect srcRect) {
    final centerX = imageDisplayRect.left + imageDisplayRect.width / 2;
    final centerY = imageDisplayRect.top + imageDisplayRect.height / 2;
    final pathSize = (imageDisplayRect.width + imageDisplayRect.height) / 2;
    final shapeIndex = selectedEdge - 1;
    canvas.save();
    canvas.translate(centerX, centerY);
    final path = _getEdgeShapePath(shapeIndex, pathSize * 0.95);
    canvas.clipPath(path);
    canvas.translate(-centerX, -centerY);
    canvas.drawImageRect(image, srcRect, imageDisplayRect, Paint());
    canvas.restore();
  }
  void _drawEdgePreview(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    final shapeIndex = selectedEdge - 1;
    final centerX = imageDisplayRect.left + imageDisplayRect.width / 2;
    final centerY = imageDisplayRect.top + imageDisplayRect.height / 2;
    canvas.save();
    canvas.translate(centerX, centerY);
    final pathSize = (imageDisplayRect.width + imageDisplayRect.height) / 2;
    final path = _getEdgeShapePath(shapeIndex, pathSize * 0.95);
    canvas.drawPath(path, paint);
    canvas.restore();
  }
  Path _getEdgeShapePath(int shapeIndex, double size) {
    final imageAspect = imageDisplayRect.width / imageDisplayRect.height;
    switch (shapeIndex) {
      case 0:
        return _createEdgeZigzagCircle(size, imageAspect);
      case 1:
        return _createEdgeWaveCircle(size, imageAspect);
      case 2:
        return _createEdgeGearCircle(size, imageAspect);
      case 3:
        return _createEdgeRoundedRect(
            imageDisplayRect.width, imageDisplayRect.height, 30);
      case 4:
        return Path()
          ..addRect(Rect.fromCenter(
            center: Offset.zero,
            width: imageDisplayRect.width - 12,
            height: imageDisplayRect.height - 12,
          ));
      case 5:
        return _createEdgeRoundedRect(
            imageDisplayRect.width, imageDisplayRect.height, 50);
      case 6:
        return _createEdgeStar(size * 0.5, 5);
      case 7:
        return _createEdgeHeart(size * 1);
      case 8:
        return _createEdgeDiamond(size * 0.5);
      default:
        return Path()
          ..addOval(Rect.fromCenter(
            center: Offset.zero,
            width: size,
            height: size,
          ));
    }
  }
  Path _createEdgeZigzagCircle(double size, double aspect) {
    final path = Path();
    final radiusX = size / 2 * 0.9;
    final radiusY = radiusX / aspect;
    final teeth = 36;
    final angleStep = (2 * pi) / teeth;
    for (var i = 0; i <= teeth; i++) {
      final angle = i * angleStep;
      final scale = i % 2 == 0 ? 1.0 : 0.92;
      final x = cos(angle) * radiusX * scale;
      final y = sin(angle) * radiusY * scale;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
  Path _createEdgeWaveCircle(double size, double aspect) {
    final path = Path();
    final radiusX = size / 2 * 0.9;
    final radiusY = radiusX / aspect;
    final waves = 16;
    final angleStep = (2 * pi) / (waves * 4);
    for (var i = 0; i <= waves * 4; i++) {
      final angle = i * angleStep;
      final waveOffset = sin(i * pi / 2) * 0.06;
      final x = cos(angle) * radiusX * (1 + waveOffset);
      final y = sin(angle) * radiusY * (1 + waveOffset);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
  Path _createEdgeGearCircle(double size, double aspect) {
    final path = Path();
    final radiusX = size / 2 * 0.9;
    final radiusY = radiusX / aspect;
    final teeth = 16;
    final angleStep = (2 * pi) / teeth;
    for (var i = 0; i < teeth; i++) {
      final angle1 = i * angleStep;
      final angle2 = angle1 + angleStep / 3;
      final angle3 = angle1 + angleStep * 2 / 3;
      path.lineTo(cos(angle1) * radiusX * 0.85, sin(angle1) * radiusY * 0.85);
      path.lineTo(cos(angle2) * radiusX, sin(angle2) * radiusY);
      path.lineTo(cos(angle3) * radiusX, sin(angle3) * radiusY);
    }
    path.close();
    return path;
  }
  Path _createEdgeRoundedRect(double width, double height, double radius) {
    final path = Path();
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: width - 12,
      height: height - 12,
    );
    path.addRRect(RRect.fromRectAndRadius(
      rect,
      Radius.circular(radius),
    ));
    return path;
  }
  Path _createEdgeStar(double size, int points) {
    final path = Path();
    final outerRadius = size;
    final innerRadius = outerRadius * 0.45;
    final angleStep = pi / points;
    for (var i = 0; i < points * 2; i++) {
      final angle = i * angleStep - pi / 2;
      final radius = i % 2 == 0 ? outerRadius : innerRadius;
      final x = cos(angle) * radius;
      final y = sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
  Path _createEdgeHeart(double size) {
    final path = Path();
    final scale = size / 100;
    path.moveTo(0, 25 * scale);
    path.cubicTo(
      -50 * scale,
      -15 * scale,
      -50 * scale,
      -40 * scale,
      -25 * scale,
      -40 * scale,
    );
    path.cubicTo(
      0,
      -40 * scale,
      0,
      -25 * scale,
      0,
      -25 * scale,
    );
    path.cubicTo(
      0,
      -25 * scale,
      0,
      -40 * scale,
      25 * scale,
      -40 * scale,
    );
    path.cubicTo(
      50 * scale,
      -40 * scale,
      50 * scale,
      -15 * scale,
      0,
      25 * scale,
    );
    path.close();
    return path;
  }
  Path _createEdgeDiamond(double size) {
    final path = Path();
    path.moveTo(0, -size);
    path.lineTo(size, 0);
    path.lineTo(0, size);
    path.lineTo(-size, 0);
    path.close();
    return path;
  }
  void _drawText(Canvas canvas, TextObject textObj, bool isSelected) {
    canvas.save();
    canvas.translate(textObj.position.dx, textObj.position.dy);
    canvas.rotate(textObj.rotation);
    canvas.scale(textObj.scale);
    final textSpan = TextSpan(
      text: textObj.content,
      style: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: textObj.color,
        letterSpacing: textObj.letterSpacing,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    if (isSelected) {
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: textPainter.width + 20,
        height: textPainter.height + 20,
      );
      final borderPaint = Paint()
        ..color = CutoutBurstColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(rect, borderPaint);
      final handlePaint = Paint()..color = CutoutBurstColors.primary;
      final handleSize = 8.0;
      canvas.drawCircle(rect.topLeft, handleSize, handlePaint);
      canvas.drawCircle(rect.topRight, handleSize, handlePaint);
      canvas.drawCircle(rect.bottomLeft, handleSize, handlePaint);
      canvas.drawCircle(rect.bottomRight, handleSize, handlePaint);
    }
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _EdgeTextPainter oldDelegate) => true;
}
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    final cellWidth = size.width / 3;
    final cellHeight = size.height / 3;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(cellWidth * i, 0),
        Offset(cellWidth * i, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, cellHeight * i),
        Offset(size.width, cellHeight * i),
        paint,
      );
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
class _EdgeShapePainter extends CustomPainter {
  final int shapeIndex;
  final Color color;
  const _EdgeShapePainter({
    required this.shapeIndex,
    required this.color,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = _getShapePath(shapeIndex, size.width * 0.9);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.drawPath(path, paint);
  }
  Path _getShapePath(int shapeIndex, double size) {
    final path = Path();
    switch (shapeIndex) {
      case 0:
        return _createZigzagCircle(size);
      case 1:
        return _createWaveCircle(size);
      case 2:
        return _createGearCircle(size);
      case 3:
        return _createRoundedRect(size, 3);
      case 4:
        path.addRect(Rect.fromCenter(
          center: Offset.zero,
          width: size,
          height: size * 0.7,
        ));
        return path;
      case 5:
        return _createRoundedRect(size, 5);
      case 6:
        return _createStar(size, 5);
      case 7:
        return _createHeart(size);
      case 8:
        return _createDiamond(size);
      default:
        path.addOval(Rect.fromCenter(
          center: Offset.zero,
          width: size,
          height: size,
        ));
        return path;
    }
  }
  Path _createZigzagCircle(double size) {
    final path = Path();
    final radius = size / 2;
    final teeth = 12;
    final angleStep = (2 * 3.14159) / teeth;
    for (var i = 0; i <= teeth; i++) {
      final angle = i * angleStep;
      final r = i % 2 == 0 ? radius : radius * 0.85;
      final x = cos(angle) * r;
      final y = sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
  Path _createWaveCircle(double size) {
    final path = Path();
    final radius = size / 2;
    final waves = 8;
    final angleStep = (2 * 3.14159) / (waves * 4);
    for (var i = 0; i <= waves * 4; i++) {
      final angle = i * angleStep;
      final waveOffset = sin(i * 3.14159 / 2) * radius * 0.1;
      final r = radius + waveOffset;
      final x = cos(angle) * r;
      final y = sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
  Path _createGearCircle(double size) {
    final path = Path();
    final radius = size / 2;
    final teeth = 8;
    final angleStep = (2 * 3.14159) / teeth;
    for (var i = 0; i < teeth; i++) {
      final angle1 = i * angleStep;
      final angle2 = angle1 + angleStep / 3;
      final angle3 = angle1 + angleStep * 2 / 3;
      path.lineTo(cos(angle1) * radius * 0.8, sin(angle1) * radius * 0.8);
      path.lineTo(cos(angle2) * radius, sin(angle2) * radius);
      path.lineTo(cos(angle3) * radius, sin(angle3) * radius);
    }
    path.close();
    return path;
  }
  Path _createRoundedRect(double size, double cornerRadius) {
    final path = Path();
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size,
      height: size * 0.7,
    );
    path.addRRect(RRect.fromRectAndRadius(
      rect,
      Radius.circular(cornerRadius),
    ));
    return path;
  }
  Path _createStar(double size, int points) {
    final path = Path();
    final outerRadius = size / 2;
    final innerRadius = outerRadius * 0.4;
    final angleStep = 3.14159 / points;
    for (var i = 0; i < points * 2; i++) {
      final angle = i * angleStep - 3.14159 / 2;
      final radius = i % 2 == 0 ? outerRadius : innerRadius;
      final x = cos(angle) * radius;
      final y = sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
  Path _createHeart(double size) {
    final path = Path();
    final scale = size / 100;
    path.moveTo(0, 15 * scale);
    path.cubicTo(
      -40 * scale,
      -15 * scale,
      -40 * scale,
      -35 * scale,
      -20 * scale,
      -35 * scale,
    );
    path.cubicTo(
      0,
      -35 * scale,
      0,
      -20 * scale,
      0,
      -20 * scale,
    );
    path.cubicTo(
      0,
      -20 * scale,
      0,
      -35 * scale,
      20 * scale,
      -35 * scale,
    );
    path.cubicTo(
      40 * scale,
      -35 * scale,
      40 * scale,
      -15 * scale,
      0,
      15 * scale,
    );
    path.close();
    return path;
  }
  Path _createDiamond(double size) {
    final path = Path();
    final half = size / 2;
    path.moveTo(0, -half);
    path.lineTo(half, 0);
    path.lineTo(0, half);
    path.lineTo(-half, 0);
    path.close();
    return path;
  }
  @override
  bool shouldRepaint(covariant _EdgeShapePainter oldDelegate) =>
      shapeIndex != oldDelegate.shapeIndex || color != oldDelegate.color;
}
