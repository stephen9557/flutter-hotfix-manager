import 'package:flutter_hotfix_manager/flutter_hotfix_manager.dart';

/// 基本使用示例 - 展示如何作为二方库使用
void main() async {
  // 1. 初始化 SDK
  final config = FlutterHotfixConfig(
    serverUrl: 'https://mycompany.com/api/patches',
    appVersion: '1.0.0',
    userId: 'developer',
    channels: ['beta'],
    region: 'CN',
    cacheDir: 'cache',
  );
  await FlutterHotfixManager.init(config);

  // 2. 创建自定义安全策略
  final customSecurityPolicy = CustomSecurityPolicy();
  
  // 3. 创建可配置的安全中间件
  final securityMiddleware = ConfigurableSecurityMiddleware(
    policy: customSecurityPolicy,
    enabled: true,
    priority: 20,
  );

  // 4. 创建自定义权限检查器
  final permissionChecker = CustomPermissionChecker();
  
  // 5. 创建权限检查中间件
  final permissionMiddleware = PermissionCheckMiddleware(
    checker: permissionChecker,
    enabled: true,
    priority: 15,
  );

  // 6. 注册中间件
  SimpleMiddlewareManager.register(securityMiddleware);
  SimpleMiddlewareManager.register(permissionMiddleware);

  // 7. 设置当前用户
  permissionMiddleware.setCurrentUser('developer');

  // 8. 检查并应用补丁
  try {
    await FlutterHotfixManager.checkAndApply();
    print('补丁检查和应用完成');
  } catch (e) {
    print('补丁执行失败: $e');
  }
}

/// 自定义安全策略 - 业务方实现
class CustomSecurityPolicy implements SecurityPolicy {
  @override
  String get name => 'CustomSecurityPolicy';

  @override
  String get description => '自定义安全策略';

  @override
  Future<bool> checkExpiration(PatchModel patch) async {
    // 业务方自定义过期检查逻辑
    if (patch.expireAt == null) return true;
    return DateTime.now().isBefore(patch.expireAt!);
  }

  @override
  Future<bool> verifySignature(PatchModel patch) async {
    // 业务方自定义签名验证逻辑
    // 实际项目中应该使用加密库验证签名
    return patch.signature.isNotEmpty && patch.signature.length >= 32;
  }

  @override
  Future<bool> checkSourceTrust(PatchModel patch) async {
    // 业务方自定义来源检查逻辑
    final trustedDomains = [
      'mycompany.com',
      'cdn.mycompany.com',
      'localhost',
    ];
    
    try {
      final uri = Uri.parse(patch.downloadUrl);
      return trustedDomains.any((domain) => uri.host.contains(domain));
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> checkSizeLimit(PatchModel patch) async {
    // 业务方自定义大小限制
    const maxSize = 512 * 1024; // 512KB
    return patch.entry.length <= maxSize;
  }

  @override
  Future<bool> checkTypeSupport(PatchModel patch) async {
    // 业务方自定义类型支持
    return patch.type == PatchType.jsScript;
  }
}

/// 自定义权限检查器 - 业务方实现
class CustomPermissionChecker implements PermissionChecker {
  @override
  String get name => 'CustomPermissionChecker';

  @override
  String get description => '自定义权限检查器';

  @override
  Future<bool> checkPermission(String userId, String patchId) async {
    // 业务方自定义权限检查逻辑
    // 实际项目中应该调用权限服务 API
    
    // 模拟权限检查
    if (userId == 'admin') {
      return true; // 管理员有所有权限
    } else if (userId == 'developer') {
      return patchId.startsWith('dev_'); // 开发者只能执行开发补丁
    } else if (userId == 'tester') {
      return patchId.startsWith('test_'); // 测试者只能执行测试补丁
    } else {
      return false; // 其他用户无权限
    }
  }
}

/// 使用工厂方法创建中间件的示例
void factoryUsageExample() {
  // 使用工厂方法创建默认安全中间件
  final defaultSecurityMiddleware = SecurityMiddlewareFactory.createDefault();
  
  // 使用工厂方法创建自定义安全中间件
  final customPolicy = DefaultSecurityPolicy(
    trustedDomains: ['mycompany.com'],
    maxFileSize: 1024 * 1024, // 1MB
    supportedTypes: [PatchType.jsScript],
  );
  
  final customSecurityMiddleware = SecurityMiddlewareFactory.createCustom(
    policy: customPolicy,
    enabled: true,
    priority: 15,
  );
  
  // 注册中间件
  SimpleMiddlewareManager.register(defaultSecurityMiddleware);
  SimpleMiddlewareManager.register(customSecurityMiddleware);
}

/// 回调中间件使用示例
void callbackMiddlewareExample() {
  // 创建回调中间件
  final callbackMiddleware = CallbackSimpleMiddleware(
    name: 'CustomCallbackMiddleware',
    description: '自定义回调中间件',
    onBefore: (patch) async {
      print('补丁执行前回调: ${patch.id}');
    },
    onAfter: (patch, status) async {
      print('补丁执行后回调: ${patch.id}, 状态: ${status.applied}');
    },
    enabled: true,
    priority: 30,
  );
  
  // 注册回调中间件
  SimpleMiddlewareManager.register(callbackMiddleware);
} 