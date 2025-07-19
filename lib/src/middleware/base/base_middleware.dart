import '../core/middleware_interface.dart';
import '../../status/patch_status.dart';

/// 基础中间件实现
abstract class BasePatchMiddleware extends PatchMiddleware {
  @override
  Future<MiddlewareResult> before(MiddlewareContext context) async {
    return MiddlewareResult.success();
  }

  @override
  Future<MiddlewareResult> after(MiddlewareContext context) async {
    return MiddlewareResult.success();
  }
}

/// 回调函数类型定义
typedef PatchBeforeCallback = Future<void> Function(PatchModel patch);
typedef PatchAfterCallback = Future<void> Function(PatchModel patch, PatchStatus status);

/// 支持 callback 的中间件实现
class CallbackPatchMiddleware extends BasePatchMiddleware {
  final String _name;
  final String _description;
  final PatchBeforeCallback? _onBefore;
  final PatchAfterCallback? _onAfter;
  final bool _enabled;
  final int _priority;
  final MiddlewareType _type;

  CallbackPatchMiddleware({
    String? name,
    String? description,
    PatchBeforeCallback? onBefore,
    PatchAfterCallback? onAfter,
    bool enabled = true,
    int priority = 100,
    MiddlewareType type = MiddlewareType.business,
  }) : _name = name ?? 'CallbackMiddleware',
       _description = description ?? 'Callback-based middleware',
       _onBefore = onBefore,
       _onAfter = onAfter,
       _enabled = enabled,
       _priority = priority,
       _type = type;

  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  bool get enabled => _enabled;

  @override
  int get priority => _priority;

  @override
  MiddlewareType get type => _type;

  @override
  Future<MiddlewareResult> before(MiddlewareContext context) async {
    try {
      await _onBefore?.call(context.patch);
      return MiddlewareResult.success();
    } catch (e) {
      return MiddlewareResult.error('Before hook failed: $e');
    }
  }

  @override
  Future<MiddlewareResult> after(MiddlewareContext context) async {
    try {
      await _onAfter?.call(context.patch, context.status!);
      return MiddlewareResult.success();
    } catch (e) {
      return MiddlewareResult.error('After hook failed: $e');
    }
  }
} 