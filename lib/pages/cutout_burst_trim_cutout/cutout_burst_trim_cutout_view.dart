import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import 'cutout_burst_trim_cutout_logic.dart';
class CutoutBurstTrimCutoutView extends GetView<CutoutBurstTrimCutoutLogic> {
  const CutoutBurstTrimCutoutView({super.key});
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildColorPaletteBar(),
            Expanded(child: _buildImageCanvas()),
            _buildBottomPanel(),
          ],
        ),
      ),
    );
  }
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Trim Cutout',
      ),
      actions: [
        _buildIconBtn(Icons.restore, controller.onFitScreen),
        _buildIconBtn(Icons.remove_rounded, controller.onZoomOut),
        _buildIconBtn(Icons.add_rounded, controller.onZoomIn),
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
  Widget _buildIconBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      padding: EdgeInsets.all(6.w),
      constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.w),
      icon: Icon(icon, size: 20.w, color: Colors.white70),
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
            onTap: controller.onShowHelp,
            child: Icon(Icons.info_outline_rounded,
                size: 18.w, color: Colors.white54),
          ),
          SizedBox(width: 8.w),
          Text(
            'Background:',
            style: TextStyle(fontSize: 12.sp, color: Colors.white60),
          ),
          SizedBox(width: 10.w),
          ...CutoutBurstTrimCutoutLogic.bgColors.map((c) => _buildColorDot(c)),
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
          width: 32.w,
          height: 22.w,
          margin: EdgeInsets.only(right: 8.w),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16.w),
            border: Border.all(
              color: isSelected ? CutoutBurstColors.primary : Colors.white30,
              width: isSelected ? 2 : 1,
            ),
          ),
        ),
      );
    });
  }
  Widget _buildImageCanvas() {
    return Obx(() {
      final image = controller.uiImage.value;
      if (image == null) {
        return _buildNoImagePlaceholder();
      }
      return _buildDrawingArea(image);
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
  Widget _buildDrawingArea(ui.Image image) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final rect = controller.calcImageDisplayRect(size);
        controller.updateImageDisplayRect(rect);
      });
      return Stack(
        children: [
          Obx(() {
            final isPanMode = controller.isPanMode.value;
            return InteractiveViewer(
              transformationController: controller.transformationController,
              panEnabled: isPanMode,
              scaleEnabled: true,
              minScale: 0.5,
              maxScale: 5.0,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: GestureDetector(
                  onPanStart: isPanMode
                      ? null
                      : (d) => controller.onDrawStart(d.localPosition),
                  onPanUpdate: isPanMode
                      ? null
                      : (d) => controller.onDrawUpdate(d.localPosition),
                  onPanEnd: isPanMode ? null : (_) => controller.onDrawEnd(),
                  onTapDown: isPanMode
                      ? null
                      : (d) {
                          controller.onDrawStart(d.localPosition);
                          controller.onDrawEnd();
                        },
                  child: Obx(() {
                    controller.strokes.length;
                    return CustomPaint(
                      size: size,
                      painter: _TrimPainter(
                        image: image,
                        strokes: controller.strokes
                            .toList(),
                        bgColor: controller.selectedBgColor.value,
                        imageDisplayRect: Rect.fromLTWH(
                          controller.imageDisplayLeft.value,
                          controller.imageDisplayTop.value,
                          controller.imageDisplayWidth.value,
                          controller.imageDisplayHeight.value,
                        ),
                        currentStroke: controller.currentStroke.value,
                      ),
                    );
                  }),
                ),
              ),
            );
          }),
        ],
      );
    });
  }
  Widget _buildBottomPanel() {
    return Container(
      color: const Color(0xFF111118),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTrimToolbar(),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }
  Widget _buildTrimToolbar() {
    return SizedBox(
      height: 70.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        children: [
          Obx(() => _buildToggleTool(
                icon: Icons.pan_tool_outlined,
                label: 'Move',
                isActive: controller.isPanMode.value,
                onTap: controller.togglePanMode,
              )),
          SizedBox(width: 4.w),
          Obx(() => _buildToggleTool(
                icon: Icons.add_circle_outline,
                label: 'Add',
                isActive: !controller.isPanMode.value &&
                    controller.currentTool.value == TrimTool.add,
                onTap: () {
                  controller.isPanMode.value = false;
                  controller.currentTool.value = TrimTool.add;
                },
              )),
          SizedBox(width: 4.w),
          Obx(() => _buildToggleTool(
                icon: Icons.remove_circle_outline,
                label: 'Subtract',
                isActive: !controller.isPanMode.value &&
                    controller.currentTool.value == TrimTool.subtract,
                onTap: () {
                  controller.isPanMode.value = false;
                  controller.currentTool.value = TrimTool.subtract;
                },
              )),
          SizedBox(width: 4.w),
          Obx(() => _buildToggleTool(
                icon: Icons.add_rounded,
                label: 'Restore',
                isActive: !controller.isPanMode.value &&
                    controller.currentTool.value == TrimTool.restore,
                onTap: () {
                  controller.isPanMode.value = false;
                  controller.currentTool.value = TrimTool.restore;
                },
              )),
          SizedBox(width: 4.w),
          Obx(() => _buildToggleTool(
                icon: Icons.remove_rounded,
                label: 'Erase',
                isActive: !controller.isPanMode.value &&
                    controller.currentTool.value == TrimTool.erase,
                onTap: () {
                  controller.isPanMode.value = false;
                  controller.currentTool.value = TrimTool.erase;
                },
              )),
          SizedBox(width: 4.w),
          Obx(() => _buildActionTool(
                icon: Icons.undo_rounded,
                label: 'Undo',
                enabled: controller.canUndo,
                onTap: controller.onUndo,
              )),
          SizedBox(width: 4.w),
          Obx(() => _buildActionTool(
                icon: Icons.redo_rounded,
                label: 'Redo',
                enabled: controller.canRedo,
                onTap: controller.onRedo,
              )),
          SizedBox(width: 4.w),
          _buildToolItem(Icons.help_outline_rounded, 'Help',
              onTap: controller.onShowHelp),
        ],
      ),
    );
  }
  Widget _buildToggleTool({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52.w,
        padding: EdgeInsets.symmetric(vertical: 6.h),
        decoration: BoxDecoration(
          color: isActive
              ? CutoutBurstColors.primary.withOpacity(0.25)
              : CutoutBurstColors.elevated,
          borderRadius: BorderRadius.circular(10.w),
          border: isActive
              ? Border.all(
                  color: CutoutBurstColors.primary.withOpacity(0.5),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18.w,
              color: isActive ? CutoutBurstColors.primary : Colors.white70,
            ),
            SizedBox(height: 3.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 8.sp,
                color: isActive ? CutoutBurstColors.primary : Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildActionTool({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 52.w,
        padding: EdgeInsets.symmetric(vertical: 6.h),
        decoration: BoxDecoration(
          color: CutoutBurstColors.elevated,
          borderRadius: BorderRadius.circular(10.w),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18.w,
              color: enabled ? Colors.white70 : Colors.white24,
            ),
            SizedBox(height: 3.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 8.sp,
                color: enabled ? Colors.white54 : Colors.white24,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildToolItem(IconData icon, String label,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52.w,
        padding: EdgeInsets.symmetric(vertical: 6.h),
        decoration: BoxDecoration(
          color: CutoutBurstColors.elevated,
          borderRadius: BorderRadius.circular(10.w),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18.w, color: Colors.white70),
            SizedBox(height: 3.h),
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
}
class _TrimPainter extends CustomPainter {
  final ui.Image image;
  final List<TrimStroke> strokes;
  final Color bgColor;
  final Rect imageDisplayRect;
  final TrimStroke? currentStroke;
  const _TrimPainter({
    required this.image,
    required this.strokes,
    required this.bgColor,
    required this.imageDisplayRect,
    this.currentStroke,
  });
  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawImageWithStrokes(canvas, size);
    _drawPreviewStroke(canvas, size);
  }
  void _drawBackground(Canvas canvas, Size size) {
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
  void _drawImageWithStrokes(Canvas canvas, Size size) {
    Rect dstRect = imageDisplayRect;
    if (dstRect.width <= 0 || dstRect.height <= 0) {
      final scale = min(size.width / image.width, size.height / image.height);
      final w = image.width * scale;
      final h = image.height * scale;
      dstRect = Rect.fromLTWH(
        (size.width - w) / 2,
        (size.height - h) / 2,
        w,
        h,
      );
    }
    final srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(
      dstRect,
      Paint()..color = bgColor.withOpacity(0.7),
    );
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      _applyStroke(canvas, stroke, size, dstRect);
    }
    canvas.restore();
  }
  void _applyStroke(
    Canvas canvas,
    TrimStroke stroke,
    Size size,
    Rect dstRect,
  ) {
    switch (stroke.tool) {
      case TrimTool.add:
        _applyManualBrush(canvas, stroke, reveal: true);
        if (stroke.regionSegments != null &&
            stroke.regionSegments!.isNotEmpty) {
          debugPrint(
              '🎨 Drawing Add region: ${stroke.regionSegments!.length} segments');
          _applyRegionSegments(canvas, stroke.regionSegments!, reveal: true);
        } else {
          debugPrint('⚠️ No region segments for Add stroke');
        }
        break;
      case TrimTool.subtract:
        _applyManualBrush(canvas, stroke, reveal: false);
        if (stroke.regionSegments != null &&
            stroke.regionSegments!.isNotEmpty) {
          debugPrint(
              '🎨 Drawing Subtract region: ${stroke.regionSegments!.length} segments');
          _applyRegionSegments(canvas, stroke.regionSegments!, reveal: false);
        } else {
          debugPrint('⚠️ No region segments for Subtract stroke');
        }
        break;
      case TrimTool.restore:
        _applyManualBrush(canvas, stroke, reveal: true);
        break;
      case TrimTool.erase:
        _applyManualBrush(canvas, stroke, reveal: false);
        break;
    }
  }
  void _applyRegionSegments(Canvas canvas, List<RowSegment> regionSegments,
      {required bool reveal}) {
    if (regionSegments.isEmpty) return;
    final paint = Paint()
      ..blendMode = reveal ? BlendMode.clear : BlendMode.srcOver
      ..color =
          reveal ? Colors.transparent : bgColor.withOpacity(1.0)
      ..style = PaintingStyle.fill;
    for (final segment in regionSegments) {
      final y = segment.y.toDouble();
      final left = segment.left.toDouble();
      final right = segment.right.toDouble();
      canvas.drawRect(
        Rect.fromLTRB(left, y, right + 1, y + 1),
        paint,
      );
    }
  }
  void _applyManualBrush(Canvas canvas, TrimStroke stroke,
      {required bool reveal}) {
    final isErase = stroke.tool == TrimTool.erase;
    final paint = Paint()
      ..blendMode = reveal
          ? BlendMode.clear
          : (isErase ? BlendMode.dstOver : BlendMode.srcOver)
      ..color = reveal ? Colors.transparent : bgColor.withOpacity(0.7)
      ..strokeWidth = stroke.brushSize
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points[0], stroke.brushSize / 2, paint);
    } else {
      final path = Path()..moveTo(stroke.points[0].dx, stroke.points[0].dy);
      for (var i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }
  void _drawPreviewStroke(Canvas canvas, Size size) {
    if (currentStroke == null || currentStroke!.points.isEmpty) return;
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.85)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (currentStroke!.points.length == 1) {
      canvas.drawCircle(currentStroke!.points[0], 1.5, paint);
    } else {
      final path = Path()
        ..moveTo(currentStroke!.points[0].dx, currentStroke!.points[0].dy);
      for (var i = 1; i < currentStroke!.points.length; i++) {
        path.lineTo(currentStroke!.points[i].dx, currentStroke!.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _TrimPainter old) => true;
}
