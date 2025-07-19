import '../status/patch_status.dart';
import '../utils/logger.dart';
import 'package:flutter_js/flutter_js.dart';
import 'dart:io';

/// 脚本补丁加载器接口，仅支持 JS
abstract class ScriptPatchLoader {
  Future<bool> load(PatchModel patch);
  Future<void> rollback(PatchModel patch);
}

/// ScriptPatchLoader 工厂，仅支持 JS
class ScriptPatchLoaderFactory {
  static ScriptPatchLoader Function(PatchModel patch)? customCreator;
  static ScriptPatchLoader create(PatchModel patch) {
    if (customCreator != null) {
      return customCreator!(patch);
    }
    if (patch.type == PatchType.jsScript) {
      return JsScriptPatchLoader();
    }
    throw UnsupportedError('Unsupported script patch type: ${patch.type}');
  }
}

/// JS 脚本补丁加载器实现
class JsScriptPatchLoader implements ScriptPatchLoader {
  static JavascriptRuntime? _runtime;
  // 存储每个补丁的回滚脚本（可按需扩展为全局或更复杂的管理）
  static final Map<String, String> _rollbackScripts = {};

  JsScriptPatchLoader() {
    _runtime ??= getJavascriptRuntime();
  }

  @override
  Future<bool> load(PatchModel patch) async {
    hotfixLogger.patchInfo(patch.id, '开始加载 JS 脚本补丁', '文件: ${patch.entry}');
    
    final scriptFile = File(patch.entry);
    if (!await scriptFile.exists()) {
      hotfixLogger.error('JS 补丁文件不存在: ${patch.entry}');
      return false;
    }
    
    final script = await scriptFile.readAsString();
    hotfixLogger.debug('JS 脚本内容长度: ${script.length} 字符');
    
    // 检查是否有回滚脚本（约定：同目录下同名 .rollback.js 文件）
    final rollbackPath = patch.entry.replaceAll('.js', '.rollback.js');
    final rollbackFile = File(rollbackPath);
    if (await rollbackFile.exists()) {
      final rollbackScript = await rollbackFile.readAsString();
      _rollbackScripts[patch.id] = rollbackScript;
      hotfixLogger.debug('找到回滚脚本: $rollbackPath');
    } else {
      hotfixLogger.debug('未找到回滚脚本: $rollbackPath');
    }
    
    try {
    final result = _runtime!.evaluate(script);
      hotfixLogger.patchInfo(patch.id, 'JS 脚本执行完成', '结果: ${result.stringResult}');
    return true;
    } catch (e, stackTrace) {
      hotfixLogger.error('JS 脚本执行失败', e, stackTrace);
      return false;
    }
  }

  @override
  Future<void> rollback(PatchModel patch) async {
    hotfixLogger.patchInfo(patch.id, '开始回滚 JS 脚本补丁');
    
    final rollbackScript = _rollbackScripts[patch.id];
    if (rollbackScript != null) {
      try {
      final result = _runtime!.evaluate(rollbackScript);
        hotfixLogger.patchInfo(patch.id, 'JS 脚本回滚完成', '结果: ${result.stringResult}');
      // 回滚后可移除记录
      _rollbackScripts.remove(patch.id);
      } catch (e, stackTrace) {
        hotfixLogger.error('JS 脚本回滚失败', e, stackTrace);
      }
    } else {
      hotfixLogger.warning('未找到 JS 补丁的回滚脚本: ${patch.id}');
    }
  }
} 