import '../status/patch_status.dart';
import '../utils/logger.dart';
import 'dart:async';

/// 简化的中间件接口
abstract class SimplePatchMiddleware {
  /// 中间件名称
  String get name;
  
  /// 中间件描述
  String get description;
  
  /// 执行补丁前的钩子
  Future<void> before(PatchModel patch);
  
  /// 执行补丁后的钩子
  Future<void> after(PatchModel patch, PatchStatus status);
  
  /// 是否启用此中间件
  bool get enabled => true;
  
  /// 中间件优先级（数字越小优先级越高）
  int get priority => 100;
}

/// 简化的中间件管理器
class SimpleMiddlewareManager {
  static final List<SimplePatchMiddleware> _middlewares = <SimplePatchMiddleware>[];

  /// 注册中间件
  static void register(SimplePatchMiddleware middleware) {
    if (middleware.enabled) {
      _middlewares.add(middleware);
      // 按优先级排序
      _middlewares.sort((a, b) => a.priority.compareTo(b.priority));
      hotfixLogger.middlewareInfo(middleware.name, '注册', '优先级: ${middleware.priority}');
    } else {
      hotfixLogger.warning('中间件已禁用，跳过注册: ${middleware.name}');
    }
  }

  /// 批量注册中间件
  static void registerAll(List<SimplePatchMiddleware> middlewares) {
    hotfixLogger.info('批量注册中间件，共 ${middlewares.length} 个');
    for (final middleware in middlewares) {
      register(middleware);
    }
  }

  /// 取消注册中间件
  static void unregister(SimplePatchMiddleware middleware) {
    _middlewares.remove(middleware);
    hotfixLogger.middlewareInfo(middleware.name, '取消注册');
  }

  /// 清空所有中间件
  static void clear() {
    final count = _middlewares.length;
    _middlewares.clear();
    hotfixLogger.info('清空所有中间件，共 $count 个');
  }

  /// 执行所有 before 钩子
  static Future<void> executeBefore(PatchModel patch) async {
    hotfixLogger.debug('执行 before 钩子，中间件数量: ${_middlewares.length}');
    for (final middleware in _middlewares) {
      try {
        hotfixLogger.debug('执行中间件 before: ${middleware.name}');
        await middleware.before(patch);
        hotfixLogger.debug('中间件 before 执行完成: ${middleware.name}');
      } catch (e) {
        hotfixLogger.error('中间件 before 执行失败: ${middleware.name}', e);
      }
    }
  }

  /// 执行所有 after 钩子
  static Future<void> executeAfter(PatchModel patch, PatchStatus status) async {
    hotfixLogger.debug('执行 after 钩子，中间件数量: ${_middlewares.length}');
    for (final middleware in _middlewares) {
      try {
        hotfixLogger.debug('执行中间件 after: ${middleware.name}');
        await middleware.after(patch, status);
        hotfixLogger.debug('中间件 after 执行完成: ${middleware.name}');
      } catch (e) {
        hotfixLogger.error('中间件 after 执行失败: ${middleware.name}', e);
      }
    }
  }

  /// 获取中间件列表
  static List<SimplePatchMiddleware> get middlewares => List.unmodifiable(_middlewares);

  /// 获取中间件总数
  static int get totalCount => _middlewares.length;

  /// 检查是否为空
  static bool get isEmpty => _middlewares.isEmpty;

  /// 检查是否不为空
  static bool get isNotEmpty => _middlewares.isNotEmpty;
}

/// 回调中间件
class CallbackSimpleMiddleware implements SimplePatchMiddleware {
  final String _name;
  final String _description;
  final Future<void> Function(PatchModel)? _onBefore;
  final Future<void> Function(PatchModel, PatchStatus)? _onAfter;
  final bool _enabled;
  final int _priority;

  CallbackSimpleMiddleware({
    String? name,
    String? description,
    Future<void> Function(PatchModel)? onBefore,
    Future<void> Function(PatchModel, PatchStatus)? onAfter,
    bool enabled = true,
    int priority = 100,
  }) : _name = name ?? 'CallbackMiddleware',
       _description = description ?? 'Callback-based middleware',
       _onBefore = onBefore,
       _onAfter = onAfter,
       _enabled = enabled,
       _priority = priority;

  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  bool get enabled => _enabled;

  @override
  int get priority => _priority;

  @override
  Future<void> before(PatchModel patch) async {
    await _onBefore?.call(patch);
  }

  @override
  Future<void> after(PatchModel patch, PatchStatus status) async {
    await _onAfter?.call(patch, status);
  }
}

/// 日志中间件
class LoggingSimpleMiddleware implements SimplePatchMiddleware {
  @override
  String get name => 'LoggingMiddleware';

  @override
  String get description => 'Logs patch execution events';

  @override
  bool get enabled => true;

  @override
  int get priority => 10;

  @override
  Future<void> before(PatchModel patch) async {
    hotfixLogger.patchInfo(patch.id, '开始执行', '类型: ${patch.type}, 版本: ${patch.version}');
  }

  @override
  Future<void> after(PatchModel patch, PatchStatus status) async {
    final statusText = status.applied ? "成功" : "失败";
    hotfixLogger.patchInfo(patch.id, '执行完成', '状态: $statusText');
    if (status.error != null) {
      hotfixLogger.error('补丁执行错误: ${patch.id}', status.error);
    }
  }
}

/// 基础安全中间件（向后兼容）
class SecuritySimpleMiddleware implements SimplePatchMiddleware {
  @override
  String get name => 'SecurityMiddleware';

  @override
  String get description => 'Checks security for patch execution';

  @override
  bool get enabled => true;

  @override
  int get priority => 20;

  @override
  Future<void> before(PatchModel patch) async {
    hotfixLogger.debug('开始安全检查: ${patch.id}');
    
    // 检查补丁是否过期
    if (patch.expireAt != null && DateTime.now().isAfter(patch.expireAt!)) {
      hotfixLogger.error('补丁已过期: ${patch.id}');
      throw Exception('补丁已过期: ${patch.id}');
    }

    // 检查补丁签名
    if (patch.signature.isEmpty) {
      hotfixLogger.error('补丁签名验证失败: ${patch.id}');
      throw Exception('补丁签名验证失败: ${patch.id}');
    }

    // 检查补丁来源是否可信
    if (!_isTrustedSource(patch.downloadUrl)) {
      hotfixLogger.error('补丁来源不可信: ${patch.downloadUrl}');
      throw Exception('补丁来源不可信: ${patch.downloadUrl}');
    }

    // 检查补丁大小限制
    if (patch.entry.length > 1024 * 1024) { // 1MB 限制
      hotfixLogger.error('补丁文件过大: ${patch.entry.length} bytes');
      throw Exception('补丁文件过大: ${patch.entry.length} bytes');
    }

    // 检查补丁类型是否支持
    if (!_isSupportedPatchType(patch.type)) {
      hotfixLogger.error('不支持的补丁类型: ${patch.type}');
      throw Exception('不支持的补丁类型: ${patch.type}');
    }

    hotfixLogger.debug('安全检查通过: ${patch.id}');
  }

  @override
  Future<void> after(PatchModel patch, PatchStatus status) async {
    final statusText = status.applied ? "成功" : "失败";
    hotfixLogger.debug('安全检查完成: ${patch.id}, 状态: $statusText');
  }

  /// 检查补丁来源是否可信
  bool _isTrustedSource(String downloadUrl) {
    final trustedDomains = [
      'patch.example.com',
      'cdn.example.com',
      'localhost',
      '127.0.0.1',
    ];
    
    try {
      final uri = Uri.parse(downloadUrl);
      return trustedDomains.any((domain) => uri.host.contains(domain));
    } catch (e) {
      hotfixLogger.warning('无法解析下载URL: $downloadUrl', e);
      return false;
    }
  }

  /// 检查补丁类型是否支持
  bool _isSupportedPatchType(PatchType type) {
    return type == PatchType.dartAot || type == PatchType.jsScript;
  }
} 