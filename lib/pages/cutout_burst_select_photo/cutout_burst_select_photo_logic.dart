import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../utils/index.dart';
class PhotoModel {
  final AssetEntity asset;
  final Uint8List? thumbnail;
  PhotoModel({required this.asset, this.thumbnail});
}
class CutoutBurstSelectPhotoLogic extends GetxController {
  final String mode = Get.arguments?['mode'] ?? 'special';
  final photos = <PhotoModel>[].obs;
  final isLoading = false.obs;
  final permissionDenied = false.obs;
  final showInfoOverlay = false.obs;
  String get modeDisplayName {
    switch (mode) {
      case 'special':
        return 'Special Cutout';
      case 'trim':
        return 'Trim Cutout';
      case 'shape':
        return 'Shape Cutout';
      case 'edge_text':
        return 'Edge + Text';
      case 'portrait':
        return 'Portrait Cutout';
      default:
        return 'Cutout';
    }
  }
  @override
  void onInit() {
    super.onInit();
    _requestPermissionAndLoadPhotos();
  }
  Future<void> _requestPermissionAndLoadPhotos() async {
    try {
      final ps = await PhotoManager.requestPermissionExtend();
      if (ps.isAuth || ps.hasAccess) {
        permissionDenied.value = false;
        await _loadPhotos();
      } else {
        permissionDenied.value = true;
      }
    } catch (e) {
      errorToast('Failed to access photos');
    }
  }
  Future<void> _loadPhotos() async {
    try {
      isLoading.value = true;
      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
      );
      if (paths.isEmpty) return;
      final count = await paths[0].assetCountAsync;
      final assets = await paths[0].getAssetListRange(
        start: 0,
        end: count > 300 ? 300 : count,
      );
      photos.clear();
      for (final asset in assets) {
        final thumbnail = await asset.thumbnailDataWithSize(
          const ThumbnailSize(300, 300),
        );
        photos.add(PhotoModel(asset: asset, thumbnail: thumbnail));
      }
    } catch (e) {
      errorToast('Failed to load photos');
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> refreshPhotos() async {
    await _requestPermissionAndLoadPhotos();
  }
  Future<void> onSelectPhoto(PhotoModel model) async {
    try {
      isLoading.value = true;
      final file = await model.asset.file;
      if (file == null) {
        errorToast('Failed to load image');
        return;
      }
      Get.toNamed(
        '/cutout_burst_crop',
        arguments: {'imagePath': file.path, 'mode': mode},
      );
    } catch (e) {
      errorToast('Failed to load image');
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> onOpenGallery() async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: ImageSource.gallery);
      if (xFile != null) {
        Get.toNamed(
          '/cutout_burst_crop',
          arguments: {'imagePath': xFile.path, 'mode': mode},
        );
      }
    } catch (e) {
      errorToast('Failed to open gallery');
    }
  }
  void onInfoTap() => showInfoOverlay.value = !showInfoOverlay.value;
  void onCloseInfo() => showInfoOverlay.value = false;
  void onOpenSettings() => PhotoManager.openSetting();
  void onBackTap() => Get.back();
}
