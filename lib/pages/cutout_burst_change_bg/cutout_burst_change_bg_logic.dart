import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../../db_cutout_burst/data.dart';
import '../../db_cutout_burst/db_cutout_burst_entity.dart';
import '../../utils/index.dart';
enum BgType { color, image }
class CutoutBurstChangeBgLogic extends GetxController {
  final String cutoutImagePath = Get.arguments?['cutoutImagePath'] ?? '';
  final String cutoutMode = Get.arguments?['cutoutMode'] ?? CutoutMode.trim;
  final int imageWidth = Get.arguments?['imageWidth'] ?? 0;
  final int imageHeight = Get.arguments?['imageHeight'] ?? 0;
  final double displayWidth = Get.arguments?['displayWidth'] ?? 0.0;
  final double displayHeight = Get.arguments?['displayHeight'] ?? 0.0;
  final uiImage = Rx<ui.Image?>(null);
  final isLoading = false.obs;
  final isProcessing = false.obs;
  final selectedBgType = BgType.color.obs;
  final selectedColorIndex = 0.obs;
  final selectedImageIndex = 0.obs;
  final imageOffsetX = 0.0.obs;
  final imageOffsetY = 0.0.obs;
  void onPanUpdate(double dx, double dy) {
    imageOffsetX.value += dx;
    imageOffsetY.value += dy;
  }
  void resetImagePosition() {
    imageOffsetX.value = 0.0;
    imageOffsetY.value = 0.0;
  }
  static const colorBackgrounds = [
    Color(0xFFFFFFFF),
    Color(0xFF000000),
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF607D8B),
  ];
  static const imageBackgrounds = [
    'assets/bg/bg-1.jpg',
    'assets/bg/bg-2.jpg',
    'assets/bg/bg-3.jpg',
    'assets/bg/bg-4.jpg',
    'assets/bg/bg-5.jpg',
    'assets/bg/bg-6.jpg',
    'assets/bg/bg-7.jpg',
    'assets/bg/bg-8.jpg',
  ];
  @override
  void onInit() {
    super.onInit();
    if (cutoutImagePath.isNotEmpty) {
      _loadCutoutImage();
    }
  }
  @override
  void onClose() {
    uiImage.value?.dispose();
    super.onClose();
  }
  Future<void> _loadCutoutImage() async {
    try {
      isLoading.value = true;
      final file = File(cutoutImagePath);
      if (!await file.exists()) {
        errorToast('Image not found');
        return;
      }
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      uiImage.value?.dispose();
      uiImage.value = frame.image;
      codec.dispose();
      debugPrint(
          '✅ Loaded cutout image: ${frame.image.width}x${frame.image.height}');
    } catch (e) {
      errorToast('Failed to load image');
      debugPrint('Error loading cutout image: $e');
    } finally {
      isLoading.value = false;
    }
  }
  void selectColorBackground(int index) {
    selectedBgType.value = BgType.color;
    selectedColorIndex.value = index;
  }
  void selectImageBackground(int index) {
    selectedBgType.value = BgType.image;
    selectedImageIndex.value = index;
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
      final fileName = 'cutout_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await _saveToDatabase(file.path);
      successToast('Saved successfully');
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed('/cutout_burst_tab');
    } catch (e) {
      errorToast('Save failed: $e');
      debugPrint('Error saving: $e');
    } finally {
      isProcessing.value = false;
    }
  }
  Future<Uint8List?> _renderFinalImage() async {
    final image = uiImage.value;
    if (image == null) return null;
    final imgW = image.width;
    final imgH = image.height;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, imgW.toDouble(), imgH.toDouble()),
    );
    if (selectedBgType.value == BgType.color) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, imgW.toDouble(), imgH.toDouble()),
        Paint()..color = colorBackgrounds[selectedColorIndex.value],
      );
    } else {
      final bgImage = await _loadBackgroundImage(
        imageBackgrounds[selectedImageIndex.value],
      );
      if (bgImage != null) {
        final srcRect = Rect.fromLTWH(
          0,
          0,
          bgImage.width.toDouble(),
          bgImage.height.toDouble(),
        );
        final dstRect = Rect.fromLTWH(0, 0, imgW.toDouble(), imgH.toDouble());
        canvas.drawImageRect(bgImage, srcRect, dstRect, Paint());
        bgImage.dispose();
      }
    }
    canvas.drawImage(image, Offset.zero, Paint());
    final picture = recorder.endRecording();
    final finalImage = await picture.toImage(imgW, imgH);
    final byteData =
        await finalImage.toByteData(format: ui.ImageByteFormat.png);
    finalImage.dispose();
    picture.dispose();
    return byteData?.buffer.asUint8List();
  }
  Future<ui.Image?> _loadBackgroundImage(String assetPath) async {
    try {
      final data = await DefaultAssetBundle.of(Get.context!).load(assetPath);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    } catch (e) {
      debugPrint('Error loading background image: $e');
      return null;
    }
  }
  Future<void> _saveToDatabase(String resultPath) async {
    try {
      final db = CutoutBurstDb.to;
      final now = DateTime.now();
      final history = CutoutHistory(
        resultPath: resultPath,
        thumbnailPath: resultPath,
        cutoutMode: cutoutMode,
        createdAt:
            '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} '
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      );
      await db.insertCutoutHistory(history);
    } catch (e) {
      debugPrint('DB save failed: $e');
    }
  }
}
