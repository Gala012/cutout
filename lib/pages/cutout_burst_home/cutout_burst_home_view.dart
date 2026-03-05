import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import 'cutout_burst_home_logic.dart';
class CutoutBurstHomeView extends GetView<CutoutBurstHomeLogic> {
  const CutoutBurstHomeView({super.key});
  static const _modes = [
    {
      'mode': 'trim',
      'name': 'Trim Cutout',
      'desc': 'Manual erase & restore for fine edges',
      'tag': 'green',
    },
    {
      'mode': 'shape',
      'name': 'Shape Cutout',
      'desc': 'Clip by preset shapes or freehand paths',
      'tag': 'coral',
    },
    {
      'mode': 'edge_text',
      'name': 'Edge + Text',
      'desc': 'Filters, edge cuts & text overlays',
      'tag': 'yellow',
    },
    {
      'mode': 'portrait',
      'name': 'Portrait Cutout',
      'desc': 'AI-powered person segmentation',
      'tag': 'pink',
    },
  ];
  IconData _iconForTag(String tag) {
    switch (tag) {
      case 'purple':
        return Icons.auto_fix_high_rounded;
      case 'green':
        return Icons.content_cut_rounded;
      case 'coral':
        return Icons.interests_rounded;
      case 'yellow':
        return Icons.text_fields_rounded;
      case 'pink':
        return Icons.face_retouching_natural_rounded;
      default:
        return Icons.star;
    }
  }
  LinearGradient _gradientForTag(String tag) {
    switch (tag) {
      case 'purple':
        return CutoutBurstColors.primaryGradient;
      case 'green':
        return CutoutBurstColors.accentGradient;
      case 'coral':
        return CutoutBurstColors.dangerGradient;
      case 'yellow':
        return CutoutBurstColors.warningGradient;
      case 'pink':
        return CutoutBurstColors.pinkGradient;
      default:
        return CutoutBurstColors.primaryGradient;
    }
  }
  Color _shadowColorForTag(String tag) {
    switch (tag) {
      case 'purple':
        return CutoutBurstColors.primary.withValues(alpha: 0.4);
      case 'green':
        return CutoutBurstColors.accent.withValues(alpha: 0.4);
      case 'coral':
        return CutoutBurstColors.danger.withValues(alpha: 0.4);
      case 'yellow':
        return CutoutBurstColors.warning.withValues(alpha: 0.4);
      case 'pink':
        return CutoutBurstColors.pink.withValues(alpha: 0.4);
      default:
        return CutoutBurstColors.primary.withValues(alpha: 0.4);
    }
  }
  Color _accentColorForTag(String tag) {
    switch (tag) {
      case 'purple':
        return CutoutBurstColors.primary;
      case 'green':
        return CutoutBurstColors.accent;
      case 'coral':
        return CutoutBurstColors.danger;
      case 'yellow':
        return CutoutBurstColors.warning;
      case 'pink':
        return CutoutBurstColors.pink;
      default:
        return CutoutBurstColors.primary;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CutoutBurstColors.bg,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(top: 0, bottom: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),
                  _buildWelcomeBanner(),
                  SizedBox(height: 20.h),
                  _buildSectionHeader('✦ Cutout Tools'),
                  SizedBox(height: 12.h),
                  _buildModeGrid(),
                  SizedBox(height: 24.h),
                  _buildSectionHeaderWithAction('✦ Recent Works'),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
            _buildRecentWorks(),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: CutoutBurstColors.card,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              gradient: CutoutBurstColors.primaryGradient,
              borderRadius: BorderRadius.circular(10.w),
              boxShadow: [
                BoxShadow(
                  color: CutoutBurstColors.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(Icons.bolt_rounded, color: Colors.white, size: 24.w),
          ),
          Spacer(),
          ShaderMask(
            shaderCallback: (bounds) =>
                CutoutBurstColors.titleGradient.createShader(bounds),
            child: Text(
              'CutoutBurst',
              style: TextStyle(
                fontSize: 21.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Spacer(),
          SizedBox(width: 32.w),
        ],
      ),
    );
  }
  Widget _buildWelcomeBanner() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CutoutBurstColors.primary.withValues(alpha: 0.15),
            CutoutBurstColors.accent.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(
          color: CutoutBurstColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              gradient: CutoutBurstColors.primaryGradient,
              borderRadius: BorderRadius.circular(12.w),
              boxShadow: [
                BoxShadow(
                  color: CutoutBurstColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 26.w,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Professional Cutout Toolkit',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: CutoutBurstColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Extract, trim & create stunning visuals with AI-powered tools',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: CutoutBurstColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: CutoutBurstColors.textSecondary,
        letterSpacing: 1.0,
      ),
    );
  }
  Widget _buildSectionHeaderWithAction(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: CutoutBurstColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        GestureDetector(
          onTap: controller.onSeeAllTap,
          child: Text(
            'See All',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: CutoutBurstColors.primary,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildModeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
        childAspectRatio: 1.35,
      ),
      itemCount: _modes.length,
      itemBuilder: (_, i) {
        return _buildModeCard(_modes[i]);
      },
    );
  }
  Widget _buildModeCard(Map<String, dynamic> mode) {
    final tag = mode['tag'] as String;
    final accentColor = _accentColorForTag(tag);
    final gradient = _gradientForTag(tag);
    final shadowColor = _shadowColorForTag(tag);
    final icon = _iconForTag(tag);
    return GestureDetector(
      onTap: () => controller.onModeTap(mode['mode'] as String),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: CutoutBurstColors.card,
          borderRadius: BorderRadius.circular(18.w),
          border: Border.all(color: CutoutBurstColors.border),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(18.w),
                    bottomLeft: Radius.circular(60.w),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(14.w),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 20.w, color: Colors.white),
                ),
                SizedBox(height: 8.h),
                Text(
                  mode['name'] as String,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: CutoutBurstColors.textPrimary,
                  ),
                ),
                SizedBox(height: 3.h),
                Flexible(
                  child: Text(
                    mode['desc'] as String,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: CutoutBurstColors.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildRecentWorks() {
    return Obx(() {
      if (controller.recentWorks.isEmpty) {
        return SizedBox(
          height: 148.h,
          child: Center(
            child: Text(
              'No recent works yet',
              style: TextStyle(
                fontSize: 13.sp,
                color: CutoutBurstColors.textTertiary,
              ),
            ),
          ),
        );
      }
      return SizedBox(
        height: 148.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: controller.recentWorks.length,
          separatorBuilder: (_, __) => SizedBox(width: 10.w),
          itemBuilder: (_, i) => _buildRecentCard(controller.recentWorks[i]),
        ),
      );
    });
  }
  Widget _buildRecentCard(dynamic history) {
    final tag = controller.getModeTag(history.cutoutMode);
    final accentColor = _accentColorForTag(tag);
    final modeName = controller.getModeDisplayName(history.cutoutMode);
    return GestureDetector(
      onTap: () => controller.onRecentWorkTap(history),
      child: Container(
        width: 100.w,
        decoration: BoxDecoration(
          color: CutoutBurstColors.card,
          borderRadius: BorderRadius.circular(14.w),
          border: Border.all(color: CutoutBurstColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: CutoutBurstColors.elevated,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(14.w),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(14.w),
                  ),
                  child: Image.file(
                    File(history.thumbnailPath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: CutoutBurstColors.textTertiary,
                        size: 28.w,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modeName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    history.createdAt,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: CutoutBurstColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
