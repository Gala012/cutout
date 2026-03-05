import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../../db_cutout_burst/db_cutout_burst_entity.dart';
import '../../utils/colors.dart';
import '../../utils/index.dart';
enum TrimTool {
  add,
  subtract,
  erase,
  restore,
}
class RowSegment {
  final int y;
  final int left;
  final int right;
  RowSegment({
    required this.y,
    required this.left,
    required this.right,
  });
}
class TrimStroke {
  final List<Offset> points;
  final TrimTool tool;
  final double brushSize;
  final List<RowSegment>?
      regionSegments;
  TrimStroke({
    required this.points,
    required this.tool,
    required this.brushSize,
    this.regionSegments,
  });
}
Map<String, dynamic> _boundaryFillIsolate(Map<String, dynamic> params) {
  final startX = params['startX'] as int;
  final startY = params['startY'] as int;
  final targetColorValue = params['targetColorValue'] as int;
  final tolerance = params['tolerance'] as int;
  final pixelData = params['pixelData'] as Uint8List;
  final imageWidth = params['imageWidth'] as int;
  final imageHeight = params['imageHeight'] as int;
  final targetColor = Color(targetColorValue);
  final visited = <int>{};
  final pixelsByRow = <int, Set<int>>{};
  final queue = Queue<Offset>()
    ..add(Offset(startX.toDouble(), startY.toDouble()));
  const maxIterations = 200000;
  int iterations = 0;
  Color? getPixelColor(int x, int y) {
    if (x < 0 || x >= imageWidth || y < 0 || y >= imageHeight) return null;
    final index = (y * imageWidth + x) * 4;
    if (index + 3 >= pixelData.length) return null;
    return Color.fromARGB(
      pixelData[index + 3],
      pixelData[index + 0],
      pixelData[index + 1],
      pixelData[index + 2],
    );
  }
  double colorDistance(Color c1, Color c2) {
    final dr = c1.red - c2.red;
    final dg = c1.green - c2.green;
    final db = c1.blue - c2.blue;
    return sqrt(dr * dr + dg * dg + db * db);
  }
  while (queue.isNotEmpty && iterations < maxIterations) {
    iterations++;
    final point = queue.removeFirst();
    final x = point.dx.toInt();
    final y = point.dy.toInt();
    if (x < 0 || x >= imageWidth || y < 0 || y >= imageHeight) continue;
    final index = y * imageWidth + x;
    if (visited.contains(index)) continue;
    visited.add(index);
    final pixelColor = getPixelColor(x, y);
    if (pixelColor == null) continue;
    if (colorDistance(pixelColor, targetColor) <= tolerance) {
      pixelsByRow.putIfAbsent(y, () => <int>{});
      pixelsByRow[y]!.add(x);
      queue.add(Offset((x + 1).toDouble(), y.toDouble()));
      queue.add(Offset((x - 1).toDouble(), y.toDouble()));
      queue.add(Offset(x.toDouble(), (y + 1).toDouble()));
      queue.add(Offset(x.toDouble(), (y - 1).toDouble()));
    }
  }
  final regionBoundaries = <Map<String, dynamic>>[];
  for (final entry in pixelsByRow.entries) {
    final y = entry.key;
    final xCoords = entry.value.toList()..sort();
    if (xCoords.isEmpty) continue;
    int segmentStart = xCoords[0];
    int segmentEnd = xCoords[0];
    for (int i = 1; i < xCoords.length; i++) {
      if (xCoords[i] == segmentEnd + 1) {
        segmentEnd = xCoords[i];
      } else {
        regionBoundaries.add({
          'y': y.toDouble(),
          'left': segmentStart.toDouble(),
          'right': segmentEnd.toDouble(),
        });
        segmentStart = xCoords[i];
        segmentEnd = xCoords[i];
      }
    }
    regionBoundaries.add({
      'y': y.toDouble(),
      'left': segmentStart.toDouble(),
      'right': segmentEnd.toDouble(),
    });
  }
  return {
    'regionBoundaries': regionBoundaries,
    'totalSegments': regionBoundaries.length,
  };
}
class CutoutBurstTrimCutoutLogic extends GetxController {
  final String imagePath = Get.arguments?['imagePath'] ?? '';
  final int cropOriginX = Get.arguments?['cropOriginX'] ?? 0;
  final int cropOriginY = Get.arguments?['cropOriginY'] ?? 0;
  final int origWidth = Get.arguments?['origWidth'] ?? 0;
  final int origHeight = Get.arguments?['origHeight'] ?? 0;
  final double cropBoxWidth = Get.arguments?['cropBoxWidth'] ?? 0.0;
  final double cropBoxHeight = Get.arguments?['cropBoxHeight'] ?? 0.0;
  final double cropBoxLeft = Get.arguments?['cropBoxLeft'] ?? 0.0;
  final double cropBoxTop = Get.arguments?['cropBoxTop'] ?? 0.0;
  final currentStep = 1.obs;
  final selectedBgColor = const Color(0xFF2196F3).obs;
  final currentTool = TrimTool.add.obs;
  final isLargeBrush = true.obs;
  final isProcessing = false.obs;
  final isDragging = false.obs;
  final isPanMode = false.obs;
  late TransformationController transformationController;
  Rx<File?> imageFile = Rx<File?>(null);
  final uiImage = Rx<ui.Image?>(null);
  final imageDisplayLeft = 0.0.obs;
  final imageDisplayTop = 0.0.obs;
  final imageDisplayWidth = 0.0.obs;
  final imageDisplayHeight = 0.0.obs;
  final strokes = <TrimStroke>[].obs;
  final undoneStrokes = <TrimStroke>[].obs;
  final currentStroke = Rx<TrimStroke?>(null);
  final lastTouchPoint = Offset.zero.obs;
  ByteData? _imagePixelData;
  int _imagePixelWidth = 0;
  int _imagePixelHeight = 0;
  static const bgColors = [
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFFFFFF),
    Color(0xFF000000),
    Color(0xFF9E9E9E),
  ];
  double get brushSize => isLargeBrush.value ? 25.0 : 10.0;
  bool get canUndo => strokes.isNotEmpty;
  bool get canRedo => undoneStrokes.isNotEmpty;
  @override
  void onInit() {
    super.onInit();
    transformationController = TransformationController();
    if (imagePath.isNotEmpty) {
      _loadImage();
    }
  }
  @override
  void onClose() {
    transformationController.dispose();
    uiImage.value?.dispose();
    super.onClose();
  }
  Future<void> _loadImage() async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        errorToast('Image not found');
        return;
      }
      imageFile.value = file;
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      uiImage.value?.dispose();
      uiImage.value = frame.image;
      codec.dispose();
      await _loadImagePixelData(frame.image);
      debugPrint('\n====== TRIM CUTOUT PAGE DEBUG ======');
      debugPrint(
          '📷 Loaded Cropped Image: ${frame.image.width} x ${frame.image.height}');
      debugPrint('📦 Crop Metadata:');
      debugPrint('   - Original Image: $origWidth x $origHeight');
      debugPrint('   - Crop Origin: x=$cropOriginX, y=$cropOriginY');
      debugPrint('=====================================\n');
    } catch (e) {
      errorToast('Failed to load image');
    }
  }
  Future<void> _loadImagePixelData(ui.Image image) async {
    try {
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      _imagePixelData = byteData;
      _imagePixelWidth = image.width;
      _imagePixelHeight = image.height;
    } catch (e) {
      debugPrint('Failed to load pixel data: $e');
    }
  }
  void updateImageDisplayRect(Rect rect) {
    imageDisplayLeft.value = rect.left;
    imageDisplayTop.value = rect.top;
    imageDisplayWidth.value = rect.width;
    imageDisplayHeight.value = rect.height;
  }
  Rect calcImageDisplayRect(Size canvasSize) {
    final image = uiImage.value;
    if (image == null) return Rect.zero;
    double w, h, l, t;
    if (cropBoxWidth > 0 && cropBoxHeight > 0) {
      final cropBoxAspectRatio = cropBoxWidth / cropBoxHeight;
      final canvasAspectRatio = canvasSize.width / canvasSize.height;
      if (cropBoxAspectRatio > canvasAspectRatio) {
        w = canvasSize.width * 0.9;
        h = w / cropBoxAspectRatio;
      } else {
        h = canvasSize.height * 0.85;
        w = h * cropBoxAspectRatio;
      }
      l = (canvasSize.width - w) / 2;
      t = (canvasSize.height - h) / 2;
      debugPrint('\n====== TRIM CUTOUT DISPLAY CALC ======');
      debugPrint(
          '📺 Canvas Size: ${canvasSize.width.toStringAsFixed(1)} x ${canvasSize.height.toStringAsFixed(1)}');
      debugPrint('📷 Cropped Image: ${image.width} x ${image.height}');
      debugPrint(
          '📦 Crop Box (from Crop page): W=${cropBoxWidth.toStringAsFixed(1)}, H=${cropBoxHeight.toStringAsFixed(1)}, AR=${cropBoxAspectRatio.toStringAsFixed(3)}');
      debugPrint(
          '🖼️  Display Rect (maintaining crop box aspect ratio): L=${l.toStringAsFixed(1)}, T=${t.toStringAsFixed(1)}, W=${w.toStringAsFixed(1)}, H=${h.toStringAsFixed(1)}');
      debugPrint('======================================\n');
    } else {
      final scale = min(
        canvasSize.width / image.width,
        canvasSize.height / image.height,
      );
      w = image.width * scale;
      h = image.height * scale;
      l = (canvasSize.width - w) / 2;
      t = (canvasSize.height - h) / 2;
      debugPrint('\n====== TRIM CUTOUT DISPLAY CALC (Fallback) ======');
      debugPrint(
          '📺 Canvas Size: ${canvasSize.width.toStringAsFixed(1)} x ${canvasSize.height.toStringAsFixed(1)}');
      debugPrint('📷 Cropped Image: ${image.width} x ${image.height}');
      debugPrint('📐 Scale (BoxFit.contain): ${scale.toStringAsFixed(3)}');
      debugPrint(
          '🖼️  Display Rect: L=${l.toStringAsFixed(1)}, T=${t.toStringAsFixed(1)}, W=${w.toStringAsFixed(1)}, H=${h.toStringAsFixed(1)}');
      debugPrint('==================================================\n');
    }
    return Rect.fromLTWH(l, t, w, h);
  }
  void onDrawStart(Offset position) {
    if (isPanMode.value) return;
    undoneStrokes.clear();
    final effectiveBrushSize = brushSize / 2;
    currentStroke.value = TrimStroke(
      points: [position],
      tool: currentTool.value,
      brushSize: effectiveBrushSize,
    );
    isDragging.value = true;
    lastTouchPoint.value = position;
  }
  Future<void> _performIntelligentSelectionForStroke(TrimStroke stroke) async {
    if (_imagePixelData == null) {
      errorToast('Image data not loaded');
      return;
    }
    try {
      if (stroke.points.isEmpty) {
        errorToast('No points in stroke');
        return;
      }
      final sampledPoints = _sampleStrokePoints(stroke.points);
      if (sampledPoints.isEmpty) {
        errorToast('No valid sample points');
        return;
      }
      debugPrint(
          '📍 Sampling ${sampledPoints.length} points along stroke path');
      final allRegionSegments = <RowSegment>[];
      final processedRegions =
          <String>{};
      int colorCount = 0;
      const maxSegments = 10000;
      for (final samplePoint in sampledPoints) {
        if (allRegionSegments.length >= maxSegments) {
          debugPrint(
              '⚠️ Reached segment limit ($maxSegments), stopping collection');
          break;
        }
        final imagePos = _displayToImageCoords(samplePoint);
        if (imagePos == null) continue;
        final imageX = imagePos.dx.toInt();
        final imageY = imagePos.dy.toInt();
        final targetColor = _getPixelColor(imageX, imageY);
        if (targetColor != null) {
          final regionSegments = await _boundaryFillSimilarColorsAsync(
            imageX,
            imageY,
            targetColor,
            tolerance: 150,
          );
          if (regionSegments.isNotEmpty) {
            final regionId =
                '${regionSegments.first.y}_${regionSegments.first.left}_${regionSegments.first.right}';
            if (!processedRegions.contains(regionId)) {
              processedRegions.add(regionId);
              final limitedSegments = regionSegments.length > maxSegments
                  ? regionSegments.sublist(0, maxSegments)
                  : regionSegments;
              allRegionSegments.addAll(limitedSegments);
              colorCount++;
            }
          }
        }
      }
      if (allRegionSegments.isEmpty) {
        errorToast('No regions found');
        return;
      }
      int totalPixels = 0;
      for (final seg in allRegionSegments) {
        totalPixels += (seg.right - seg.left + 1);
      }
      debugPrint(
          '✨ Found $colorCount unique color regions, ${allRegionSegments.length} segments covering ~$totalPixels pixels');
      final displayRegionSegments = <RowSegment>[];
      for (final seg in allRegionSegments) {
        final leftPos = _imageToDisplayCoords(
            Offset(seg.left.toDouble(), seg.y.toDouble()));
        final rightPos = _imageToDisplayCoords(
            Offset(seg.right.toDouble(), seg.y.toDouble()));
        if (leftPos != null && rightPos != null) {
          displayRegionSegments.add(RowSegment(
            y: leftPos.dy.toInt(),
            left: leftPos.dx.toInt(),
            right: rightPos.dx.toInt(),
          ));
        }
      }
      debugPrint(
          '🔄 Converted to ${displayRegionSegments.length} display segments');
      if (displayRegionSegments.isEmpty) {
        errorToast('Coordinate conversion failed');
        return;
      }
      final finalStroke = TrimStroke(
        points: stroke.points,
        tool: stroke.tool,
        brushSize: stroke.brushSize,
        regionSegments: displayRegionSegments,
      );
      debugPrint(
          '✅ Created stroke with ${finalStroke.points.length} line points and ${finalStroke.regionSegments?.length ?? 0} region segments');
      strokes.add(finalStroke);
      strokes.refresh();
    } catch (e) {
      errorToast('Selection failed: $e');
      debugPrint('Error in intelligent selection: $e');
    }
  }
  List<Offset> _sampleStrokePoints(List<Offset> points) {
    if (points.isEmpty) return [];
    if (points.length <= 10) return points;
    const sampleInterval = 5;
    final sampledPoints = <Offset>[];
    for (int i = 0; i < points.length; i += sampleInterval) {
      sampledPoints.add(points[i]);
    }
    if (sampledPoints.last != points.last) {
      sampledPoints.add(points.last);
    }
    return sampledPoints;
  }
  Offset? _displayToImageCoords(Offset displayPos) {
    if (imageDisplayWidth.value <= 0 || imageDisplayHeight.value <= 0) {
      return null;
    }
    if (displayPos.dx < imageDisplayLeft.value ||
        displayPos.dx > imageDisplayLeft.value + imageDisplayWidth.value ||
        displayPos.dy < imageDisplayTop.value ||
        displayPos.dy > imageDisplayTop.value + imageDisplayHeight.value) {
      return null;
    }
    final relativeX = displayPos.dx - imageDisplayLeft.value;
    final relativeY = displayPos.dy - imageDisplayTop.value;
    final imageX = (relativeX / imageDisplayWidth.value * _imagePixelWidth)
        .clamp(0, _imagePixelWidth - 1);
    final imageY = (relativeY / imageDisplayHeight.value * _imagePixelHeight)
        .clamp(0, _imagePixelHeight - 1);
    return Offset(imageX.toDouble(), imageY.toDouble());
  }
  Offset? _imageToDisplayCoords(Offset imagePos) {
    if (imageDisplayWidth.value <= 0 || imageDisplayHeight.value <= 0) {
      return null;
    }
    final displayX = imageDisplayLeft.value +
        (imagePos.dx / _imagePixelWidth * imageDisplayWidth.value);
    final displayY = imageDisplayTop.value +
        (imagePos.dy / _imagePixelHeight * imageDisplayHeight.value);
    return Offset(displayX, displayY);
  }
  Color? _getPixelColor(int x, int y) {
    if (_imagePixelData == null) return null;
    if (x < 0 || x >= _imagePixelWidth || y < 0 || y >= _imagePixelHeight) {
      return null;
    }
    final index = (y * _imagePixelWidth + x) * 4;
    final buffer = _imagePixelData!.buffer.asUint8List();
    if (index + 3 >= buffer.length) return null;
    return Color.fromARGB(
      buffer[index + 3],
      buffer[index + 0],
      buffer[index + 1],
      buffer[index + 2],
    );
  }
  Future<List<RowSegment>> _boundaryFillSimilarColorsAsync(
      int startX, int startY, Color targetColor,
      {required int tolerance}) async {
    if (_imagePixelData == null) return [];
    try {
      final params = {
        'startX': startX,
        'startY': startY,
        'targetColorValue': targetColor.value,
        'tolerance': tolerance,
        'pixelData': _imagePixelData!.buffer.asUint8List(),
        'imageWidth': _imagePixelWidth,
        'imageHeight': _imagePixelHeight,
      };
      final result = await compute(_boundaryFillIsolate, params);
      final regionBoundariesMaps =
          result['regionBoundaries'] as List<Map<String, dynamic>>;
      final regionSegments = regionBoundariesMaps
          .map((seg) => RowSegment(
                y: (seg['y'] as double).toInt(),
                left: (seg['left'] as double).toInt(),
                right: (seg['right'] as double).toInt(),
              ))
          .toList();
      debugPrint(
          'Boundary fill completed: ${regionSegments.length} segments, ${result['totalSegments']} total');
      return regionSegments;
    } catch (e) {
      debugPrint('Error in async boundary fill: $e');
      return [];
    }
  }
  void onDrawUpdate(Offset position) {
    final stroke = currentStroke.value;
    if (stroke == null) return;
    currentStroke.value = TrimStroke(
      points: [...stroke.points, position],
      tool: stroke.tool,
      brushSize: stroke.brushSize,
      regionSegments: stroke.regionSegments,
    );
    lastTouchPoint.value = position;
  }
  void onDrawEnd() async {
    final stroke = currentStroke.value;
    if (stroke != null) {
      if (stroke.points.isNotEmpty) {
        if (stroke.tool == TrimTool.add || stroke.tool == TrimTool.subtract) {
          await _performIntelligentSelectionForStroke(stroke);
        } else {
          strokes.add(stroke);
        }
      }
      currentStroke.value = null;
    }
    isDragging.value = false;
  }
  void onUndo() {
    if (strokes.isEmpty) return;
    final last = strokes.removeLast();
    undoneStrokes.add(last);
    strokes.refresh();
    debugPrint('↩️ Undo: ${strokes.length} strokes remaining');
  }
  void onRedo() {
    if (undoneStrokes.isEmpty) return;
    final stroke = undoneStrokes.removeLast();
    strokes.add(stroke);
    strokes.refresh();
    debugPrint('↪️ Redo: ${strokes.length} strokes now');
  }
  void onFitScreen() {
    transformationController.value = Matrix4.identity();
  }
  void onZoomIn() {
    final currentMatrix = transformationController.value.clone();
    final scale = currentMatrix.getMaxScaleOnAxis();
    if (scale < 5.0) {
      final newScale = min(scale * 1.25, 5.0);
      final scaleFactor = newScale / scale;
      final newMatrix = currentMatrix.clone();
      newMatrix.scale(scaleFactor, scaleFactor, 1.0);
      transformationController.value = newMatrix;
    }
  }
  void onZoomOut() {
    final currentMatrix = transformationController.value.clone();
    final scale = currentMatrix.getMaxScaleOnAxis();
    if (scale > 0.5) {
      final newScale = max(scale / 1.25, 0.5);
      final scaleFactor = newScale / scale;
      final newMatrix = currentMatrix.clone();
      newMatrix.scale(scaleFactor, scaleFactor, 1.0);
      transformationController.value = newMatrix;
    }
  }
  void onShowHelp() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'How to Use Trim Cutout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '• Background: Choose a tint color overlay (default: covers entire image)\n'
          '• Add: Tap to reveal similar colors (removes tint intelligently)\n'
          '• Subtract: Tap to cover similar colors (adds tint intelligently)\n'
          '• Erase: Paint to add tint manually\n'
          '• Restore: Paint to remove tint manually\n'
          '• Undo / Redo: Step backward or forward through operations\n'
          '• Pinch to zoom for fine-detail work\n'
          '• Use + / − buttons in toolbar to zoom in/out\n'
          '• Tap ⊡ to reset zoom to fit screen',
          style: TextStyle(
            color: Colors.white70,
            height: 1.7,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text(
              'Got it',
              style: TextStyle(color: CutoutBurstColors.primary),
            ),
          ),
        ],
      ),
    );
  }
  void onBgColorChange(Color color) => selectedBgColor.value = color;
  void togglePanMode() {
    isPanMode.value = !isPanMode.value;
    if (isPanMode.value) {
      currentStroke.value = null;
    }
  }
  Future<void> onSaveTap() async {
    if (uiImage.value == null) {
      errorToast('No image loaded');
      return;
    }
    try {
      isProcessing.value = true;
      final bytes = await _renderFinalImage();
      if (bytes == null) {
        errorToast('Failed to render image');
        return;
      }
      final dir = await getTemporaryDirectory();
      final fileName =
          'trim_cutout_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      Get.toNamed(
        '/cutout_burst_change_bg',
        arguments: {
          'cutoutImagePath': file.path,
          'cutoutMode': CutoutMode.trim,
          'imageWidth': uiImage.value!.width,
          'imageHeight': uiImage.value!.height,
          'displayWidth': imageDisplayWidth.value,
          'displayHeight': imageDisplayHeight.value,
        },
      );
    } catch (e) {
      errorToast('Processing failed: $e');
    } finally {
      isProcessing.value = false;
    }
  }
  Future<Uint8List?> _renderFinalImage() async {
    final image = uiImage.value;
    if (image == null) return null;
    if (imageDisplayWidth.value <= 0 || imageDisplayHeight.value <= 0) {
      return await imageFile.value?.readAsBytes();
    }
    const maxDimension = 2048;
    double outW = imageDisplayWidth.value;
    double outH = imageDisplayHeight.value;
    if (outW > maxDimension || outH > maxDimension) {
      final scale = maxDimension / max(outW, outH);
      outW = outW * scale;
      outH = outH * scale;
      debugPrint('⚠️ Output size limited: ${outW.toInt()} x ${outH.toInt()}');
    }
    final outputWidth = outW.toInt();
    final outputHeight = outH.toInt();
    final scaleX = imageDisplayWidth.value > 0
        ? outputWidth / imageDisplayWidth.value
        : 1.0;
    final scaleY = imageDisplayHeight.value > 0
        ? outputHeight / imageDisplayHeight.value
        : 1.0;
    final maskRecorder = ui.PictureRecorder();
    final maskCanvas = Canvas(maskRecorder,
        Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()));
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      switch (stroke.tool) {
        case TrimTool.add:
        case TrimTool.restore:
          _drawStrokeMaskDisplay(maskCanvas, stroke, outputWidth.toDouble(),
              outputHeight.toDouble(), paint, scaleX, scaleY);
          if (stroke.tool == TrimTool.add &&
              stroke.regionSegments != null &&
              stroke.regionSegments!.isNotEmpty) {
            _drawRegionSegmentsDisplay(
                maskCanvas,
                stroke.regionSegments!,
                outputWidth.toDouble(),
                outputHeight.toDouble(),
                paint,
                scaleX,
                scaleY);
          }
          break;
        case TrimTool.subtract:
        case TrimTool.erase:
          paint.blendMode = ui.BlendMode.clear;
          _drawStrokeMaskDisplay(maskCanvas, stroke, outputWidth.toDouble(),
              outputHeight.toDouble(), paint, scaleX, scaleY);
          if (stroke.tool == TrimTool.subtract &&
              stroke.regionSegments != null &&
              stroke.regionSegments!.isNotEmpty) {
            _drawRegionSegmentsDisplay(
                maskCanvas,
                stroke.regionSegments!,
                outputWidth.toDouble(),
                outputHeight.toDouble(),
                paint,
                scaleX,
                scaleY);
          }
          break;
      }
    }
    final maskPicture = maskRecorder.endRecording();
    var maskImage = await maskPicture.toImage(outputWidth, outputHeight);
    maskPicture.dispose();
    maskImage = await _applyMaskDilation(maskImage, radius: 3);
    debugPrint('✅ Mask created with dilation effect');
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder,
        Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()));
    canvas.saveLayer(
        Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
        Paint());
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
      Paint(),
    );
    canvas.drawImage(
        maskImage, Offset.zero, Paint()..blendMode = ui.BlendMode.dstIn);
    canvas.restore();
    final picture = recorder.endRecording();
    final finalImage = await picture.toImage(outputWidth, outputHeight);
    final byteData =
        await finalImage.toByteData(format: ui.ImageByteFormat.png);
    maskImage.dispose();
    finalImage.dispose();
    picture.dispose();
    debugPrint('✅ Image rendered: ${outputWidth}x${outputHeight}');
    return byteData?.buffer.asUint8List();
  }
  void _drawStrokeMaskDisplay(Canvas canvas, TrimStroke stroke, double outW,
      double outH, Paint paint, double scaleX, double scaleY) {
    final adjustedPoints = stroke.points.map((p) {
      return Offset(
        ((p.dx - imageDisplayLeft.value) * scaleX).clamp(0.0, outW),
        ((p.dy - imageDisplayTop.value) * scaleY).clamp(0.0, outH),
      );
    }).toList();
    paint.strokeWidth = stroke.brushSize * min(scaleX, scaleY);
    paint.style = PaintingStyle.stroke;
    paint.strokeCap = StrokeCap.round;
    paint.strokeJoin = StrokeJoin.round;
    if (adjustedPoints.length == 1) {
      canvas.drawCircle(adjustedPoints[0], paint.strokeWidth / 2, paint);
    } else {
      final path = Path()..moveTo(adjustedPoints[0].dx, adjustedPoints[0].dy);
      for (var i = 1; i < adjustedPoints.length; i++) {
        path.lineTo(adjustedPoints[i].dx, adjustedPoints[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }
  void _drawRegionSegmentsDisplay(
      Canvas canvas,
      List<RowSegment> regionSegments,
      double outW,
      double outH,
      Paint paint,
      double scaleX,
      double scaleY) {
    if (regionSegments.isEmpty) return;
    paint.style = PaintingStyle.fill;
    for (final segment in regionSegments) {
      final y = ((segment.y - imageDisplayTop.value) * scaleY).clamp(0.0, outH);
      final left =
          ((segment.left - imageDisplayLeft.value) * scaleX).clamp(0.0, outW);
      final right =
          ((segment.right - imageDisplayLeft.value) * scaleX).clamp(0.0, outW);
      canvas.drawRect(
        Rect.fromLTRB(left, y, right + 1, y + 1),
        paint,
      );
    }
  }
  Future<ui.Image> _applyMaskDilation(ui.Image maskImage,
      {int radius = 5}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(
          0, 0, maskImage.width.toDouble(), maskImage.height.toDouble()),
    );
    final paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImage(maskImage, Offset.zero, paint);
    for (double angle = 0; angle < 360; angle += 22.5) {
      for (var r = 1; r <= radius; r++) {
        final radian = angle * pi / 180;
        final dx = cos(radian) * r;
        final dy = sin(radian) * r;
        canvas.drawImage(maskImage, Offset(dx, dy), paint);
      }
    }
    final picture = recorder.endRecording();
    final tempImage = await picture.toImage(
      maskImage.width,
      maskImage.height,
    );
    picture.dispose();
    final blurRecorder = ui.PictureRecorder();
    final blurCanvas = Canvas(
      blurRecorder,
      Rect.fromLTWH(
          0, 0, maskImage.width.toDouble(), maskImage.height.toDouble()),
    );
    final blurPaint = Paint()
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5)
      ..filterQuality = FilterQuality.medium;
    blurCanvas.drawImage(tempImage, Offset.zero, blurPaint);
    final blurPicture = blurRecorder.endRecording();
    final dilatedImage = await blurPicture.toImage(
      maskImage.width,
      maskImage.height,
    );
    tempImage.dispose();
    blurPicture.dispose();
    return dilatedImage;
  }
  void onBackTap() => Get.back();
}
