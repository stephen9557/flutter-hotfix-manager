import '../status/patch_status.dart';
import '../middleware/middleware_manager.dart';
import 'dart_patch_loader.dart';
import 'script_patch_loader.dart';

/// 补丁执行器接口，定义补丁的执行与回滚
abstract class PatchExecutor {
  /// 执行补丁
  Future<PatchStatus> execute(PatchModel patch);
  /// 回滚补丁
  Future<void> rollback(PatchModel patch);
}

/// 默认补丁执行器，支持多类型补丁分发与中间件
class DefaultPatchExecutor implements PatchExecutor {
  @override
  Future<PatchStatus> execute(PatchModel patch) async {
    await PatchMiddlewareManager.runBefore(patch);
    try {
      final bool result = await _executePatchByType(patch);
      final PatchStatus status = PatchStatus(
        patchId: patch.id,
        type: patch.type,
        applied: result,
        appliedAt: result ? DateTime.now() : null,
        error: result ? null : 'Patch execution failed',
      );
      await PatchMiddlewareManager.runAfter(patch, status);
      return status;
    } catch (e) {
      final PatchStatus status = PatchStatus(
        patchId: patch.id,
        type: patch.type,
        applied: false,
        error: e.toString(),
      );
      await PatchMiddlewareManager.runAfter(patch, status);
      return status;
    }
  }

  /// 根据补丁类型分发执行
  Future<bool> _executePatchByType(PatchModel patch) async {
    switch (patch.type) {
      case PatchType.dartAot:
        return await DartPatchLoaderFactory.create(patch).load(patch);
      case PatchType.jsScript:
        return await ScriptPatchLoaderFactory.create(patch).load(patch);
      default:
        throw UnsupportedError('Unsupported patch type: \'${patch.type}\'');
    }
  }

  @override
  Future<void> rollback(PatchModel patch) async {
    await PatchMiddlewareManager.runBefore(patch);
    try {
      await _rollbackPatchByType(patch);
      final PatchStatus status = PatchStatus(
        patchId: patch.id,
        type: patch.type,
        applied: false,
        error: 'rollback',
      );
      await PatchMiddlewareManager.runAfter(patch, status);
    } catch (e) {
      final PatchStatus status = PatchStatus(
        patchId: patch.id,
        type: patch.type,
        applied: false,
        error: e.toString(),
      );
      await PatchMiddlewareManager.runAfter(patch, status);
    }
  }

  /// 根据补丁类型分发回滚
  Future<void> _rollbackPatchByType(PatchModel patch) async {
    switch (patch.type) {
      case PatchType.dartAot:
        await DartPatchLoaderFactory.create(patch).rollback(patch);
        break;
      case PatchType.jsScript:
        await ScriptPatchLoaderFactory.create(patch).rollback(patch);
        break;
      default:
        throw UnsupportedError('Unsupported patch type: \'${patch.type}\'');
    }
  }
} 