import '../simple_middleware.dart';
import '../../utils/logger.dart';
import '../../status/patch_status.dart';
import 'dart:async';

/// 安全策略接口 - 业务方需要实现
abstract class SecurityPolicy {
  /// 检查补丁是否过期
  Future<bool> checkExpiration(PatchModel patch);
  
  /// 验证补丁签名
  Future<bool> verifySignature(PatchModel patch);
  
  /// 检查补丁来源是否可信
  Future<bool> checkSourceTrust(PatchModel patch);
  
  /// 检查补丁大小限制
  Future<bool> checkSizeLimit(PatchModel patch);
  
  /// 检查补丁类型是否支持
  Future<bool> checkTypeSupport(PatchModel patch);
  
  /// 获取策略名称
  String get name;
  
  /// 获取策略描述
  String get description;
}

/// 默认安全策略实现 - 业务方可以继承或替换
class DefaultSecurityPolicy implements SecurityPolicy {
  final List<String> trustedDomains;
  final int maxFileSize; // 字节
  final List<PatchType> supportedTypes;
  final Duration maxExpirationDays;

  DefaultSecurityPolicy({
    this.trustedDomains = const [
      'patch.example.com',
      'cdn.example.com',
      'localhost',
      '127.0.0.1',
    ],
    this.maxFileSize = 1024 * 1024, // 1MB
    this.supportedTypes = const [PatchType.dartAot, PatchType.jsScript],
    this.maxExpirationDays = const Duration(days: 30),
  });

  @override
  String get name => 'DefaultSecurityPolicy';

  @override
  String get description => '默认安全策略实现';

  @override
  Future<bool> checkExpiration(PatchModel patch) async {
    if (patch.expireAt == null) {
      return true; // 没有过期时间，认为有效
    }
    
    final now = DateTime.now();
    final isExpired = now.isAfter(patch.expireAt!);
    
    if (isExpired) {
      hotfixLogger.warning('补丁已过期: ${patch.id}, 过期时间: ${patch.expireAt}');
    }
    
    return !isExpired;
  }

  @override
  Future<bool> verifySignature(PatchModel patch) async {
    // 业务方需要实现具体的签名验证逻辑
    if (patch.signature.isEmpty) {
      hotfixLogger.warning('补丁签名为空: ${patch.id}');
      return false;
    }
    
    // 实际项目中应该使用加密库验证签名
    return _verifySignatureInternal(patch);
  }

  @override
  Future<bool> checkSourceTrust(PatchModel patch) async {
    try {
      final uri = Uri.parse(patch.downloadUrl);
      final isTrusted = trustedDomains.any((domain) => uri.host.contains(domain));
      
      if (!isTrusted) {
        hotfixLogger.warning('补丁来源不可信: ${patch.downloadUrl}');
      }
      
      return isTrusted;
    } catch (e) {
      hotfixLogger.warning('无法解析下载URL: ${patch.downloadUrl}', e);
      return false;
    }
  }

  @override
  Future<bool> checkSizeLimit(PatchModel patch) async {
    final size = patch.entry.length;
    final isWithinLimit = size <= maxFileSize;
    
    if (!isWithinLimit) {
      hotfixLogger.warning('补丁文件过大: $size bytes, 限制: $maxFileSize bytes');
    }
    
    return isWithinLimit;
  }

  @override
  Future<bool> checkTypeSupport(PatchModel patch) async {
    final isSupported = supportedTypes.contains(patch.type);
    
    if (!isSupported) {
      hotfixLogger.warning('不支持的补丁类型: ${patch.type}');
    }
    
    return isSupported;
  }

  /// 内部签名验证方法 - 业务方可以重写
  bool _verifySignatureInternal(PatchModel patch) {
    // 基础实现：检查签名不为空且格式正确
    // 实际项目中应该实现真正的签名验证
    return patch.signature.isNotEmpty && patch.signature.length >= 32;
  }
}

/// 可配置的安全中间件
class ConfigurableSecurityMiddleware implements SimplePatchMiddleware {
  final SecurityPolicy _policy;
  final bool _enabled;
  final int _priority;

  ConfigurableSecurityMiddleware({
    SecurityPolicy? policy,
    bool enabled = true,
    int priority = 20,
  }) : _policy = policy ?? DefaultSecurityPolicy(),
       _enabled = enabled,
       _priority = priority;

  @override
  String get name => 'ConfigurableSecurityMiddleware';

  @override
  String get description => '可配置的安全中间件，使用 ${_policy.name}';

  @override
  bool get enabled => _enabled;

  @override
  int get priority => _priority;

  @override
  Future<void> before(PatchModel patch) async {
    hotfixLogger.middlewareInfo(name, '开始安全检查', '补丁ID: ${patch.id}, 策略: ${_policy.name}');
    
    // 执行所有安全检查
    final checks = [
      _policy.checkExpiration(patch),
      _policy.verifySignature(patch),
      _policy.checkSourceTrust(patch),
      _policy.checkSizeLimit(patch),
      _policy.checkTypeSupport(patch),
    ];

    final results = await Future.wait(checks);
    
    // 检查是否有任何失败的安全检查
    for (int i = 0; i < results.length; i++) {
      if (!results[i]) {
        final checkNames = ['过期检查', '签名验证', '来源检查', '大小检查', '类型检查'];
        final error = '安全检查失败: ${checkNames[i]} - 补丁ID: ${patch.id}';
        hotfixLogger.error(error);
        throw Exception(error);
      }
    }

    hotfixLogger.middlewareInfo(name, '安全检查通过', '补丁ID: ${patch.id}');
  }

  @override
  Future<void> after(PatchModel patch, PatchStatus status) async {
    final statusText = status.applied ? "成功" : "失败";
    hotfixLogger.middlewareInfo(name, '安全检查完成', '补丁ID: ${patch.id}, 状态: $statusText');
  }
}

/// 安全中间件工厂 - 业务方使用
class SecurityMiddlewareFactory {
  /// 创建默认安全中间件
  static ConfigurableSecurityMiddleware createDefault() {
    return ConfigurableSecurityMiddleware(
      policy: DefaultSecurityPolicy(),
    );
  }

  /// 创建自定义安全中间件
  static ConfigurableSecurityMiddleware createCustom({
    required SecurityPolicy policy,
    bool enabled = true,
    int priority = 20,
  }) {
    return ConfigurableSecurityMiddleware(
      policy: policy,
      enabled: enabled,
      priority: priority,
    );
  }
}

/// 权限检查接口 - 业务方实现
abstract class PermissionChecker {
  /// 检查用户是否有补丁执行权限
  Future<bool> checkPermission(String userId, String patchId);
  
  /// 获取检查器名称
  String get name;
  
  /// 获取检查器描述
  String get description;
}

/// 简单的权限检查中间件
class PermissionCheckMiddleware implements SimplePatchMiddleware {
  final PermissionChecker _checker;
  final bool _enabled;
  final int _priority;
  String? _currentUserId;

  PermissionCheckMiddleware({
    required PermissionChecker checker,
    bool enabled = true,
    int priority = 15,
  }) : _checker = checker,
       _enabled = enabled,
       _priority = priority;

  @override
  String get name => 'PermissionCheckMiddleware';

  @override
  String get description => '权限检查中间件，使用 ${_checker.name}';

  @override
  bool get enabled => _enabled;

  @override
  int get priority => _priority;

  /// 设置当前用户ID
  void setCurrentUser(String userId) {
    _currentUserId = userId;
    hotfixLogger.debug('设置当前用户: $userId');
  }

  @override
  Future<void> before(PatchModel patch) async {
    hotfixLogger.middlewareInfo(name, '开始权限检查', '补丁ID: ${patch.id}');
    
    // 获取当前用户ID
    final userId = _currentUserId ?? _getUserIdFromPatch(patch);
    
    if (userId == null) {
      final error = '无法确定当前用户ID';
      hotfixLogger.error('权限检查失败: $error');
      throw Exception(error);
    }

    // 检查用户权限
    final hasPermission = await _checker.checkPermission(userId, patch.id);
    if (!hasPermission) {
      final error = '用户无权限执行此补丁: ${patch.id}';
      hotfixLogger.error('权限检查失败: $error');
      throw Exception(error);
    }

    hotfixLogger.middlewareInfo(name, '权限检查通过', '用户: $userId, 补丁ID: ${patch.id}');
  }

  @override
  Future<void> after(PatchModel patch, PatchStatus status) async {
    final userId = _currentUserId ?? _getUserIdFromPatch(patch);
    hotfixLogger.middlewareInfo(name, '权限检查完成', '用户: $userId, 补丁ID: ${patch.id}, 状态: ${status.applied ? "成功" : "失败"}');
  }

  /// 从补丁元数据中获取用户ID
  String? _getUserIdFromPatch(PatchModel patch) {
    // 从补丁的额外信息中获取用户ID
    if (patch.extra != null && patch.extra!['userId'] != null) {
      return patch.extra!['userId'].toString();
    }
    
    // 从补丁ID中提取用户信息（如果使用特定格式）
    if (patch.id.contains('_user_')) {
      final parts = patch.id.split('_user_');
      if (parts.length > 1) {
        return parts[1];
      }
    }
    
    return null;
  }
}

/// 数据校验中间件
class DataValidationSimpleMiddleware implements SimplePatchMiddleware {
  @override
  String get name => 'DataValidationMiddleware';

  @override
  String get description => '验证补丁数据完整性的中间件';

  @override
  bool get enabled => true;

  @override
  int get priority => 25;

  @override
  Future<void> before(PatchModel patch) async {
    hotfixLogger.middlewareInfo(name, '开始数据校验', '补丁ID: ${patch.id}');
    
    // 验证补丁签名
    final isValid = await _verifyPatchSignature(patch);
    if (!isValid) {
      final error = '补丁签名验证失败: ${patch.id}';
      hotfixLogger.error('数据校验失败: $error');
      throw Exception(error);
    }

    // 检查补丁数据完整性
    if (!_validatePatchData(patch)) {
      final error = '补丁数据不完整: ${patch.id}';
      hotfixLogger.error('数据校验失败: $error');
      throw Exception(error);
    }

    hotfixLogger.middlewareInfo(name, '数据校验通过', '补丁ID: ${patch.id}');
  }

  @override
  Future<void> after(PatchModel patch, PatchStatus status) async {
    hotfixLogger.middlewareInfo(name, '数据校验完成', '补丁ID: ${patch.id}, 状态: ${status.applied ? "成功" : "失败"}');
  }

  /// 验证补丁签名
  Future<bool> _verifyPatchSignature(PatchModel patch) async {
    // 实际实现中这里会验证签名
    // 这里简化实现，实际应该使用加密库验证签名
    hotfixLogger.debug('验证补丁签名: ${patch.id}');
    return patch.signature.isNotEmpty;
  }

  /// 检查补丁数据完整性
  bool _validatePatchData(PatchModel patch) {
    // 检查必要字段是否存在
    if (patch.id.isEmpty || patch.entry.isEmpty || patch.downloadUrl.isEmpty) {
      hotfixLogger.warning('补丁数据不完整: ${patch.id}');
      return false;
    }
    
    // 检查版本号格式
    if (patch.version.isEmpty) {
      hotfixLogger.warning('补丁版本号为空: ${patch.id}');
      return false;
    }
    
    return true;
  }
} 