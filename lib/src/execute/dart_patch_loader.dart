import '../status/patch_status.dart';
import '../utils/logger.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Dart AOT 补丁加载器接口
abstract class DartPatchLoader {
  Future<bool> load(PatchModel patch);
  Future<void> rollback(PatchModel patch);
}

/// DartPatchLoader 工厂，支持自定义实现注入
class DartPatchLoaderFactory {
  static DartPatchLoader Function(PatchModel patch)? customCreator;

  static DartPatchLoader create(PatchModel patch) {
    if (customCreator != null) {
      return customCreator!(patch);
    }
    return ShorebirdPatchLoader();
  }
}

/// Shorebird AOT 补丁加载器实现
class ShorebirdPatchLoader implements DartPatchLoader {
  final ShorebirdUpdater _updater = ShorebirdUpdater();

  @override
  Future<bool> load(PatchModel patch) async {
    hotfixLogger.patchInfo(patch.id, '开始加载 Dart AOT 补丁', '类型: Shorebird');
    
    // 检查是否有新补丁
    final status = await _updater.checkForUpdate();
    if (status == UpdateStatus.outdated) {
      try {
        await _updater.update();
        hotfixLogger.patchInfo(patch.id, 'Dart AOT 补丁下载完成', '下次重启后生效');
        return true;
      } on UpdateException catch (e) {
        hotfixLogger.error('Dart AOT 补丁更新失败', e);
        return false;
      }
    } else {
      hotfixLogger.info('没有可用的 Dart AOT 补丁');
      return false;
    }
  }

  @override
  Future<void> rollback(PatchModel patch) async {
    hotfixLogger.patchInfo(patch.id, '尝试回滚 Dart AOT 补丁', 'Shorebird 暂不支持直接回滚');
    hotfixLogger.warning('Shorebird 暂不支持直接回滚补丁，请通过下发旧补丁实现回退');
  }
} 