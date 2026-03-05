import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import 'cutout_burst_shape_cutout_logic.dart';
class CutoutBurstShapeCutoutView extends GetView<CutoutBurstShapeCutoutLogic> {
  const CutoutBurstShapeCutoutView({super.key});
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
                Expanded(child: _buildImageArea()),
                _buildShapeLibrary(),
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
      backgroundColor: const Color(0xFF111118),
      elevation: 0,
      leading: IconButton(
        onPressed: controller.onBackTap,
        icon:
            Icon(Icons.arrow_back_ios_rounded, size: 20.w, color: Colors.white),
      ),
      title: const Text('Shape Cutout'),
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
  Widget _buildImageArea() {
    return Obx(() {
      final image = controller.uiImage.value;
      if (image == null) {
        return _buildLoadingPlaceholder();
      }
      return _buildImageCanvas(image);
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
              if (controller.selectedShapeId.value != null) {
                controller.onDeselectShape();
              }
            },
            child: Stack(
              children: [
                Obx(() {
                  controller.shapes.length;
                  controller.freePaths.length;
                  return CustomPaint(
                    size: size,
                    painter: _ShapeCutoutPainter(
                      image: image,
                      imageDisplayRect: Rect.fromLTWH(
                        controller.imageDisplayLeft.value,
                        controller.imageDisplayTop.value,
                        controller.imageDisplayWidth.value,
                        controller.imageDisplayHeight.value,
                      ),
                      shapes: controller.shapes.toList(),
                      freePaths: controller.freePaths.toList(),
                      selectedShapeId: controller.selectedShapeId.value,
                      currentDrawPoints: controller.currentDrawPoints.toList(),
                    ),
                  );
                }),
                Obx(() => _buildGridOverlay()),
                Obx(() => _buildShapeInteractionLayer()),
              ],
            ),
          ),
        );
      },
    );
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
  Widget _buildShapeInteractionLayer() {
    if (controller.shapes.isEmpty) return const SizedBox.shrink();
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) {
          final tapPosition = details.localPosition;
          for (var i = controller.shapes.length - 1; i >= 0; i--) {
            final shape = controller.shapes[i];
            if (_isPointInShape(tapPosition, shape)) {
              controller.onShapeTap(shape.id);
              return;
            }
          }
          controller.onDeselectShape();
        },
        onScaleStart: (details) {
          controller.resetPinchGestures();
          final position = details.localFocalPoint;
          for (var i = controller.shapes.length - 1; i >= 0; i--) {
            final shape = controller.shapes[i];
            if (_isPointInShape(position, shape)) {
              controller.onShapeTap(shape.id);
              controller.onHandleDragStart(shape.id, 'move', position);
              return;
            }
          }
        },
        onScaleUpdate: (details) {
          final selectedId = controller.selectedShapeId.value;
          if (selectedId == null) return;
          final isMultiFinger = details.scale != 1.0 || details.rotation != 0.0;
          if (isMultiFinger) {
            if (details.scale != 1.0) {
              controller.onPinchScale(selectedId, details.scale);
            }
            if (details.rotation.abs() > 0.01) {
              controller.onPinchRotate(selectedId, details.rotation);
            }
          } else {
            controller.onHandleDragUpdate(details.localFocalPoint);
          }
        },
        onScaleEnd: (details) {
          controller.onHandleDragEnd();
        },
      ),
    );
  }
  bool _isPointInShape(Offset point, ShapeObject shape) {
    final baseSize = 100.0 * shape.scale;
    final distance = (point - shape.position).distance;
    return distance <= baseSize / 2;
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
                _buildHelpItem('1. Tap a shape to add it to the image'),
                _buildHelpItem('2. Tap shape to select'),
                _buildHelpItem('3. One finger to drag and move'),
                _buildHelpItem('4. Two fingers to pinch scale & rotate'),
                _buildHelpItem('5. Move shape outside to delete it'),
                _buildHelpItem('6. Use Undo/Redo to manage changes'),
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
  Widget _buildShapeLibrary() {
    return Container(
      height: 80.h,
      color: const Color(0xFF111118),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        itemCount: CutoutBurstShapeCutoutLogic.shapeLabels.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          return Obx(() {
            final isSelected = controller.selectedShapeIndex.value == i;
            return GestureDetector(
              onTap: () => controller.onShapeSelect(i),
              child: Container(
                width: 56.w,
                decoration: BoxDecoration(
                  color: isSelected
                      ? CutoutBurstColors.primary.withOpacity(0.2)
                      : CutoutBurstColors.elevated,
                  borderRadius: BorderRadius.circular(10.w),
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
                    SizedBox(
                      width: 26.w,
                      height: 26.w,
                      child: CustomPaint(
                        painter: _ShapeThumbnailPainter(
                          shapeIndex: i,
                          color: isSelected
                              ? CutoutBurstColors.primary
                              : Colors.white38,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      CutoutBurstShapeCutoutLogic.shapeLabels[i],
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
      ),
    );
  }
}
class _ShapeCutoutPainter extends CustomPainter {
  final ui.Image image;
  final Rect imageDisplayRect;
  final List<ShapeObject> shapes;
  final List<FreeDrawPath> freePaths;
  final String? selectedShapeId;
  final List<Offset> currentDrawPoints;
  const _ShapeCutoutPainter({
    required this.image,
    required this.imageDisplayRect,
    required this.shapes,
    required this.freePaths,
    this.selectedShapeId,
    required this.currentDrawPoints,
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
    canvas.drawImageRect(image, srcRect, imageDisplayRect, Paint());
    canvas.saveLayer(imageDisplayRect, Paint());
    canvas.drawRect(
      imageDisplayRect,
      Paint()..color = Colors.black.withOpacity(0.5),
    );
    for (final shape in shapes) {
      _clearShapeArea(canvas, shape);
    }
    for (final path in freePaths) {
      _clearFreePathArea(canvas, path);
    }
    canvas.restore();
    for (final shape in shapes) {
      _drawShapeOutline(canvas, shape, shape.id == selectedShapeId);
    }
    for (final path in freePaths) {
      _drawFreePathOutline(canvas, path);
    }
    if (currentDrawPoints.isNotEmpty) {
      _drawCurrentPath(canvas, currentDrawPoints);
    }
  }
  void _clearShapeArea(Canvas canvas, ShapeObject shape) {
    final baseSize = 100.0 * shape.scale;
    canvas.save();
    canvas.translate(shape.position.dx, shape.position.dy);
    canvas.rotate(shape.rotation);
    final path = _getShapePath(shape.shapeIndex, baseSize);
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, clearPaint);
    canvas.restore();
  }
  void _drawShapeOutline(Canvas canvas, ShapeObject shape, bool isSelected) {
    final baseSize = 100.0 * shape.scale;
    canvas.save();
    canvas.translate(shape.position.dx, shape.position.dy);
    canvas.rotate(shape.rotation);
    final path = _getShapePath(shape.shapeIndex, baseSize);
    final outlinePaint = Paint()
      ..color = isSelected
          ? CutoutBurstColors.primary.withOpacity(0.9)
          : Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3 : 2;
    canvas.drawPath(path, outlinePaint);
    canvas.restore();
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
        return _createRoundedRect(size, 20);
      case 4:
        path.addRect(Rect.fromCenter(
          center: Offset.zero,
          width: size,
          height: size * 0.7,
        ));
        return path;
      case 5:
        return _createRoundedRect(size, 30);
      case 6:
        return _createStar(size, 5);
      case 7:
        return _createHeart(size);
      case 8:
        return _createDiamond(size);
      case 9:
        return _createArrow(size);
      case 10:
        return _createCloud(size);
      case 11:
        return _createFlower(size);
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
    final teeth = 24;
    final angleStep = (2 * pi) / teeth;
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
    final waves = 12;
    final angleStep = (2 * pi) / (waves * 4);
    for (var i = 0; i <= waves * 4; i++) {
      final angle = i * angleStep;
      final waveOffset = sin(i * pi / 2) * radius * 0.1;
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
    final teeth = 12;
    final angleStep = (2 * pi) / teeth;
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
  Path _createHeart(double size) {
    final path = Path();
    final scale = size / 100;
    path.moveTo(0, 20 * scale);
    path.cubicTo(
      -50 * scale,
      -20 * scale,
      -50 * scale,
      -50 * scale,
      -25 * scale,
      -50 * scale,
    );
    path.cubicTo(
      0,
      -50 * scale,
      0,
      -30 * scale,
      0,
      -30 * scale,
    );
    path.cubicTo(
      0,
      -30 * scale,
      0,
      -50 * scale,
      25 * scale,
      -50 * scale,
    );
    path.cubicTo(
      50 * scale,
      -50 * scale,
      50 * scale,
      -20 * scale,
      0,
      20 * scale,
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
  Path _createArrow(double size) {
    final path = Path();
    final scale = size / 100;
    path.moveTo(50 * scale, 0);
    path.lineTo(10 * scale, -30 * scale);
    path.lineTo(10 * scale, -10 * scale);
    path.lineTo(-50 * scale, -10 * scale);
    path.lineTo(-50 * scale, 10 * scale);
    path.lineTo(10 * scale, 10 * scale);
    path.lineTo(10 * scale, 30 * scale);
    path.close();
    return path;
  }
  Path _createCloud(double size) {
    final path = Path();
    final scale = size / 120;
    path.addOval(
        Rect.fromCircle(center: Offset(-20 * scale, 0), radius: 25 * scale));
    path.addOval(
        Rect.fromCircle(center: Offset(0, -10 * scale), radius: 30 * scale));
    path.addOval(
        Rect.fromCircle(center: Offset(20 * scale, 0), radius: 25 * scale));
    path.addOval(Rect.fromCircle(
        center: Offset(10 * scale, 15 * scale), radius: 20 * scale));
    path.addOval(Rect.fromCircle(
        center: Offset(-10 * scale, 15 * scale), radius: 20 * scale));
    return path;
  }
  Path _createFlower(double size) {
    final path = Path();
    final petalCount = 8;
    final radius = size / 2;
    final petalRadius = radius * 0.5;
    for (var i = 0; i < petalCount; i++) {
      final angle = (i * 2 * pi) / petalCount;
      final centerX = cos(angle) * radius * 0.5;
      final centerY = sin(angle) * radius * 0.5;
      path.addOval(Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: petalRadius,
      ));
    }
    path.addOval(Rect.fromCircle(center: Offset.zero, radius: radius * 0.3));
    return path;
  }
  void _clearFreePathArea(Canvas canvas, FreeDrawPath path) {
    if (path.points.isEmpty) return;
    final pathObj = Path()..moveTo(path.points[0].dx, path.points[0].dy);
    for (var i = 1; i < path.points.length; i++) {
      pathObj.lineTo(path.points[i].dx, path.points[i].dy);
    }
    pathObj.close();
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;
    canvas.drawPath(pathObj, clearPaint);
  }
  void _drawFreePathOutline(Canvas canvas, FreeDrawPath path) {
    if (path.points.isEmpty) return;
    final pathObj = Path()..moveTo(path.points[0].dx, path.points[0].dy);
    for (var i = 1; i < path.points.length; i++) {
      pathObj.lineTo(path.points[i].dx, path.points[i].dy);
    }
    pathObj.close();
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(pathObj, paint);
  }
  void _drawCurrentPath(Canvas canvas, List<Offset> points) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant _ShapeCutoutPainter oldDelegate) => true;
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
class _ShapeThumbnailPainter extends CustomPainter {
  final int shapeIndex;
  final Color color;
  const _ShapeThumbnailPainter({
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
      case 9:
        return _createArrow(size);
      case 10:
        return _createCloud(size);
      case 11:
        return _createFlower(size);
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
    final angleStep = (2 * pi) / teeth;
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
    final angleStep = (2 * pi) / (waves * 4);
    for (var i = 0; i <= waves * 4; i++) {
      final angle = i * angleStep;
      final waveOffset = sin(i * pi / 2) * radius * 0.1;
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
    final angleStep = (2 * pi) / teeth;
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
  Path _createArrow(double size) {
    final path = Path();
    final scale = size / 100;
    path.moveTo(40 * scale, 0);
    path.lineTo(10 * scale, -25 * scale);
    path.lineTo(10 * scale, -10 * scale);
    path.lineTo(-40 * scale, -10 * scale);
    path.lineTo(-40 * scale, 10 * scale);
    path.lineTo(10 * scale, 10 * scale);
    path.lineTo(10 * scale, 25 * scale);
    path.close();
    return path;
  }
  Path _createCloud(double size) {
    final path = Path();
    final scale = size / 120;
    path.addOval(
        Rect.fromCircle(center: Offset(-15 * scale, 0), radius: 18 * scale));
    path.addOval(
        Rect.fromCircle(center: Offset(0, -8 * scale), radius: 20 * scale));
    path.addOval(
        Rect.fromCircle(center: Offset(15 * scale, 0), radius: 18 * scale));
    path.addOval(Rect.fromCircle(
        center: Offset(8 * scale, 10 * scale), radius: 15 * scale));
    path.addOval(Rect.fromCircle(
        center: Offset(-8 * scale, 10 * scale), radius: 15 * scale));
    return path;
  }
  Path _createFlower(double size) {
    final path = Path();
    final petalCount = 6;
    final radius = size / 2;
    final petalRadius = radius * 0.4;
    for (var i = 0; i < petalCount; i++) {
      final angle = (i * 2 * pi) / petalCount;
      final centerX = cos(angle) * radius * 0.45;
      final centerY = sin(angle) * radius * 0.45;
      path.addOval(Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: petalRadius,
      ));
    }
    path.addOval(Rect.fromCircle(center: Offset.zero, radius: radius * 0.25));
    return path;
  }
  @override
  bool shouldRepaint(covariant _ShapeThumbnailPainter oldDelegate) =>
      shapeIndex != oldDelegate.shapeIndex || color != oldDelegate.color;
}
