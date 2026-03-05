import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/index.dart';
class CutoutBurstCropLogic extends GetxController {
  final String mode = Get.arguments?['mode'] ?? 'special';
  final String imagePath = Get.arguments?['imagePath'] ?? '';
  final selectedRatio = 'Free'.obs;
  final isProcessing = false.obs;
  Rx<File?> imageFile = Rx<File?>(null);
  final imageWidth = 0.obs;
  final imageHeight = 0.obs;
  final cropBoxLeft = 0.0.obs;
  final cropBoxTop = 0.0.obs;
  final cropBoxWidth = 0.0.obs;
  final cropBoxHeight = 0.0.obs;
  final containerWidth = 0.0.obs;
  final containerHeight = 0.0.obs;
  final imageDisplayLeft = 0.0.obs;
  final imageDisplayTop = 0.0.obs;
  final imageDisplayWidth = 0.0.obs;
  final imageDisplayHeight = 0.0.obs;
  late TransformationController transformationController;
  static const ratios = [
    'Free',
    '1:1',
    '2:3',
    '3:4',
    '4:5',
    '9:16',
    '16:9',
    '3:2',
    '4:3',
    '5:4',
  ];
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
      imageWidth.value = frame.image.width;
      imageHeight.value = frame.image.height;
      imageFile.value = file;
      frame.image.dispose();
      codec.dispose();
    } catch (e) {
      errorToast('Failed to load image');
      Get.back();
    }
  }
  void updateContainerSize(double w, double h) {
    if (containerWidth.value == w && containerHeight.value == h) return;
    containerWidth.value = w;
    containerHeight.value = h;
  }
  void updateImageDisplayRect(Rect rect) {
    imageDisplayLeft.value = rect.left;
    imageDisplayTop.value = rect.top;
    imageDisplayWidth.value = rect.width;
    imageDisplayHeight.value = rect.height;
    if (cropBoxWidth.value == 0 && imageDisplayWidth.value > 0) {
      _initCropBox();
    }
  }
  void _initCropBox() {
    if (containerWidth.value == 0 || containerHeight.value == 0) return;
    _updateCropBoxForRatio();
    cropBoxLeft.value = (containerWidth.value - cropBoxWidth.value) / 2;
    cropBoxTop.value = (containerHeight.value - cropBoxHeight.value) / 2;
    _constrainCropBox();
  }
  void _updateCropBoxForRatio() {
    double aspectRatio = 1.0;
    if (selectedRatio.value == 'Free') {
      if (imageWidth.value > 0 && imageHeight.value > 0) {
        aspectRatio = imageWidth.value / imageHeight.value;
      }
    } else {
      final parts = selectedRatio.value.split(':');
      if (parts.length == 2) {
        final w = double.tryParse(parts[0]) ?? 1.0;
        final h = double.tryParse(parts[1]) ?? 1.0;
        aspectRatio = w / h;
      }
    }
    final maxWidth = containerWidth.value * 0.85;
    final maxHeight = containerHeight.value * 0.7;
    if (aspectRatio >= 1) {
      cropBoxWidth.value = maxWidth;
      cropBoxHeight.value = cropBoxWidth.value / aspectRatio;
      if (cropBoxHeight.value > maxHeight) {
        cropBoxHeight.value = maxHeight;
        cropBoxWidth.value = cropBoxHeight.value * aspectRatio;
      }
    } else {
      cropBoxHeight.value = maxHeight;
      cropBoxWidth.value = cropBoxHeight.value * aspectRatio;
      if (cropBoxWidth.value > maxWidth) {
        cropBoxWidth.value = maxWidth;
        cropBoxHeight.value = cropBoxWidth.value / aspectRatio;
      }
    }
  }
  void onRatioSelect(String ratio) {
    selectedRatio.value = ratio;
    _updateCropBoxForRatio();
    cropBoxLeft.value = (containerWidth.value - cropBoxWidth.value) / 2;
    cropBoxTop.value = (containerHeight.value - cropBoxHeight.value) / 2;
    _constrainCropBox();
  }
  Offset? _lastFocalPoint;
  void onCropBoxScaleStart(ScaleStartDetails d) {
    _lastFocalPoint = d.focalPoint;
  }
  void onCropBoxScaleUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount == 1 && _lastFocalPoint != null) {
      final delta = d.focalPoint - _lastFocalPoint!;
      cropBoxLeft.value += delta.dx;
      cropBoxTop.value += delta.dy;
      _constrainCropBox();
    }
    _lastFocalPoint = d.focalPoint;
  }
  Offset? _resizeStart;
  double? _resizeStartW, _resizeStartH, _resizeStartL, _resizeStartT;
  double? _resizeAR;
  void onCornerResizeStart(Offset pos, String corner) {
    _resizeStart = pos;
    _resizeStartW = cropBoxWidth.value;
    _resizeStartH = cropBoxHeight.value;
    _resizeStartL = cropBoxLeft.value;
    _resizeStartT = cropBoxTop.value;
    if (selectedRatio.value != 'Free' && cropBoxHeight.value > 0) {
      _resizeAR = cropBoxWidth.value / cropBoxHeight.value;
    } else {
      _resizeAR = null;
    }
  }
  void onCornerResizeUpdate(Offset pos, String corner) {
    if (_resizeStart == null ||
        _resizeStartW == null ||
        _resizeStartH == null ||
        _resizeStartL == null ||
        _resizeStartT == null) {
      return;
    }
    final delta = pos - _resizeStart!;
    const minSize = 50.0;
    double newW = _resizeStartW!;
    double newH = _resizeStartH!;
    double newL = _resizeStartL!;
    double newT = _resizeStartT!;
    if (_resizeAR != null) {
      switch (corner) {
        case 'topLeft':
          final avgDelta = -(delta.dx + delta.dy) / 2;
          newW = (_resizeStartW! + avgDelta).clamp(
            minSize,
            double.infinity,
          );
          newH = newW / _resizeAR!;
          newL = _resizeStartL! + (_resizeStartW! - newW);
          newT = _resizeStartT! + (_resizeStartH! - newH);
          break;
        case 'topRight':
          final avgDelta = (delta.dx - delta.dy) / 2;
          newW = (_resizeStartW! + avgDelta).clamp(
            minSize,
            double.infinity,
          );
          newH = newW / _resizeAR!;
          newT = _resizeStartT! + (_resizeStartH! - newH);
          break;
        case 'bottomLeft':
          final avgDelta = (-delta.dx + delta.dy) / 2;
          newW = (_resizeStartW! + avgDelta).clamp(
            minSize,
            double.infinity,
          );
          newH = newW / _resizeAR!;
          newL = _resizeStartL! + (_resizeStartW! - newW);
          break;
        case 'bottomRight':
          final avgDelta = (delta.dx + delta.dy) / 2;
          newW = (_resizeStartW! + avgDelta).clamp(
            minSize,
            double.infinity,
          );
          newH = newW / _resizeAR!;
          break;
      }
    } else {
      switch (corner) {
        case 'topLeft':
          newW = (_resizeStartW! - delta.dx).clamp(minSize, double.infinity);
          newH = (_resizeStartH! - delta.dy).clamp(minSize, double.infinity);
          newL = _resizeStartL! + (_resizeStartW! - newW);
          newT = _resizeStartT! + (_resizeStartH! - newH);
          break;
        case 'topRight':
          newW = (_resizeStartW! + delta.dx).clamp(minSize, double.infinity);
          newH = (_resizeStartH! - delta.dy).clamp(minSize, double.infinity);
          newT = _resizeStartT! + (_resizeStartH! - newH);
          break;
        case 'bottomLeft':
          newW = (_resizeStartW! - delta.dx).clamp(minSize, double.infinity);
          newH = (_resizeStartH! + delta.dy).clamp(minSize, double.infinity);
          newL = _resizeStartL! + (_resizeStartW! - newW);
          break;
        case 'bottomRight':
          newW = (_resizeStartW! + delta.dx).clamp(minSize, double.infinity);
          newH = (_resizeStartH! + delta.dy).clamp(minSize, double.infinity);
          break;
      }
    }
    final maxW = imageDisplayWidth.value;
    final maxH = imageDisplayHeight.value;
    if (maxW > 0 && newW > maxW) {
      newW = maxW;
      if (_resizeAR != null) {
        newH = newW / _resizeAR!;
      }
    }
    if (maxH > 0 && newH > maxH) {
      newH = maxH;
      if (_resizeAR != null) {
        newW = newH * _resizeAR!;
      }
    }
    cropBoxWidth.value = newW;
    cropBoxHeight.value = newH;
    cropBoxLeft.value = newL;
    cropBoxTop.value = newT;
    _constrainCropBox();
  }
  void onCornerResizeEnd() {
    _resizeStart = null;
    _resizeStartW = null;
    _resizeStartH = null;
    _resizeStartL = null;
    _resizeStartT = null;
    _resizeAR = null;
  }
  void _constrainCropBox() {
    if (containerWidth.value == 0 || containerHeight.value == 0) return;
    final minLeft = imageDisplayLeft.value;
    final minTop = imageDisplayTop.value;
    final maxLeft =
        imageDisplayLeft.value + imageDisplayWidth.value - cropBoxWidth.value;
    final maxTop =
        imageDisplayTop.value + imageDisplayHeight.value - cropBoxHeight.value;
    cropBoxLeft.value = cropBoxLeft.value.clamp(minLeft, maxLeft);
    cropBoxTop.value = cropBoxTop.value.clamp(minTop, maxTop);
  }
  Rect convertScreenToImageCoordinates() {
    final matrix = transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final translation = matrix.getTranslation();
    debugPrint('=== Crop Conversion Debug ===');
    debugPrint(
        'Scale: $scale, Translation: ${translation.x}, ${translation.y}');
    debugPrint(
      'Image display: L=${imageDisplayLeft.value}, T=${imageDisplayTop.value}, W=${imageDisplayWidth.value}, H=${imageDisplayHeight.value}',
    );
    debugPrint(
      'Crop box: L=${cropBoxLeft.value}, T=${cropBoxTop.value}, W=${cropBoxWidth.value}, H=${cropBoxHeight.value}',
    );
    debugPrint('Image original: W=${imageWidth.value}, H=${imageHeight.value}');
    final cropBoxInOriginalCoords = Rect.fromLTWH(
      (cropBoxLeft.value - translation.x) / scale,
      (cropBoxTop.value - translation.y) / scale,
      cropBoxWidth.value / scale,
      cropBoxHeight.value / scale,
    );
    debugPrint(
      'Crop box in original coords: ${cropBoxInOriginalCoords.left}, ${cropBoxInOriginalCoords.top}, ${cropBoxInOriginalCoords.width}, ${cropBoxInOriginalCoords.height}',
    );
    final relativeLeft = cropBoxInOriginalCoords.left - imageDisplayLeft.value;
    final relativeTop = cropBoxInOriginalCoords.top - imageDisplayTop.value;
    debugPrint('Relative to image: L=$relativeLeft, T=$relativeTop');
    final scaleX = imageWidth.value / imageDisplayWidth.value;
    final scaleY = imageHeight.value / imageDisplayHeight.value;
    final pixelX = (relativeLeft * scaleX).clamp(
      0.0,
      imageWidth.value.toDouble(),
    );
    final pixelY = (relativeTop * scaleY).clamp(
      0.0,
      imageHeight.value.toDouble(),
    );
    final pixelWidth = (cropBoxInOriginalCoords.width * scaleX).clamp(
      1.0,
      imageWidth.value.toDouble() - pixelX,
    );
    final pixelHeight = (cropBoxInOriginalCoords.height * scaleY).clamp(
      1.0,
      imageHeight.value.toDouble() - pixelY,
    );
    debugPrint(
      'Final pixels: X=$pixelX, Y=$pixelY, W=$pixelWidth, H=$pixelHeight',
    );
    debugPrint('=============================');
    return Rect.fromLTWH(pixelX, pixelY, pixelWidth, pixelHeight);
  }
  void onBackTap() => Get.back();
  Future<void> onCutoutTap() async {
    if (imageFile.value == null) {
      errorToast('No image loaded');
      return;
    }
    if (cropBoxWidth.value < 10 || cropBoxHeight.value < 10) {
      errorToast('Crop area is too small, please adjust');
      return;
    }
    try {
      isProcessing.value = true;
      final cropRect = convertScreenToImageCoordinates();
      final x = cropRect.left.round();
      final y = cropRect.top.round();
      final w = cropRect.width.round();
      final h = cropRect.height.round();
      if (w < 10 || h < 10) {
        errorToast('Crop area is too small');
        isProcessing.value = false;
        return;
      }
      final croppedPath = await _cropImage(imagePath, x, y, w, h);
      if (croppedPath == null) {
        errorToast('Failed to crop image');
        isProcessing.value = false;
        return;
      }
      String routeName;
      switch (mode) {
        case 'trim':
          routeName = '/cutout_burst_trim_cutout';
          break;
        case 'shape':
          routeName = '/cutout_burst_shape_cutout';
          break;
        case 'edge_text':
          routeName = '/cutout_burst_edge_text';
          break;
        case 'portrait':
          routeName = '/cutout_burst_portrait_cutout';
          break;
        default:
          routeName = '/cutout_burst_trim_cutout';
      }
      Get.toNamed(routeName, arguments: {
        'imagePath': croppedPath,
        'cropOriginX': x,
        'cropOriginY': y,
        'origWidth': imageWidth.value,
        'origHeight': imageHeight.value,
        'cropBoxWidth': cropBoxWidth.value,
        'cropBoxHeight': cropBoxHeight.value,
        'cropBoxLeft': cropBoxLeft.value,
        'cropBoxTop': cropBoxTop.value,
      });
    } catch (e) {
      errorToast('Crop failed: $e');
    } finally {
      isProcessing.value = false;
    }
  }
  Future<String?> _cropImage(String path, int x, int y, int w, int h) async {
    try {
      debugPrint('🔧 _cropImage called: x=$x, y=$y, w=$w, h=$h');
      final bytes = await File(path).readAsBytes();
      debugPrint('📂 Original file size: ${bytes.length} bytes');
      const maxDimension = 3840;
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: maxDimension,
        targetHeight: maxDimension,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      debugPrint(
          '📷 Decoded image (with maxDimension): ${image.width} x ${image.height}');
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble()),
        Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        Paint(),
      );
      final picture = recorder.endRecording();
      final croppedImg = await picture.toImage(w, h);
      debugPrint(
          '✂️  Cropped image: ${croppedImg.width} x ${croppedImg.height}');
      final byteData =
          await croppedImg.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      croppedImg.dispose();
      picture.dispose();
      codec.dispose();
      if (byteData == null) {
        debugPrint('❌ byteData is null!');
        return null;
      }
      final dir = await getTemporaryDirectory();
      final tempPath =
          '${dir.path}/crop_temp_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(tempPath).writeAsBytes(byteData.buffer.asUint8List());
      debugPrint('💾 Temp file size: ${await File(tempPath).length()} bytes');
      final compressedPath =
          '${dir.path}/crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        tempPath,
        quality: 85,
        format: CompressFormat.jpeg,
      );
      if (compressedBytes == null) {
        debugPrint('❌ Image compression failed, using original');
        await File(tempPath).delete();
        final fallbackPath = compressedPath.replaceAll('.jpg', '.png');
        await File(fallbackPath).writeAsBytes(byteData.buffer.asUint8List());
        return fallbackPath;
      }
      await File(compressedPath).writeAsBytes(compressedBytes);
      await File(tempPath).delete();
      debugPrint('✅ Compressed image saved: $compressedPath');
      debugPrint('✅ Compressed size: ${compressedBytes.length} bytes');
      debugPrint(
          '📊 Compression ratio: ${((1 - compressedBytes.length / byteData.lengthInBytes) * 100).toStringAsFixed(1)}%');
      return compressedPath;
    } catch (e) {
      debugPrint('❌ _cropImage error: $e');
      return null;
    }
  }
  Rect calcImageDisplayRect(double containerW, double containerH) {
    if (imageWidth.value == 0 || imageHeight.value == 0) {
      return Rect.fromLTWH(0, 0, containerW, containerH);
    }
    final scale =
        min(containerW / imageWidth.value, containerH / imageHeight.value);
    final w = imageWidth.value * scale;
    final h = imageHeight.value * scale;
    final l = (containerW - w) / 2;
    final t = (containerH - h) / 2;
    return Rect.fromLTWH(l, t, w, h);
  }
}
