import 'dart:io';

import 'package:flutter_hotfix_manager/src/status/patch_status.dart';

/// 补丁缓存管理器，负责本地补丁包的路径生成与清理
class PatchCacheManager {
  /// 缓存目录路径
  final String cacheDir;
  /// 构造函数，传入缓存目录
  PatchCacheManager(this.cacheDir);

  /// 获取补丁缓存文件路径
  String getPatchFilePath(PatchModel patch) {
    return '$cacheDir/${patch.id}_${patch.type}.patch';
  }

  /// 清理指定补丁缓存文件
  Future<void> clearPatch(String patchId, PatchType type) async {
    final file = File('$cacheDir/${patchId}_${type}.patch');
    if (await file.exists()) {
      await file.delete();
    }
  }
} 