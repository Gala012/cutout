import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../../db_cutout_burst/db_cutout_burst_entity.dart';
import '../../utils/index.dart';
class ShapeObject {
  String id;
  int shapeIndex;
  Offset position;
  double scale;
  double rotation;
  ShapeObject({
    required this.id,
    required this.shapeIndex,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
  });
  ShapeObject copyWith({
    String? id,
    int? shapeIndex,
    Offset? position,
    double? scale,
    double? rotation,
  }) {
    return ShapeObject(
      id: id ?? this.id,
      shapeIndex: shapeIndex ?? this.shapeIndex,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }
}
class FreeDrawPath {
  String id;
  List<Offset> points;
  String lineType;
  FreeDrawPath({
    required this.id,
    required this.points,
    this.lineType = 'curve',
  });
  FreeDrawPath copyWith({
    String? id,
    List<Offset>? points,
    String? lineType,
  }) {
    return FreeDrawPath(
      id: id ?? this.id,
      points: points ?? this.points,
      lineType: lineType ?? this.lineType,
    );
  }
}
class CutoutBurstShapeCutoutLogic extends GetxController {
  final String imagePath = Get.arguments?['imagePath'] ?? '';
  final int cropOriginX = Get.arguments?['cropOriginX'] ?? 0;
  final int cropOriginY = Get.arguments?['cropOriginY'] ?? 0;
  final int origWidth = Get.arguments?['origWidth'] ?? 0;
  final int origHeight = Get.arguments?['origHeight'] ?? 0;
  final double cropBoxWidth = Get.arguments?['cropBoxWidth'] ?? 0.0;
  final double cropBoxHeight = Get.arguments?['cropBoxHeight'] ?? 0.0;
  final uiImage = Rx<ui.Image?>(null);
  final imageDisplayLeft = 0.0.obs;
  final imageDisplayTop = 0.0.obs;
  final imageDisplayWidth = 0.0.obs;
  final imageDisplayHeight = 0.0.obs;
  final isShapeMode = true.obs;
  final selectedShapeIndex = (-1).obs;
  final selectedShapeId = Rx<String?>(null);
  final shapes = <ShapeObject>[].obs;
  final freePaths = <FreeDrawPath>[].obs;
  final isDrawing = false.obs;
  final currentDrawPoints = <Offset>[].obs;
  final undoStack = <Map<String, dynamic>>[].obs;
  final redoStack = <Map<String, dynamic>>[].obs;
  final showHelp = false.obs;
  final isProcessing = false.obs;
  String? _draggedShapeId;
  String? _dragHandleType;
  Offset? _dragStartPosition;
  double? _dragStartScale;
  double? _dragStartRotation;
  Offset? _dragStartShapePosition;
  double _lastPinchScale = 1.0;
  double _lastRotation = 0.0;
  static const shapeLabels = [
    'B005',
    'B006',
    'B007',
    '022',
    '001',
    '002',
    'Star',
    'Heart',
    'Diamond',
    'Arrow',
    'Cloud',
    'Flower',
  ];
  @override
  void onInit() {
    super.onInit();
    _loadImage();
  }
  @override
  void onClose() {
    uiImage.value?.dispose();
    super.onClose();
  }
  Future<void> _loadImage() async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        errorToast('Image not found');
        Get.back();
        return;
      }
      final bytes = await file.readAsBytes();
      const maxDimension = 3840;
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: maxDimension,
        targetHeight: maxDimension,
      );
      final frame = await codec.getNextFrame();
      uiImage.value = frame.image;
      codec.dispose();
    } catch (e) {
      errorToast('Failed to load image: $e');
      Get.back();
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
    } else {
      final scale = (canvasSize.width / image.width).clamp(0.0, 1.0);
      w = image.width * scale;
      h = image.height * scale;
      l = (canvasSize.width - w) / 2;
      t = (canvasSize.height - h) / 2;
    }
    return Rect.fromLTWH(l, t, w, h);
  }
  void onModeSwitch(bool isShape) {
    isShapeMode.value = isShape;
    selectedShapeId.value = null;
    selectedShapeIndex.value = -1;
  }
  void onShapeSelect(int index) {
    if (!isShapeMode.value) return;
    selectedShapeIndex.value = index;
    _addShapeToImage(index);
  }
  void _addShapeToImage(int shapeIndex) {
    if (imageDisplayWidth.value == 0 || imageDisplayHeight.value == 0) return;
    _saveStateForUndo();
    final centerX = imageDisplayLeft.value + imageDisplayWidth.value / 2;
    final centerY = imageDisplayTop.value + imageDisplayHeight.value / 2;
    final shape = ShapeObject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      shapeIndex: shapeIndex,
      position: Offset(centerX, centerY),
      scale: 1.0,
      rotation: 0.0,
    );
    shapes.add(shape);
    selectedShapeId.value = shape.id;
    debugPrint(
        '✅ Shape added: ${shapeLabels[shapeIndex]} at ($centerX, $centerY)');
  }
  void onShapeTap(String shapeId) {
    selectedShapeId.value = shapeId;
  }
  void onDeselectShape() {
    selectedShapeId.value = null;
  }
  void onShapeMove(String shapeId, Offset delta) {
    final index = shapes.indexWhere((s) => s.id == shapeId);
    if (index == -1) return;
    final shape = shapes[index];
    shapes[index] = shape.copyWith(
      position: shape.position + delta,
    );
    _checkShapeOutOfBounds(shapeId);
  }
  void onShapeScale(String shapeId, double scaleDelta) {
    final index = shapes.indexWhere((s) => s.id == shapeId);
    if (index == -1) return;
    final shape = shapes[index];
    final newScale = (shape.scale * scaleDelta).clamp(0.5, 3.0);
    shapes[index] = shape.copyWith(scale: newScale);
  }
  void onShapeRotate(String shapeId, double angleDelta) {
    final index = shapes.indexWhere((s) => s.id == shapeId);
    if (index == -1) return;
    final shape = shapes[index];
    shapes[index] = shape.copyWith(
      rotation: shape.rotation + angleDelta,
    );
  }
  void onHandleDragStart(String shapeId, String handleType, Offset position) {
    final index = shapes.indexWhere((s) => s.id == shapeId);
    if (index == -1) return;
    _draggedShapeId = shapeId;
    _dragHandleType = handleType;
    _dragStartPosition = position;
    final shape = shapes[index];
    _dragStartScale = shape.scale;
    _dragStartRotation = shape.rotation;
    _dragStartShapePosition = shape.position;
    debugPrint('🎯 Drag start: $handleType for shape $shapeId');
  }
  void onHandleDragUpdate(Offset currentPosition) {
    if (_draggedShapeId == null || _dragStartPosition == null) return;
    final index = shapes.indexWhere((s) => s.id == _draggedShapeId);
    if (index == -1) return;
    final shape = shapes[index];
    final delta = currentPosition - _dragStartPosition!;
    switch (_dragHandleType) {
      case 'scale':
        final distance = delta.distance;
        final scaleFactor = 1.0 + (distance / 100.0);
        final newScale = (_dragStartScale! * scaleFactor).clamp(0.3, 4.0);
        shapes[index] = shape.copyWith(scale: newScale);
        break;
      case 'move':
        final newPosition = _dragStartShapePosition! + delta;
        shapes[index] = shape.copyWith(position: newPosition);
        break;
      case 'rotate':
        final center = shape.position;
        final startAngle = (_dragStartPosition! - center).direction;
        final currentAngle = (currentPosition - center).direction;
        final angleDelta = currentAngle - startAngle;
        final newRotation = _dragStartRotation! + angleDelta;
        shapes[index] = shape.copyWith(rotation: newRotation);
        break;
    }
  }
  void onHandleDragEnd() {
    if (_draggedShapeId != null && _dragHandleType == 'move') {
      _checkShapeOutOfBounds(_draggedShapeId!);
    }
    _draggedShapeId = null;
    _dragHandleType = null;
    _dragStartPosition = null;
    _dragStartScale = null;
    _dragStartRotation = null;
    _dragStartShapePosition = null;
    _lastPinchScale = 1.0;
    _lastRotation = 0.0;
    debugPrint('🎯 Drag end');
  }
  void onPinchScale(String shapeId, double currentScale) {
    final index = shapes.indexWhere((s) => s.id == shapeId);
    if (index == -1) return;
    final shape = shapes[index];
    final scaleDelta = currentScale / _lastPinchScale;
    final newScale = (shape.scale * scaleDelta).clamp(0.3, 4.0);
    shapes[index] = shape.copyWith(scale: newScale);
    _lastPinchScale = currentScale;
  }
  void onPinchRotate(String shapeId, double currentRotation) {
    final index = shapes.indexWhere((s) => s.id == shapeId);
    if (index == -1) return;
    final shape = shapes[index];
    final rotationDelta = currentRotation - _lastRotation;
    final newRotation = shape.rotation + rotationDelta;
    shapes[index] = shape.copyWith(rotation: newRotation);
    _lastRotation = currentRotation;
  }
  void resetPinchGestures() {
    _lastPinchScale = 1.0;
    _lastRotation = 0.0;
  }
  void _checkShapeOutOfBounds(String shapeId) {
    final index = shapes.indexWhere((s) => s.id == shapeId);
    if (index == -1) return;
    final shape = shapes[index];
    final rect = Rect.fromLTWH(
      imageDisplayLeft.value,
      imageDisplayTop.value,
      imageDisplayWidth.value,
      imageDisplayHeight.value,
    );
    if (!rect.contains(shape.position)) {
      shapes.removeAt(index);
      if (selectedShapeId.value == shapeId) {
        selectedShapeId.value = null;
      }
      debugPrint('🗑️ Shape removed (out of bounds)');
    }
  }
  void onFreeDrawStart(Offset position) {
    if (isShapeMode.value) return;
    isDrawing.value = true;
    currentDrawPoints.clear();
    currentDrawPoints.add(position);
  }
  void onFreeDrawUpdate(Offset position) {
    if (!isDrawing.value) return;
    currentDrawPoints.add(position);
  }
  void onFreeDrawEnd() {
    if (!isDrawing.value) return;
    isDrawing.value = false;
    if (currentDrawPoints.length < 3) {
      currentDrawPoints.clear();
      return;
    }
    _saveStateForUndo();
    final path = FreeDrawPath(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      points: List.from(currentDrawPoints),
      lineType: 'curve',
    );
    freePaths.add(path);
    currentDrawPoints.clear();
    debugPrint('✅ Free path added: ${path.points.length} points');
  }
  void _saveStateForUndo() {
    final state = {
      'shapes': shapes.map((s) => s.copyWith()).toList(),
      'freePaths': freePaths.map((p) => p.copyWith()).toList(),
    };
    undoStack.add(state);
    redoStack.clear();
    if (undoStack.length > 20) {
      undoStack.removeAt(0);
    }
  }
  void onUndo() {
    if (undoStack.isEmpty) return;
    final currentState = {
      'shapes': shapes.map((s) => s.copyWith()).toList(),
      'freePaths': freePaths.map((p) => p.copyWith()).toList(),
    };
    redoStack.add(currentState);
    final previousState = undoStack.removeLast();
    shapes.value = List<ShapeObject>.from(previousState['shapes']);
    freePaths.value = List<FreeDrawPath>.from(previousState['freePaths']);
    selectedShapeId.value = null;
    debugPrint('↶ Undo');
  }
  void onRedo() {
    if (redoStack.isEmpty) return;
    _saveStateForUndo();
    final nextState = redoStack.removeLast();
    shapes.value = List<ShapeObject>.from(nextState['shapes']);
    freePaths.value = List<FreeDrawPath>.from(nextState['freePaths']);
    selectedShapeId.value = null;
    debugPrint('↷ Redo');
  }
  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;
  void onInfoTap() {
    showHelp.value = true;
  }
  void onCloseHelp() {
    showHelp.value = false;
  }
  Future<void> onShareTap() async {
    if (shapes.isEmpty && freePaths.isEmpty) {
      errorToast('Please add at least one shape');
      return;
    }
    if (uiImage.value == null) {
      errorToast('Image not loaded');
      return;
    }
    try {
      isProcessing.value = true;
      final bytes = await _renderShapeCutout();
      if (bytes == null) {
        errorToast('Failed to render image');
        return;
      }
      final dir = await getTemporaryDirectory();
      final fileName =
          'shape_cutout_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      final savedPath = file.path;
      Get.toNamed(
        '/cutout_burst_change_bg',
        arguments: {
          'cutoutImagePath': savedPath,
          'cutoutMode': CutoutMode.shape,
          'imageWidth': uiImage.value!.width,
          'imageHeight': uiImage.value!.height,
          'displayWidth': imageDisplayWidth.value,
          'displayHeight': imageDisplayHeight.value,
        },
      );
    } catch (e) {
      errorToast('Failed to save: $e');
    } finally {
      isProcessing.value = false;
    }
  }
  Future<Uint8List?> _renderShapeCutout() async {
    final image = uiImage.value;
    if (image == null) return null;
    if (imageDisplayWidth.value <= 0 || imageDisplayHeight.value <= 0) {
      return await File(imagePath).readAsBytes();
    }
    try {
      final outputWidth = imageDisplayWidth.value.toInt();
      final outputHeight = imageDisplayHeight.value.toInt();
      debugPrint('🎨 Rendering shape cutout: ${outputWidth}x$outputHeight');
      final maskRecorder = ui.PictureRecorder();
      final maskCanvas = Canvas(
        maskRecorder,
        Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
      );
      final paint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final displayRect = Rect.fromLTWH(
        imageDisplayLeft.value,
        imageDisplayTop.value,
        imageDisplayWidth.value,
        imageDisplayHeight.value,
      );
      final scaleX = outputWidth / imageDisplayWidth.value;
      final scaleY = outputHeight / imageDisplayHeight.value;
      for (final shape in shapes) {
        _drawShapeOnMask(maskCanvas, shape, displayRect, scaleX, scaleY, paint);
      }
      for (final path in freePaths) {
        _drawFreePathOnMask(
            maskCanvas, path, displayRect, scaleX, scaleY, paint);
      }
      final maskPicture = maskRecorder.endRecording();
      final maskImage = await maskPicture.toImage(outputWidth, outputHeight);
      maskPicture.dispose();
      final resultRecorder = ui.PictureRecorder();
      final resultCanvas = Canvas(
        resultRecorder,
        Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
      );
      final srcRect = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final dstRect = Rect.fromLTWH(
        0,
        0,
        outputWidth.toDouble(),
        outputHeight.toDouble(),
      );
      resultCanvas.drawImageRect(image, srcRect, dstRect, Paint());
      resultCanvas.saveLayer(dstRect, Paint()..blendMode = ui.BlendMode.dstIn);
      resultCanvas.drawImageRect(
        maskImage,
        Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
        dstRect,
        Paint(),
      );
      resultCanvas.restore();
      maskImage.dispose();
      final resultPicture = resultRecorder.endRecording();
      final resultImage =
          await resultPicture.toImage(outputWidth, outputHeight);
      resultPicture.dispose();
      final byteData =
          await resultImage.toByteData(format: ui.ImageByteFormat.png);
      resultImage.dispose();
      if (byteData == null) return null;
      debugPrint('✅ Shape cutout rendered successfully');
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('❌ Render error: $e');
      return null;
    }
  }
  void _drawShapeOnMask(
    Canvas canvas,
    ShapeObject shape,
    Rect displayRect,
    double scaleX,
    double scaleY,
    Paint paint,
  ) {
    canvas.save();
    final x = (shape.position.dx - displayRect.left) * scaleX;
    final y = (shape.position.dy - displayRect.top) * scaleY;
    canvas.translate(x, y);
    canvas.rotate(shape.rotation);
    final baseSize = 100.0 * shape.scale;
    final scaledSize = baseSize * scaleX;
    final path = _getShapePathForMask(shape.shapeIndex, scaledSize);
    canvas.drawPath(path, paint);
    canvas.restore();
  }
  void _drawFreePathOnMask(
    Canvas canvas,
    FreeDrawPath path,
    Rect displayRect,
    double scaleX,
    double scaleY,
    Paint paint,
  ) {
    if (path.points.isEmpty) return;
    final pathObj = ui.Path();
    for (var i = 0; i < path.points.length; i++) {
      final x = (path.points[i].dx - displayRect.left) * scaleX;
      final y = (path.points[i].dy - displayRect.top) * scaleY;
      if (i == 0) {
        pathObj.moveTo(x, y);
      } else {
        pathObj.lineTo(x, y);
      }
    }
    pathObj.close();
    canvas.drawPath(pathObj, paint);
  }
  ui.Path _getShapePathForMask(int shapeIndex, double size) {
    final path = ui.Path();
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
  ui.Path _createZigzagCircle(double size) {
    final path = ui.Path();
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
  ui.Path _createWaveCircle(double size) {
    final path = ui.Path();
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
  ui.Path _createGearCircle(double size) {
    final path = ui.Path();
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
  ui.Path _createRoundedRect(double size, double cornerRadius) {
    final path = ui.Path();
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
  ui.Path _createStar(double size, int points) {
    final path = ui.Path();
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
  ui.Path _createHeart(double size) {
    final path = ui.Path();
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
    path.cubicTo(0, -50 * scale, 0, -30 * scale, 0, -30 * scale);
    path.cubicTo(0, -30 * scale, 0, -50 * scale, 25 * scale, -50 * scale);
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
  ui.Path _createDiamond(double size) {
    final path = ui.Path();
    final half = size / 2;
    path.moveTo(0, -half);
    path.lineTo(half, 0);
    path.lineTo(0, half);
    path.lineTo(-half, 0);
    path.close();
    return path;
  }
  ui.Path _createArrow(double size) {
    final path = ui.Path();
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
  ui.Path _createCloud(double size) {
    final path = ui.Path();
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
  ui.Path _createFlower(double size) {
    final path = ui.Path();
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
  void onBackTap() => Get.back();
}
