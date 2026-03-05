import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:path_provider/path_provider.dart';
import '../../db_cutout_burst/data.dart';
import '../../db_cutout_burst/db_cutout_burst_entity.dart';
import '../../utils/index.dart';
class CutoutBurstPortraitCutoutLogic extends GetxController {
  final String imagePath = Get.arguments?['imagePath'] ?? '';
  final double cropBoxWidth = Get.arguments?['cropBoxWidth'] ?? 0.0;
  final double cropBoxHeight = Get.arguments?['cropBoxHeight'] ?? 0.0;
  final selectedBgColor = const Color(0xFF2196F3).obs;
  final isProcessing = RxBool(false);
  final isSegmentationDone = RxBool(false);
  final imageFile = Rx<File?>(null);
  final originalImage = Rx<ui.Image?>(null);
  final segmentedImage = Rx<ui.Image?>(null);
  Uint8List? _segmentationMask;
  final transformationController = TransformationController();
  SelfieSegmenter? _segmenter;
  static const bgColors = [
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFFFFFF),
    Color(0xFF000000),
    Color(0xFF9E9E9E),
  ];
  @override
  void onInit() {
    super.onInit();
    _initSegmenter();
    if (imagePath.isNotEmpty) {
      _loadImage();
    }
  }
  @override
  void onClose() {
    transformationController.dispose();
    originalImage.value?.dispose();
    segmentedImage.value?.dispose();
    _segmenter?.close();
    super.onClose();
  }
  void _initSegmenter() {
    try {
      _segmenter = SelfieSegmenter(
        mode: SegmenterMode.stream,
        enableRawSizeMask: false,
      );
    } catch (e) {
      debugPrint('Failed to init segmenter: $e');
    }
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
      originalImage.value?.dispose();
      originalImage.value = frame.image;
      codec.dispose();
      debugPrint('📷 Loaded Image: ${frame.image.width} x ${frame.image.height}');
      await _performSegmentation();
    } catch (e) {
      errorToast('Failed to load image: $e');
      debugPrint('Error loading image: $e');
    }
  }
  Future<void> onRunCutoutTap() async {
    await _performSegmentation();
  }
  Future<void> _performSegmentation() async {
    if (_segmenter == null) {
      errorToast('Segmenter not initialized');
      return;
    }
    if (imageFile.value == null) {
      errorToast('No image loaded');
      return;
    }
    try {
      isProcessing.value = true;
      final inputImage = InputImage.fromFilePath(imageFile.value!.path);
      final mask = await _segmenter!.processImage(inputImage);
      if (mask == null) {
        errorToast('Segmentation failed');
        return;
      }
      debugPrint('📊 Mask Info: ${mask.width} x ${mask.height}, confidences: ${mask.confidences.length}');
      debugPrint('📷 Image Info: ${originalImage.value?.width} x ${originalImage.value?.height}');
      final maskData = <int>[];
      for (final confidence in mask.confidences) {
        maskData.add((confidence * 255).toInt());
      }
      _segmentationMask = Uint8List.fromList(maskData);
      await _applyMask(mask.width, mask.height);
      isSegmentationDone.value = true;
      successToast('Portrait segmentation completed');
    } catch (e) {
      errorToast('Segmentation failed: $e');
      debugPrint('Segmentation error: $e');
    } finally {
      isProcessing.value = false;
    }
  }
  Future<void> _applyMask(int maskW, int maskH) async {
    final img = originalImage.value;
    final mask = _segmentationMask;
    if (img == null || mask == null) return;
    try {
      final imgW = img.width;
      final imgH = img.height;
      debugPrint('🎭 Applying mask: Image ${imgW}x${imgH}, Mask ${maskW}x${maskH}');
      debugPrint('📦 Crop Box: ${cropBoxWidth}x${cropBoxHeight}');
      final imgByteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (imgByteData == null) return;
      final imgPixels = imgByteData.buffer.asUint8List();
      int outputW = cropBoxWidth.toInt();
      int outputH = cropBoxHeight.toInt();
      if (outputW <= 0 || outputH <= 0) {
        outputW = imgW;
        outputH = imgH;
        debugPrint('⚠️ Using original image size as output size');
      }
      final resultPixels = Uint8List(outputW * outputH * 4);
      const int threshold = 128;
      for (int y = 0; y < outputH; y++) {
        for (int x = 0; x < outputW; x++) {
          final srcX = (x * imgW / outputW).floor().clamp(0, imgW - 1);
          final srcY = (y * imgH / outputH).floor().clamp(0, imgH - 1);
          final maskX = (srcX * maskW / imgW).floor().clamp(0, maskW - 1);
          final maskY = (srcY * maskH / imgH).floor().clamp(0, maskH - 1);
          final maskIndex = maskY * maskW + maskX;
          if (maskIndex >= mask.length) {
            debugPrint('⚠️ Mask index out of bounds: $maskIndex >= ${mask.length}');
            continue;
          }
          final maskValue = mask[maskIndex];
          final srcPixelIndex = (srcY * imgW + srcX) * 4;
          final dstPixelIndex = (y * outputW + x) * 4;
          if (maskValue >= threshold) {
            resultPixels[dstPixelIndex] = imgPixels[srcPixelIndex];
            resultPixels[dstPixelIndex + 1] = imgPixels[srcPixelIndex + 1];
            resultPixels[dstPixelIndex + 2] = imgPixels[srcPixelIndex + 2];
            resultPixels[dstPixelIndex + 3] = 255;
          } else {
            resultPixels[dstPixelIndex] = 0;
            resultPixels[dstPixelIndex + 1] = 0;
            resultPixels[dstPixelIndex + 2] = 0;
            resultPixels[dstPixelIndex + 3] = 0;
          }
        }
      }
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        resultPixels,
        outputW,
        outputH,
        ui.PixelFormat.rgba8888,
        (ui.Image result) {
          completer.complete(result);
        },
      );
      segmentedImage.value?.dispose();
      segmentedImage.value = await completer.future;
      debugPrint('✅ Mask applied successfully (transparent background, ${outputW}x${outputH})');
    } catch (e) {
      errorToast('Error applying mask: $e');
      debugPrint('Error applying mask: $e');
    }
  }
  void onFitToScreenTap() {
    transformationController.value = Matrix4.identity();
  }
  void onZoomInTap() {
    final matrix = transformationController.value.clone();
    final currentScale = matrix.getMaxScaleOnAxis();
    if (currentScale < 4.0) {
      matrix.scale(1.2);
      transformationController.value = matrix;
    }
  }
  void onZoomOutTap() {
    final matrix = transformationController.value.clone();
    final currentScale = matrix.getMaxScaleOnAxis();
    if (currentScale > 0.5) {
      matrix.scale(1 / 1.2);
      transformationController.value = matrix;
    }
  }
  void onBgColorChange(Color color) => selectedBgColor.value = color;
  void onBackTap() => Get.toNamed('/cutout_burst_select_photo');
  void onHelpTap() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: const Text('Portrait Cutout Help',
            style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem('1. Automatic Segmentation',
                  'AI automatically detects and extracts portraits from photos'),
              const SizedBox(height: 12),
              _buildHelpItem('2. Background Preview',
                  'Change background color to check edge quality'),
              const SizedBox(height: 12),
              _buildHelpItem('3. Trim Tools',
                  'Use erase/restore tools to refine edges manually'),
              const SizedBox(height: 12),
              _buildHelpItem(
                  '4. Save', 'Click Save to export transparent background image'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Got it', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
  Widget _buildHelpItem(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(desc,
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }
  Future<void> onSaveTap() async {
    if (segmentedImage.value == null) {
      errorToast('No portrait cutout available');
      return;
    }
    try {
      isProcessing.value = true;
      final image = segmentedImage.value!;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        errorToast('Failed to render image');
        return;
      }
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final fileName = 'portrait_cutout_${DateTime.now().millisecondsSinceEpoch}.png';
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
  Future<void> _saveToDatabase(String resultPath) async {
    try {
      final db = CutoutBurstDb.to;
      final now = DateTime.now();
      final history = CutoutHistory(
        resultPath: resultPath,
        thumbnailPath: resultPath,
        cutoutMode: CutoutMode.portrait,
        createdAt:
            '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} '
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      );
      await db.insertCutoutHistory(history);
      debugPrint('✅ Saved to database: ${history.cutoutMode}');
    } catch (e) {
      debugPrint('DB save failed: $e');
    }
  }
}
