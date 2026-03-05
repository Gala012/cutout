import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../db_cutout_burst/data.dart';
import '../../db_cutout_burst/db_cutout_burst_entity.dart';
import '../../utils/index.dart';
import '../cutout_burst_tab/cutout_burst_tab_logic.dart';
class CutoutBurstHistoryLogic extends GetxController {
  final isEditMode = false.obs;
  final selectedIds = <int>{}.obs;
  final histories = <CutoutHistory>[].obs;
  final isLoading = false.obs;
  @override
  void onInit() {
    super.onInit();
    loadHistories();
  }
  Future<void> loadHistories() async {
    try {
      isLoading.value = true;
      final data = await CutoutBurstDb.to.getCutoutHistories();
      histories.assignAll(data);
    } catch (e, stackTrace) {
      debugPrint('Error loading histories: $e');
      debugPrint('Stack trace: $stackTrace');
      errorToast('Failed to load history');
    } finally {
      isLoading.value = false;
    }
  }
  void toggleEditMode() {
    isEditMode.value = !isEditMode.value;
    if (!isEditMode.value) selectedIds.clear();
  }
  void toggleSelect(int id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
  }
  void selectAll() {
    final ids = histories.map((h) => h.id!).toSet();
    selectedIds.assignAll(ids);
  }
  Future<void> onDeleteSelectedTap() async {
    if (selectedIds.isEmpty) return;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete'),
        content: Text('Delete ${selectedIds.length} item(s)?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      for (final id in selectedIds) {
        final history = histories.firstWhereOrNull((h) => h.id == id);
        if (history != null) {
          await _deleteHistoryFiles(history);
        }
      }
      await CutoutBurstDb.to.deleteCutoutHistories(selectedIds.toList());
      successToast('Deleted ${selectedIds.length} item(s)');
      selectedIds.clear();
      isEditMode.value = false;
      await loadHistories();
    } catch (e) {
      errorToast('Failed to delete');
    }
  }
  Future<void> onPreviewTap(CutoutHistory history) async {
    if (isEditMode.value) {
      toggleSelect(history.id!);
      return;
    }
    await Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: _PreviewDialog(
          history: history,
          onDelete: () async {
            Get.back();
            await _deleteSingleHistory(history);
          },
          onShare: () async {
            await _shareHistory(history);
          },
        ),
      ),
    );
  }
  Future<void> _deleteSingleHistory(CutoutHistory history) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete'),
        content: const Text('Delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _deleteHistoryFiles(history);
      await CutoutBurstDb.to.deleteCutoutHistory(history.id!);
      successToast('Deleted');
      await loadHistories();
    } catch (e) {
      errorToast('Failed to delete');
    }
  }
  Future<void> _deleteHistoryFiles(CutoutHistory history) async {
    try {
      final resultFile = File(history.resultPath);
      if (await resultFile.exists()) {
        await resultFile.delete();
      }
    } catch (e) {
    }
    try {
      final thumbnailFile = File(history.thumbnailPath);
      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
      }
    } catch (e) {
    }
  }
  Future<void> _shareHistory(CutoutHistory history) async {
    try {
      final file = File(history.resultPath);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(history.resultPath)],
            text: 'Share from CutoutBurst');
      } else {
        errorToast('File not found');
      }
    } catch (e) {
      errorToast('Failed to share');
    }
  }
  void onGoToHomeTap() {
    final tabLogic = Get.find<CutoutBurstTabLogic>();
    tabLogic.onTabChange(0);
  }
  String getModeDisplayName(String mode) {
    switch (mode) {
      case CutoutMode.trim:
        return 'Trim';
      case CutoutMode.shape:
        return 'Shape';
      case CutoutMode.edgeText:
        return 'Edge + Text';
      case CutoutMode.portrait:
        return 'Portrait';
      default:
        return 'Unknown';
    }
  }
  Color getModeColor(String mode) {
    switch (mode) {
      case CutoutMode.trim:
        return const Color(0xFF00C9FF);
      case CutoutMode.shape:
        return const Color(0xFFFF4444);
      case CutoutMode.edgeText:
        return const Color(0xFFFFAA00);
      case CutoutMode.portrait:
        return const Color(0xFFFF69B4);
      default:
        return Colors.grey;
    }
  }
}
class _PreviewDialog extends StatelessWidget {
  final CutoutHistory history;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  const _PreviewDialog({
    required this.history,
    required this.onDelete,
    required this.onShare,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(history.resultPath),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: Colors.grey,
                child: const Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ActionButton(
              icon: Icons.share_rounded,
              label: 'Share',
              onTap: onShare,
            ),
            const SizedBox(width: 20),
            _ActionButton(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              onTap: onDelete,
              color: Colors.red,
            ),
            const SizedBox(width: 20),
            _ActionButton(
              icon: Icons.close_rounded,
              label: 'Close',
              onTap: () => Get.back(),
            ),
          ],
        ),
      ],
    );
  }
}
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color != null ? Colors.white : Colors.black87),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color != null ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
