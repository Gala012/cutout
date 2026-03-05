import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../utils/index.dart';
import '../../db_cutout_burst/data.dart';
import '../../db_cutout_burst/db_cutout_burst_entity.dart';
class TextObject {
  String id;
  String content;
  Offset position;
  double scale;
  double rotation;
  Color color;
  double letterSpacing;
  TextObject({
    required this.id,
    required this.content,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.color = Colors.white,
    this.letterSpacing = 0.0,
  });
  TextObject copyWith({
    String? id,
    String? content,
    Offset? position,
    double? scale,
    double? rotation,
    Color? color,
    double? letterSpacing,
  }) {
    return TextObject(
      id: id ?? this.id,
      content: content ?? this.content,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      color: color ?? this.color,
      letterSpacing: letterSpacing ?? this.letterSpacing,
    );
  }
}
class LightParams {
  double brightness;
  double contrast;
  double red;
  double green;
  double blue;
  LightParams({
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.red = 0.0,
    this.green = 0.0,
    this.blue = 0.0,
  });
  LightParams copyWith({
    double? brightness,
    double? contrast,
    double? red,
    double? green,
    double? blue,
  }) {
    return LightParams(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      red: red ?? this.red,
      green: green ?? this.green,
      blue: blue ?? this.blue,
    );
  }
  bool get isDefault =>
      brightness == 0.0 &&
      contrast == 0.0 &&
      red == 0.0 &&
      green == 0.0 &&
      blue == 0.0;
}
class CutoutBurstEdgeTextLogic extends GetxController {
  final String imagePath = Get.arguments?['imagePath'] ?? '';
  final int cropOriginX = Get.arguments?['cropOriginX'] ?? 0;
  final int cropOriginY = Get.arguments?['cropOriginY'] ?? 0;
  final int origWidth = Get.arguments?['origWidth'] ?? 0;
  final int origHeight = Get.arguments?['origHeight'] ?? 0;
  final double cropBoxWidth = Get.arguments?['cropBoxWidth'] ?? 0.0;
  final double cropBoxHeight = Get.arguments?['cropBoxHeight'] ?? 0.0;
  final uiImage = Rx<ui.Image?>(null);
  final processedImage = Rx<ui.Image?>(null);
  final imageDisplayLeft = 0.0.obs;
  final imageDisplayTop = 0.0.obs;
  final imageDisplayWidth = 0.0.obs;
  final imageDisplayHeight = 0.0.obs;
  final selectedTool = ''.obs;
  final lightParams = LightParams().obs;
  final filterLabels = [
    'Original',
    'Vivid',
    'Grayscale',
    'Spotlight',
    'Red Tint',
    'Blue Tint',
  ];
  final selectedFilter = 0.obs;
  static const edgeLabels = [
    'None',
    'Zigzag',
    'Wave',
    'Gear',
    'Round',
    'Rect',
    'Soft',
    'Star',
    'Heart',
    'Diamond',
  ];
  final selectedEdge = 0.obs;
  final textObjects = <TextObject>[].obs;
  final selectedTextId = Rx<String?>(null);
  final textColors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];
  final randomTexts = [
    'HELLO',
    'LOVE',
    'SMILE',
    'DREAM',
    'HOPE',
    'HAPPY',
    'AMAZING',
    'BEAUTIFUL',
    'CREATIVE',
    'AWESOME',
  ];
  final undoStack = <Map<String, dynamic>>[].obs;
  final redoStack = <Map<String, dynamic>>[].obs;
  final showHelp = false.obs;
  final isZoomed = false.obs;
  final isProcessing = false.obs;
  final isApplyingEffects = false.obs;
  Timer? _effectsDebounceTimer;
  bool _isApplyingEffectsFlag = false;
  bool _pendingUndoSave = false;
  String? _draggedTextId;
  String? _dragHandleType;
  Offset? _dragStartPosition;
  Offset? _dragStartTextPosition;
  double _lastPinchScale = 1.0;
  double _lastRotation = 0.0;
  @override
  void onInit() {
    super.onInit();
    _loadImage();
  }
  @override
  void onClose() {
    _effectsDebounceTimer?.cancel();
    final img = uiImage.value;
    if (img != null && !img.debugDisposed) {
      img.dispose();
    }
    final processedImg = processedImage.value;
    if (processedImg != null &&
        processedImg != img &&
        !processedImg.debugDisposed) {
      processedImg.dispose();
    }
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
      processedImage.value = frame.image;
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
      final imageAspectRatio = image.width / image.height;
      final canvasAspectRatio = canvasSize.width / canvasSize.height;
      if (imageAspectRatio > canvasAspectRatio) {
        w = canvasSize.width * 0.9;
        h = w / imageAspectRatio;
      } else {
        h = canvasSize.height * 0.85;
        w = h * imageAspectRatio;
      }
      l = (canvasSize.width - w) / 2;
      t = (canvasSize.height - h) / 2;
    }
    return Rect.fromLTWH(l, t, w, h);
  }
  void onToolSelect(String tool) {
    selectedTool.value = selectedTool.value == tool ? '' : tool;
  }
  void onLightReset() {
    _saveStateForUndo();
    lightParams.value = LightParams();
    _applyEffectsDebounced(saveUndo: false);
  }
  void onBrightnessAdjust(double delta) {
    final current = lightParams.value.brightness;
    lightParams.value = lightParams.value.copyWith(
      brightness: (current + delta).clamp(-1.0, 1.0),
    );
    _applyEffectsDebounced(saveUndo: true);
  }
  void onContrastAdjust(double delta) {
    final current = lightParams.value.contrast;
    lightParams.value = lightParams.value.copyWith(
      contrast: (current + delta).clamp(-1.0, 1.0),
    );
    _applyEffectsDebounced(saveUndo: true);
  }
  void onRedAdjust(double delta) {
    final current = lightParams.value.red;
    lightParams.value = lightParams.value.copyWith(
      red: (current + delta).clamp(-1.0, 1.0),
    );
    _applyEffectsDebounced(saveUndo: true);
  }
  void onGreenAdjust(double delta) {
    final current = lightParams.value.green;
    lightParams.value = lightParams.value.copyWith(
      green: (current + delta).clamp(-1.0, 1.0),
    );
    _applyEffectsDebounced(saveUndo: true);
  }
  void onBlueAdjust(double delta) {
    final current = lightParams.value.blue;
    lightParams.value = lightParams.value.copyWith(
      blue: (current + delta).clamp(-1.0, 1.0),
    );
    _applyEffectsDebounced(saveUndo: true);
  }
  void _applyEffectsDebounced({bool saveUndo = false}) {
    if (saveUndo && !_pendingUndoSave && _effectsDebounceTimer == null) {
      _saveStateForUndo();
      _pendingUndoSave = true;
    }
    _effectsDebounceTimer?.cancel();
    isApplyingEffects.value = true;
    _effectsDebounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (!_isApplyingEffectsFlag) {
        _pendingUndoSave = false;
        _applyEffects();
      }
    });
  }
  void onFilterSelect(int index) {
    _saveStateForUndo();
    selectedFilter.value = index;
    isApplyingEffects.value = true;
    _applyEffects();
  }
  void onEdgeSelect(int index) {
    _saveStateForUndo();
    selectedEdge.value = index;
  }
  Future<void> onAddText() async {
    final controller = TextEditingController();
    final result = await Get.dialog<String>(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: const Text('Add Text', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter text...',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white38),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Get.back(result: controller.text),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      _addTextToImage(result);
    }
  }
  void onRandomText() {
    final random = Random();
    final text = randomTexts[random.nextInt(randomTexts.length)];
    _addTextToImage(text);
  }
  void _addTextToImage(String content) {
    if (imageDisplayWidth.value == 0 || imageDisplayHeight.value == 0) return;
    _saveStateForUndo();
    final centerX = imageDisplayLeft.value + imageDisplayWidth.value / 2;
    final centerY = imageDisplayTop.value + imageDisplayHeight.value / 2;
    final textObj = TextObject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      position: Offset(centerX, centerY),
      scale: 1.0,
      rotation: 0.0,
      color: Colors.white,
      letterSpacing: 0.0,
    );
    textObjects.add(textObj);
    selectedTextId.value = textObj.id;
    debugPrint('✅ Text added: "$content" at ($centerX, $centerY)');
  }
  Future<void> onEditText() async {
    final textId = selectedTextId.value;
    if (textId == null) return;
    final index = textObjects.indexWhere((t) => t.id == textId);
    if (index == -1) return;
    final textObj = textObjects[index];
    final controller = TextEditingController(text: textObj.content);
    final result = await Get.dialog<String>(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: const Text('Edit Text', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter text...',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white38),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Get.back(result: controller.text),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      _saveStateForUndo();
      textObjects[index] = textObj.copyWith(content: result);
      debugPrint('✅ Text edited: "$result"');
    }
  }
  void onTextColorChange(Color color) {
    final textId = selectedTextId.value;
    if (textId == null) return;
    final index = textObjects.indexWhere((t) => t.id == textId);
    if (index == -1) return;
    _saveStateForUndo();
    textObjects[index] = textObjects[index].copyWith(color: color);
  }
  void onLetterSpacingAdjust(double delta) {
    final textId = selectedTextId.value;
    if (textId == null) return;
    final index = textObjects.indexWhere((t) => t.id == textId);
    if (index == -1) return;
    _saveStateForUndo();
    final current = textObjects[index].letterSpacing;
    textObjects[index] = textObjects[index].copyWith(
      letterSpacing: (current + delta).clamp(-5.0, 10.0),
    );
  }
  void onTextTap(String textId) {
    selectedTextId.value = textId;
  }
  void onDeselectText() {
    selectedTextId.value = null;
  }
  void onTextHandleDragStart(
      String textId, String handleType, Offset position) {
    final index = textObjects.indexWhere((t) => t.id == textId);
    if (index == -1) return;
    _draggedTextId = textId;
    _dragHandleType = handleType;
    _dragStartPosition = position;
    final textObj = textObjects[index];
    _dragStartTextPosition = textObj.position;
    debugPrint('🎯 Text drag start: $handleType for text $textId');
  }
  void onTextHandleDragUpdate(Offset currentPosition) {
    if (_draggedTextId == null || _dragStartPosition == null) return;
    final index = textObjects.indexWhere((t) => t.id == _draggedTextId);
    if (index == -1) return;
    final textObj = textObjects[index];
    final delta = currentPosition - _dragStartPosition!;
    switch (_dragHandleType) {
      case 'move':
        final newPosition = _dragStartTextPosition! + delta;
        textObjects[index] = textObj.copyWith(position: newPosition);
        break;
    }
  }
  void onTextHandleDragEnd() {
    if (_draggedTextId != null) {
      _checkTextOutOfBounds(_draggedTextId!);
    }
    _draggedTextId = null;
    _dragHandleType = null;
    _dragStartPosition = null;
    _dragStartTextPosition = null;
    _lastPinchScale = 1.0;
    _lastRotation = 0.0;
    debugPrint('🎯 Text drag end');
  }
  void onTextPinchScale(String textId, double currentScale) {
    final index = textObjects.indexWhere((t) => t.id == textId);
    if (index == -1) return;
    final textObj = textObjects[index];
    final scaleDelta = currentScale / _lastPinchScale;
    final newScale = (textObj.scale * scaleDelta).clamp(0.3, 4.0);
    textObjects[index] = textObj.copyWith(scale: newScale);
    _lastPinchScale = currentScale;
  }
  void onTextPinchRotate(String textId, double currentRotation) {
    final index = textObjects.indexWhere((t) => t.id == textId);
    if (index == -1) return;
    final textObj = textObjects[index];
    final rotationDelta = currentRotation - _lastRotation;
    final newRotation = textObj.rotation + rotationDelta;
    textObjects[index] = textObj.copyWith(rotation: newRotation);
    _lastRotation = currentRotation;
  }
  void resetTextPinchGestures() {
    _lastPinchScale = 1.0;
    _lastRotation = 0.0;
  }
  void _checkTextOutOfBounds(String textId) {
    final index = textObjects.indexWhere((t) => t.id == textId);
    if (index == -1) return;
    final textObj = textObjects[index];
    final rect = Rect.fromLTWH(
      imageDisplayLeft.value - 100,
      imageDisplayTop.value - 100,
      imageDisplayWidth.value + 200,
      imageDisplayHeight.value + 200,
    );
    if (!rect.contains(textObj.position)) {
      textObjects.removeAt(index);
      if (selectedTextId.value == textId) {
        selectedTextId.value = null;
      }
      debugPrint('🗑️ Text removed (out of bounds)');
    }
  }
  Future<void> _applyEffects() async {
    final image = uiImage.value;
    if (image == null) {
      isApplyingEffects.value = false;
      return;
    }
    if (_isApplyingEffectsFlag) {
      debugPrint('⏸️ Effect application already in progress, skipping...');
      return;
    }
    _isApplyingEffectsFlag = true;
    isApplyingEffects.value = true;
    try {
      if (selectedFilter.value == 0 && !lightParams.value.isDefault) {
        await _applyEffectsOptimized();
      } else {
        await _applyEffectsFull();
      }
    } catch (e) {
      debugPrint('❌ Effect apply error: $e');
    } finally {
      _isApplyingEffectsFlag = false;
      isApplyingEffects.value = false;
    }
  }
  Future<void> _applyEffectsFull() async {
    final image = uiImage.value;
    if (image == null) return;
    debugPrint(
        '🎨 Applying full effects: brightness=${lightParams.value.brightness}, contrast=${lightParams.value.contrast}');
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();
    final processedBytes = await _processImageInIsolate(
      bytes,
      lightParams.value,
      selectedFilter.value,
    );
    if (processedBytes == null) return;
    final codec = await ui.instantiateImageCodec(processedBytes);
    final frame = await codec.getNextFrame();
    final oldProcessed = processedImage.value;
    if (oldProcessed != null &&
        oldProcessed != uiImage.value &&
        !oldProcessed.debugDisposed) {
      oldProcessed.dispose();
    }
    processedImage.value = frame.image;
    codec.dispose();
    debugPrint('✅ Full effects applied successfully');
  }
  Future<void> _applyEffectsOptimized() async {
    final image = uiImage.value;
    if (image == null) return;
    debugPrint(
        '🎨 Applying optimized effects: brightness=${lightParams.value.brightness}, contrast=${lightParams.value.contrast}');
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();
    final processedBytes = await _processImageInIsolate(
      bytes,
      lightParams.value,
      0,
    );
    if (processedBytes == null) return;
    final codec = await ui.instantiateImageCodec(processedBytes);
    final frame = await codec.getNextFrame();
    final oldProcessed = processedImage.value;
    if (oldProcessed != null &&
        oldProcessed != uiImage.value &&
        !oldProcessed.debugDisposed) {
      oldProcessed.dispose();
    }
    processedImage.value = frame.image;
    codec.dispose();
    debugPrint('✅ Optimized effects applied successfully');
  }
  Future<Uint8List?> _processImageInIsolate(
    Uint8List imageBytes,
    LightParams params,
    int filterIndex,
  ) async {
    final receivePort = ReceivePort();
    final isolateData = {
      'imageBytes': imageBytes,
      'brightness': params.brightness,
      'contrast': params.contrast,
      'red': params.red,
      'green': params.green,
      'blue': params.blue,
      'filterIndex': filterIndex,
      'sendPort': receivePort.sendPort,
    };
    try {
      await Isolate.spawn(_imageProcessingIsolate, isolateData);
      final result = await receivePort.first as Uint8List?;
      return result;
    } catch (e) {
      debugPrint('❌ Isolate processing error: $e');
      return null;
    }
  }
  static void _imageProcessingIsolate(Map<String, dynamic> data) {
    final imageBytes = data['imageBytes'] as Uint8List;
    final brightness = data['brightness'] as double;
    final contrast = data['contrast'] as double;
    final red = data['red'] as double;
    final green = data['green'] as double;
    final blue = data['blue'] as double;
    final filterIndex = data['filterIndex'] as int;
    final sendPort = data['sendPort'] as SendPort;
    try {
      img.Image? imgImage = img.decodeImage(imageBytes);
      if (imgImage == null) {
        sendPort.send(null);
        return;
      }
      final hasLightParams = brightness != 0.0 ||
          contrast != 0.0 ||
          red != 0.0 ||
          green != 0.0 ||
          blue != 0.0;
      if (hasLightParams) {
        imgImage = _applyLightParamsStatic(
            imgImage, brightness, contrast, red, green, blue);
      }
      if (filterIndex > 0) {
        imgImage = _applyFilterStatic(imgImage, filterIndex);
      }
      final processedBytes = img.encodePng(imgImage);
      sendPort.send(processedBytes);
    } catch (e) {
      sendPort.send(null);
    }
  }
  static img.Image _applyLightParamsStatic(
    img.Image image,
    double brightness,
    double contrast,
    double red,
    double green,
    double blue,
  ) {
    if (brightness != 0.0) {
      final brightnessValue = (brightness * 30).toInt();
      image = img.adjustColor(image, brightness: brightnessValue.toDouble());
    }
    if (contrast != 0.0) {
      final contrastValue = 1.0 + (contrast * 0.5);
      image = img.adjustColor(image, contrast: contrastValue);
    }
    if (red != 0.0 || green != 0.0 || blue != 0.0) {
      final redValue = (red * 30).toInt();
      final greenValue = (green * 30).toInt();
      final blueValue = (blue * 30).toInt();
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final r = (pixel.r + redValue).clamp(0, 255).toInt();
          final g = (pixel.g + greenValue).clamp(0, 255).toInt();
          final b = (pixel.b + blueValue).clamp(0, 255).toInt();
          image.setPixelRgba(x, y, r, g, b, pixel.a.toInt());
        }
      }
    }
    return image;
  }
  static img.Image _applyFilterStatic(img.Image image, int filterIndex) {
    switch (filterIndex) {
      case 1:
        return img.adjustColor(image, saturation: 1.5, contrast: 1.2);
      case 2:
        return img.grayscale(image);
      case 3:
        return img.adjustColor(image, brightness: 20, contrast: 1.1);
      case 4:
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x++) {
            final pixel = image.getPixel(x, y);
            final r = (pixel.r * 1.3).clamp(0, 255).toInt();
            image.setPixelRgba(
                x, y, r, pixel.g.toInt(), pixel.b.toInt(), pixel.a.toInt());
          }
        }
        return image;
      case 5:
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x++) {
            final pixel = image.getPixel(x, y);
            final b = (pixel.b * 1.3).clamp(0, 255).toInt();
            image.setPixelRgba(
                x, y, pixel.r.toInt(), pixel.g.toInt(), b, pixel.a.toInt());
          }
        }
        return image;
      default:
        return image;
    }
  }
  void _saveStateForUndo() {
    final state = {
      'lightParams': lightParams.value.copyWith(),
      'selectedFilter': selectedFilter.value,
      'selectedEdge': selectedEdge.value,
      'textObjects': textObjects.map((t) => t.copyWith()).toList(),
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
      'lightParams': lightParams.value.copyWith(),
      'selectedFilter': selectedFilter.value,
      'selectedEdge': selectedEdge.value,
      'textObjects': textObjects.map((t) => t.copyWith()).toList(),
    };
    redoStack.add(currentState);
    final previousState = undoStack.removeLast();
    lightParams.value = previousState['lightParams'] as LightParams;
    selectedFilter.value = previousState['selectedFilter'] as int;
    selectedEdge.value = previousState['selectedEdge'] as int;
    textObjects.value = List<TextObject>.from(previousState['textObjects']);
    selectedTextId.value = null;
    _applyEffects();
    debugPrint('↶ Undo');
  }
  void onRedo() {
    if (redoStack.isEmpty) return;
    _saveStateForUndo();
    final nextState = redoStack.removeLast();
    lightParams.value = nextState['lightParams'] as LightParams;
    selectedFilter.value = nextState['selectedFilter'] as int;
    selectedEdge.value = nextState['selectedEdge'] as int;
    textObjects.value = List<TextObject>.from(nextState['textObjects']);
    selectedTextId.value = null;
    _applyEffects();
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
  void onTitleTap() {
    isZoomed.value = !isZoomed.value;
  }
  Future<void> onShareTap() async {
    if (processedImage.value == null) {
      errorToast('Image not loaded');
      return;
    }
    try {
      isProcessing.value = true;
      final bytes = await _renderFinalImage();
      if (bytes == null) {
        errorToast('Failed to render image');
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'edge_text_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await _saveToHistory(file.path);
      successToast('Saved successfully');
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed('/cutout_burst_tab');
    } catch (e) {
      errorToast('Failed to save: $e');
      debugPrint('❌ Save error: $e');
    } finally {
      isProcessing.value = false;
    }
  }
  Future<Uint8List?> _renderFinalImage() async {
    final image = processedImage.value;
    if (image == null) return null;
    try {
      final outputSize = _calculateOutputSize();
      final outputWidth = outputSize.width.toInt();
      final outputHeight = outputSize.height.toInt();
      debugPrint('🎨 Rendering final image: ${outputWidth}x$outputHeight');
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
      );
      canvas.drawRect(
        Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
        Paint()..color = Colors.white,
      );
      if (selectedEdge.value > 0) {
        _drawImageWithEdgeCutout(
            canvas, image, image.width.toDouble(), image.height.toDouble());
      } else {
        final imageRect = Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        );
        canvas.drawImageRect(
          image,
          imageRect,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Paint(),
        );
      }
      final scaleX = image.width / imageDisplayWidth.value;
      final scaleY = image.height / imageDisplayHeight.value;
      for (final textObj in textObjects) {
        _drawTextOnCanvas(canvas, textObj, scaleX, scaleY);
      }
      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(outputWidth, outputHeight);
      picture.dispose();
      final byteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);
      finalImage.dispose();
      if (byteData == null) return null;
      debugPrint('✅ Final image rendered successfully');
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('❌ Render error: $e');
      return null;
    }
  }
  Size _calculateOutputSize() {
    final image = processedImage.value;
    if (image == null) return Size.zero;
    double maxWidth = image.width.toDouble();
    double maxHeight = image.height.toDouble();
    final scaleX = image.width / imageDisplayWidth.value;
    final scaleY = image.height / imageDisplayHeight.value;
    for (final textObj in textObjects) {
      final x = (textObj.position.dx - imageDisplayLeft.value) * scaleX;
      final y = (textObj.position.dy - imageDisplayTop.value) * scaleY;
      final textWidth = textObj.content.length * 20.0 * textObj.scale;
      final textHeight = 40.0 * textObj.scale;
      if (x + textWidth > maxWidth) maxWidth = x + textWidth;
      if (y + textHeight > maxHeight) maxHeight = y + textHeight;
    }
    return Size(maxWidth, maxHeight);
  }
  void _drawImageWithEdgeCutout(
      Canvas canvas, ui.Image image, double width, double height) {
    final shapeIndex = selectedEdge.value - 1;
    final centerX = width / 2;
    final centerY = height / 2;
    final imageAspect = width / height;
    canvas.save();
    canvas.translate(centerX, centerY);
    final pathSize = (width + height) / 2;
    final path = _getEdgeShapePath(
        shapeIndex, pathSize * 0.95, width, height, imageAspect);
    canvas.clipPath(path);
    canvas.translate(-centerX, -centerY);
    final imageRect = Rect.fromLTWH(0, 0, width, height);
    canvas.drawImageRect(image, imageRect, imageRect, Paint());
    canvas.restore();
    canvas.save();
    canvas.translate(centerX, centerY);
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawPath(path, strokePaint);
    canvas.restore();
  }
  Path _getEdgeShapePath(
      int shapeIndex, double size, double width, double height, double aspect) {
    switch (shapeIndex) {
      case 0:
        return _createEdgeZigzag(size, aspect);
      case 1:
        return _createEdgeWave(size, aspect);
      case 2:
        return _createEdgeGear(size, aspect);
      case 3:
        return _createEdgeRoundedRect(width, height, 30);
      case 4:
        return Path()
          ..addRect(Rect.fromCenter(
            center: Offset.zero,
            width: width - 16,
            height: height - 16,
          ));
      case 5:
        return _createEdgeRoundedRect(width, height, 50);
      case 6:
        return _createEdgeStar(size * 0.5, 5);
      case 7:
        return _createEdgeHeart(size * 1);
      case 8:
        return _createEdgeDiamond(size * 0.5);
      default:
        return Path()
          ..addRect(Rect.fromCenter(
            center: Offset.zero,
            width: width - 16,
            height: height - 16,
          ));
    }
  }
  Path _createEdgeZigzag(double size, double aspect) {
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
  Path _createEdgeWave(double size, double aspect) {
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
  Path _createEdgeGear(double size, double aspect) {
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
      width: width - 16,
      height: height - 16,
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
    path.cubicTo(-50 * scale, -15 * scale, -50 * scale, -40 * scale,
        -25 * scale, -40 * scale);
    path.cubicTo(0, -40 * scale, 0, -25 * scale, 0, -25 * scale);
    path.cubicTo(0, -25 * scale, 0, -40 * scale, 25 * scale, -40 * scale);
    path.cubicTo(
        50 * scale, -40 * scale, 50 * scale, -15 * scale, 0, 25 * scale);
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
  void _drawTextOnCanvas(
      Canvas canvas, TextObject textObj, double scaleX, double scaleY) {
    canvas.save();
    final x = (textObj.position.dx - imageDisplayLeft.value) * scaleX;
    final y = (textObj.position.dy - imageDisplayTop.value) * scaleY;
    canvas.translate(x, y);
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
    canvas.restore();
  }
  Future<void> _saveToHistory(String outputPath) async {
    try {
      final history = CutoutHistory(
        resultPath: outputPath,
        thumbnailPath: outputPath,
        cutoutMode: CutoutMode.edgeText,
        createdAt: DateTime.now().toIso8601String(),
      );
      await CutoutBurstDb.to.insertCutoutHistory(history);
      debugPrint('✅ Saved to history database');
    } catch (e) {
      debugPrint('❌ Failed to save to history: $e');
    }
  }
  void onBackTap() => Get.toNamed('/cutout_burst_select_photo');
}
