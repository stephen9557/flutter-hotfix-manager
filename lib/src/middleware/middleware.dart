import '../status/patch_status.dart';
import 'core/middleware_interface.dart';
import 'base/base_middleware.dart';

/// 向后兼容的中间件接口
abstract class LegacyPatchMiddleware {
  /// 执行补丁前的钩子（向后兼容）
  Future<void> before(PatchModel patch);
  
  /// 执行补丁后的钩子（向后兼容）
  Future<void> after(PatchModel patch, PatchStatus status);
}

/// 向后兼容的回调中间件
class LegacyCallbackPatchMiddleware implements LegacyPatchMiddleware {
  final PatchBeforeCallback? onBefore;
  final PatchAfterCallback? onAfter;

  LegacyCallbackPatchMiddleware({this.onBefore, this.onAfter});

  @override
  Future<void> before(PatchModel patch) async {
    await onBefore?.call(patch);
  }

  @override
  Future<void> after(PatchModel patch, PatchStatus status) async {
    await onAfter?.call(patch, status);
  }
} 

/// 向后兼容的回调函数类型定义
typedef PatchBeforeCallback = Future<void> Function(PatchModel patch);
typedef PatchAfterCallback = Future<void> Function(PatchModel patch, PatchStatus status); 