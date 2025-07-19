import '../../status/patch_status.dart';

/// 中间件类型枚举
enum MiddlewareType {
  /// 系统级中间件（日志、监控等）
  system,
  /// 安全级中间件（权限检查、数据校验等）
  security,
  /// 业务级中间件（业务逻辑、数据转换等）
  business,
  /// 自定义中间件
  custom,
}

/// 中间件执行上下文
class MiddlewareContext {
  /// 补丁模型
  final PatchModel patch;
  
  /// 补丁状态（after 阶段可用）
  final PatchStatus? status;
  
  /// 中间件间共享的数据
  final Map<String, dynamic> data;
  
  /// 是否应该继续执行
  bool shouldContinue;
  
  /// 错误信息
  String? error;

  MiddlewareContext({
    required this.patch,
    this.status,
    Map<String, dynamic>? data,
  }) : data = data ?? {}, shouldContinue = true;

  /// 设置数据
  void setData(String key, dynamic value) {
    data[key] = value;
  }

  /// 获取数据
  T? getData<T>(String key) {
    return data[key] as T?;
  }

  /// 停止执行
  void stop() {
    shouldContinue = false;
  }

  /// 设置错误
  void setError(String error) {
    this.error = error;
    shouldContinue = false;
  }
}

/// 中间件执行结果
class MiddlewareResult {
  /// 是否成功
  final bool success;
  
  /// 错误信息
  final String? error;
  
  /// 返回的数据
  final Map<String, dynamic> data;
  
  /// 是否应该继续执行后续中间件
  final bool shouldContinue;

  const MiddlewareResult({
    required this.success,
    this.error,
    this.data = const {},
    this.shouldContinue = true,
  });

  factory MiddlewareResult.success([Map<String, dynamic>? data]) {
    return MiddlewareResult(
      success: true,
      data: data ?? {},
    );
  }

  factory MiddlewareResult.error(String error, {Map<String, dynamic>? data}) {
    return MiddlewareResult(
      success: false,
      error: error,
      data: data ?? {},
      shouldContinue: false,
    );
  }

  factory MiddlewareResult.stop([Map<String, dynamic>? data]) {
    return MiddlewareResult(
      success: true,
      data: data ?? {},
      shouldContinue: false,
    );
  }
}

/// 中间件接口
abstract class PatchMiddleware {
  /// 中间件名称
  String get name;
  
  /// 中间件描述
  String get description;
  
  /// 执行补丁前的钩子
  Future<MiddlewareResult> before(MiddlewareContext context);
  
  /// 执行补丁后的钩子
  Future<MiddlewareResult> after(MiddlewareContext context);
  
  /// 是否启用此中间件
  bool get enabled => true;
  
  /// 中间件优先级（数字越小优先级越高）
  int get priority => 100;
  
  /// 中间件类型
  MiddlewareType get type => MiddlewareType.business;
} 