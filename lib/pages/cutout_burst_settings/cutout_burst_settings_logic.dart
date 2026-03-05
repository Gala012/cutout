import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../db_cutout_burst/data.dart';
import '../../utils/index.dart';
class CutoutBurstSettingsLogic extends GetxController {
  final appVersion = '1.0.0'.obs;
  final cacheSize = '0 MB'.obs;
  final isCalculating = false.obs;
  @override
  void onInit() {
    super.onInit();
    _loadAppVersion();
    _calculateCacheSize();
  }
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion.value = packageInfo.version;
    } catch (e) {
      appVersion.value = '1.0.0';
    }
  }
  Future<void> _calculateCacheSize() async {
    try {
      isCalculating.value = true;
      int totalSize = 0;
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        totalSize += await _getDirectorySize(tempDir);
      }
      final appDir = await getApplicationDocumentsDirectory();
      if (await appDir.exists()) {
        totalSize += await _getDirectorySize(appDir);
      }
      cacheSize.value = _formatBytes(totalSize);
    } catch (e) {
      cacheSize.value = '0 MB';
    } finally {
      isCalculating.value = false;
    }
  }
  Future<int> _getDirectorySize(Directory dir) async {
    int size = 0;
    try {
      final files = dir.listSync(recursive: true);
      for (final file in files) {
        if (file is File) {
          size += await file.length();
        }
      }
    } catch (e) {
    }
    return size;
  }
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  Future<void> onClearDataTap() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all history records and cached files. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final histories = await CutoutBurstDb.to.getCutoutHistories();
      final ids = histories.map((h) => h.id!).toList();
      if (ids.isNotEmpty) {
        await CutoutBurstDb.to.deleteCutoutHistories(ids);
      }
      for (final history in histories) {
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
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final files = tempDir.listSync();
        for (final file in files) {
          try {
            if (file is File) {
              await file.delete();
            } else if (file is Directory) {
              await file.delete(recursive: true);
            }
          } catch (e) {
          }
        }
      }
      final appDir = await getApplicationDocumentsDirectory();
      if (await appDir.exists()) {
        final files = appDir.listSync();
        for (final file in files) {
          try {
            if (file.path.contains('.db')) continue;
            if (file is File) {
              await file.delete();
            } else if (file is Directory) {
              await file.delete(recursive: true);
            }
          } catch (e) {
          }
        }
      }
      await _calculateCacheSize();
      successToast('All data cleared');
    } catch (e) {
      errorToast('Failed to clear data');
    }
  }
}
