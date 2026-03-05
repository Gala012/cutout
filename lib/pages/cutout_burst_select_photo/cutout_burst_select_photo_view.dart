import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import 'cutout_burst_select_photo_logic.dart';
class CutoutBurstSelectPhotoView extends GetView<CutoutBurstSelectPhotoLogic> {
  const CutoutBurstSelectPhotoView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CutoutBurstColors.bg,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: _buildBody()),
              _buildBottomHint(),
            ],
          ),
          Obx(() => controller.showInfoOverlay.value
              ? _buildInfoOverlay()
              : const SizedBox.shrink()),
        ],
      ),
    );
  }
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Select Image',
      ),
      actions: [
        IconButton(
          onPressed: controller.onInfoTap,
          icon: Icon(
            Icons.info_outline_rounded,
            size: 22.w,
            color: CutoutBurstColors.textSecondary,
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Container(
          height: 1,
          color: CutoutBurstColors.border,
        ),
      ),
    );
  }
  Widget _buildBody() {
    return Obx(() {
      if (controller.permissionDenied.value) {
        return _buildPermissionDenied();
      }
      if (controller.isLoading.value && controller.photos.isEmpty) {
        return _buildLoading();
      }
      return _buildPhotoGrid();
    });
  }
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(
              CutoutBurstColors.primary,
            ),
            strokeWidth: 2.5,
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading photos...',
            style: TextStyle(
              fontSize: 14.sp,
              color: CutoutBurstColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64.w,
              color: CutoutBurstColors.textTertiary,
            ),
            SizedBox(height: 16.h),
            Text(
              'Photo Access Required',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: CutoutBurstColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please allow access to your photos to select an image.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: CutoutBurstColors.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            GestureDetector(
              onTap: controller.onOpenSettings,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: CutoutBurstColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24.h),
                ),
                child: Text(
                  'Go to Settings',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildPhotoGrid() {
    return RefreshIndicator(
      onRefresh: controller.refreshPhotos,
      color: CutoutBurstColors.primary,
      backgroundColor: CutoutBurstColors.card,
      child: Obx(() {
        final itemCount = 1 + controller.photos.length;
        if (itemCount == 1 && !controller.isLoading.value) {
          return _buildEmptyState();
        }
        return GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6.w,
            mainAxisSpacing: 6.w,
            childAspectRatio: 1.0,
          ),
          itemCount: itemCount,
          itemBuilder: (_, i) {
            if (i == 0) return _buildGalleryButton();
            return _buildPhotoItem(controller.photos[i - 1]);
          },
        );
      }),
    );
  }
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: 300.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_outlined,
                size: 56.w,
                color: CutoutBurstColors.textTertiary,
              ),
              SizedBox(height: 12.h),
              Text(
                'No photos found',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: CutoutBurstColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildGalleryButton() {
    return GestureDetector(
      onTap: controller.onOpenGallery,
      child: Container(
        decoration: BoxDecoration(
          color: CutoutBurstColors.elevated,
          borderRadius: BorderRadius.circular(8.w),
          border: Border.all(
            color: CutoutBurstColors.primary.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 28.w,
              color: CutoutBurstColors.primary,
            ),
            SizedBox(height: 6.h),
            Text(
              'Gallery',
              style: TextStyle(
                fontSize: 11.sp,
                color: CutoutBurstColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildPhotoItem(PhotoModel model) {
    return GestureDetector(
      onTap: () => controller.onSelectPhoto(model),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.w),
        child: model.thumbnail != null
            ? Image.memory(
                model.thumbnail!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPhotoPlaceholder(),
              )
            : _buildPhotoPlaceholder(),
      ),
    );
  }
  Widget _buildPhotoPlaceholder() {
    return Container(
      color: CutoutBurstColors.elevated,
      child: Center(
        child: Icon(
          Icons.photo_outlined,
          size: 24.w,
          color: CutoutBurstColors.textTertiary,
        ),
      ),
    );
  }
  Widget _buildBottomHint() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h)
          .copyWith(bottom: 24.h),
      decoration: BoxDecoration(
        color: CutoutBurstColors.card,
        border: Border(
          top: BorderSide(color: CutoutBurstColors.border),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 16.w,
              color: CutoutBurstColors.textSecondary,
            ),
            SizedBox(width: 8.w),
            Text(
              'Select a photo to enter ${controller.modeDisplayName}',
              style: TextStyle(
                fontSize: 13.sp,
                color: CutoutBurstColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildInfoOverlay() {
    return GestureDetector(
      onTap: controller.onCloseInfo,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: CutoutBurstColors.card,
                borderRadius: BorderRadius.circular(16.w),
                border: Border.all(
                  color: CutoutBurstColors.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20.w,
                        color: CutoutBurstColors.primary,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'How to Select',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: CutoutBurstColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildInfoItem(
                    Icons.photo_library_outlined,
                    'Tap Gallery to open your system picker.',
                  ),
                  SizedBox(height: 10.h),
                  _buildInfoItem(
                    Icons.touch_app_outlined,
                    'Tap any photo below to select and proceed to crop.',
                  ),
                  SizedBox(height: 10.h),
                  _buildInfoItem(
                    Icons.crop_rounded,
                    'After selecting, you will crop the image before cutout.',
                  ),
                  SizedBox(height: 20.h),
                  Center(
                    child: GestureDetector(
                      onTap: controller.onCloseInfo,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 32.w, vertical: 10.h),
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
      ),
    );
  }
  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.w, color: CutoutBurstColors.primary),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              color: CutoutBurstColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
