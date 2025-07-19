import 'patch_status.dart';
import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';

/// 补丁状态管理器，负责补丁应用状态的增删查和持久化
class PatchStatusManager {
  /// 状态文件路径
  final String patchStatusFile;
  /// 已应用补丁状态列表
  final List<PatchStatus> _appliedPatches = <PatchStatus>[];
  /// 补丁ID与PatchModel映射表（可选扩展）
  final Map<String, dynamic> _patchModelMap = <String, dynamic>{};

  /// 构造函数，传入状态文件路径
  PatchStatusManager(this.patchStatusFile);

  /// 获取已应用补丁状态的只读列表
  List<PatchStatus> get appliedPatches => List.unmodifiable(_appliedPatches);
  /// 判断是否为空
  bool get isEmpty => _appliedPatches.isEmpty;

  /// 批量更新已应用补丁状态
  void updateAppliedPatches(List<PatchStatus> list) {
    _appliedPatches.clear();
    _appliedPatches.addAll(list);
  }

  /// 移除指定补丁状态
  void removeAppliedPatch(String patchId, dynamic type) {
    _appliedPatches.removeWhere((PatchStatus s) => s.patchId == patchId && s.type == type);
  }

  /// 查找指定补丁状态，找不到返回null
  PatchStatus? findAppliedPatch(String patchId, dynamic type) {
    return _appliedPatches.firstWhereOrNull((s) => s.patchId == patchId && s.type == type);
  }

  /// 获取完整PatchModel（可选扩展）
  dynamic getFullPatchModel(PatchStatus status) {
    return _patchModelMap['${status.patchId}_${status.type}'];
  }

  /// 持久化已应用补丁状态到本地文件
  Future<void> persistAppliedPatches() async {
    final File file = File(patchStatusFile);
    final List<Map<String, dynamic>> list = _appliedPatches.map((PatchStatus e) => e.toJson()).toList();
    await file.writeAsString(jsonEncode(list));
  }

  /// 恢复本地已应用补丁状态
  Future<void> restoreAppliedPatches() async {
    final File file = File(patchStatusFile);
    if (await file.exists()) {
      final String content = await file.readAsString();
      final List list = jsonDecode(content) as List<dynamic>;
      _appliedPatches
        ..clear()
        ..addAll(list.map((e) => PatchStatus.fromJson(e as Map<String, dynamic>)));
    }
  }
} 