import 'core/middleware_interface.dart';
import 'management/middleware_registry.dart';
import 'management/middleware_executor.dart';
import 'base/base_middleware.dart';
import '../status/patch_status.dart';

/// 全局中间件管理器，提供统一的中间件管理接口
class GlobalMiddlewareManager {
  static final MiddlewareRegistry _registry = MiddlewareRegistry();
  static final MiddlewareExecutor _executor = MiddlewareExecutor(_registry);

  /// 注册中间件
  static void register(PatchMiddleware middleware) {
    _registry.register(middleware);
  }

  /// 批量注册中间件
  static void registerAll(List<PatchMiddleware> middlewares) {
    _registry.registerAll(middlewares);
  }

  /// 取消注册中间件
  static void unregister(PatchMiddleware middleware) {
    _registry.unregister(middleware);
  }

  /// 清空中间件
  static void clear([MiddlewareType? type]) {
    _registry.clear(type);
  }

  /// 执行 before 钩子
  static Future<List<MiddlewareResult>> executeBefore(PatchModel patch) async {
    return await _executor.executeBefore(patch);
  }

  /// 执行 after 钩子
  static Future<List<MiddlewareResult>> executeAfter(PatchModel patch, PatchStatus status) async {
    return await _executor.executeAfter(patch, status);
  }

  /// 获取中间件列表
  static List<PatchMiddleware> getMiddlewares(MiddlewareType type) {
    return _registry.getMiddlewares(type);
  }

  /// 获取所有中间件
  static Map<MiddlewareType, List<PatchMiddleware>> get allMiddlewares {
    return _registry.allMiddlewares;
  }

  /// 获取中间件总数
  static int get totalCount => _registry.totalCount;

  /// 检查是否为空
  static bool get isEmpty => _registry.isEmpty;

  /// 检查是否不为空
  static bool get isNotEmpty => _registry.isNotEmpty;

  /// 获取中间件信息
  static Map<String, dynamic> getMiddlewareInfo() {
    return _registry.getMiddlewareInfo();
  }

  /// 获取执行统计信息
  static Map<String, dynamic> getExecutionStats(List<MiddlewareResult> results) {
    return _executor.getExecutionStats(results);
  }

  /// 快速注册 callback 形式的中间件
  static void registerCallback({
    String? name,
    String? description,
    PatchBeforeCallback? before,
    PatchAfterCallback? after,
    bool enabled = true,
    int priority = 100,
    MiddlewareType type = MiddlewareType.business,
  }) {
    register(CallbackPatchMiddleware(
      name: name,
      description: description,
      onBefore: before,
      onAfter: after,
      enabled: enabled,
      priority: priority,
      type: type,
    ));
  }

  /// 注册系统中间件
  static void registerSystem(PatchMiddleware middleware, {int priority = 10}) {
    register(middleware);
  }

  /// 注册安全中间件
  static void registerSecurity(PatchMiddleware middleware, {int priority = 20}) {
    register(middleware);
  }

  /// 注册业务中间件
  static void registerBusiness(PatchMiddleware middleware, {int priority = 100}) {
    register(middleware);
  }

  /// 注册自定义中间件
  static void registerCustom(PatchMiddleware middleware, {int priority = 200}) {
    register(middleware);
  }
}

/// 向后兼容的别名
class PatchMiddlewareManager {
  static void use(PatchMiddleware middleware) => GlobalMiddlewareManager.register(middleware);
  static void clear() => GlobalMiddlewareManager.clear();
  static Future<void> runBefore(PatchModel patch) async {
    await GlobalMiddlewareManager.executeBefore(patch);
  }
  static Future<void> runAfter(PatchModel patch, PatchStatus status) async {
    await GlobalMiddlewareManager.executeAfter(patch, status);
  }
  static List<PatchMiddleware> get middlewares => GlobalMiddlewareManager.getMiddlewares(MiddlewareType.business);
}

/// 向后兼容的扩展
extension PatchMiddlewareManagerExt on PatchMiddlewareManager {
  static void useCallback({
    PatchBeforeCallback? before,
    PatchAfterCallback? after,
  }) {
    GlobalMiddlewareManager.registerCallback(
      before: before,
      after: after,
    );
  }
} 