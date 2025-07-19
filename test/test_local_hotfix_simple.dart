import 'package:flutter_hotfix_manager/flutter_hotfix_manager.dart';
import 'dart:io';

/// 简化的本地热修复测试脚本 - 不依赖网络
void main() async {
  print('🚀 开始简化本地热修复测试...\n');

  try {
    // 1. 初始化 SDK
    print('📦 初始化 SDK...');
    final config = FlutterHotfixConfig(
      serverUrl: 'http://localhost:8080/api/patches',
      appVersion: '1.0.0',
      userId: 'test_user',
      channels: ['beta'],
      region: 'CN',
      cacheDir: 'test_assets/cache',
    );
    await FlutterHotfixManager.init(config);
    print('✅ SDK 初始化完成\n');

    // 2. 创建自定义安全策略
    print('🔒 创建安全策略...');
    final securityPolicy = LocalTestSecurityPolicy();
    final securityMiddleware = ConfigurableSecurityMiddleware(
      policy: securityPolicy,
      enabled: true,
      priority: 20,
    );

    // 3. 创建权限检查器
    print('👤 创建权限检查器...');
    final permissionChecker = LocalTestPermissionChecker();
    final permissionMiddleware = PermissionCheckMiddleware(
      checker: permissionChecker,
      enabled: true,
      priority: 15,
    );

    // 4. 注册中间件
    print('🔧 注册中间件...');
    SimpleMiddlewareManager.register(securityMiddleware);
    SimpleMiddlewareManager.register(permissionMiddleware);
    print('✅ 中间件注册完成\n');

    // 5. 设置当前用户
    permissionMiddleware.setCurrentUser('developer');

    // 6. 测试基本功能
    await testBasicFunctions();

    // 7. 测试权限检查
    await testPermissionCheck(permissionMiddleware);

    // 8. 测试错误处理
    await testErrorHandling();

    print('\n🎉 所有测试完成！');

  } catch (e) {
    print('❌ 测试失败: $e');
  }
}

/// 测试基本功能
Future<void> testBasicFunctions() async {
  print('📝 测试基本功能...');
  
  try {
    // 测试查询已应用的补丁
    final patches = await FlutterHotfixManager.getAppliedPatches();
    print('✅ 查询已应用补丁成功，数量: ${patches.length}');
    
    // 测试清理不存在的补丁
    await FlutterHotfixManager.clearPatch('non_existent_patch');
    print('✅ 清理不存在的补丁成功');
    
  } catch (e) {
    print('❌ 基本功能测试失败: $e');
  }
  print('');
}

/// 测试权限检查
Future<void> testPermissionCheck(PermissionCheckMiddleware permissionMiddleware) async {
  print('🔐 测试权限检查...');
  
  // 测试开发者权限
  permissionMiddleware.setCurrentUser('developer');
  try {
    final patches = await FlutterHotfixManager.getAppliedPatches();
    print('✅ 开发者权限测试成功，已应用补丁数量: ${patches.length}');
  } catch (e) {
    print('❌ 开发者权限测试失败: $e');
  }

  // 测试普通用户权限
  permissionMiddleware.setCurrentUser('user');
  try {
    final patches = await FlutterHotfixManager.getAppliedPatches();
    print('✅ 普通用户权限测试成功，已应用补丁数量: ${patches.length}');
  } catch (e) {
    print('❌ 普通用户权限测试失败: $e');
  }

  // 测试管理员权限
  permissionMiddleware.setCurrentUser('admin');
  try {
    final patches = await FlutterHotfixManager.getAppliedPatches();
    print('✅ 管理员权限测试成功，已应用补丁数量: ${patches.length}');
  } catch (e) {
    print('❌ 管理员权限测试失败: $e');
  }
  print('');
}

/// 测试错误处理
Future<void> testErrorHandling() async {
  print('🚨 测试错误处理...');
  
  try {
    // 测试清理不存在的补丁
    await FlutterHotfixManager.clearPatch('non_existent_patch');
    print('✅ 错误处理测试成功 - 正确处理了不存在的补丁');
  } catch (e) {
    print('❌ 错误处理测试失败: $e');
  }
  print('');
}

/// 本地测试安全策略
class LocalTestSecurityPolicy implements SecurityPolicy {
  @override
  String get name => 'LocalTestSecurityPolicy';

  @override
  String get description => '本地测试安全策略';

  @override
  Future<bool> checkExpiration(PatchModel patch) async {
    if (patch.expireAt == null) return true;
    return DateTime.now().isBefore(patch.expireAt!);
  }

  @override
  Future<bool> verifySignature(PatchModel patch) async {
    // 本地测试时放宽签名验证
    return patch.signature.isNotEmpty && patch.signature.length >= 10;
  }

  @override
  Future<bool> checkSourceTrust(PatchModel patch) async {
    // 本地测试时允许 localhost
    final trustedDomains = ['localhost', '127.0.0.1'];
    try {
      final uri = Uri.parse(patch.downloadUrl);
      return trustedDomains.any((domain) => uri.host.contains(domain));
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> checkSizeLimit(PatchModel patch) async {
    const maxSize = 1024 * 1024; // 1MB
    return patch.entry.length <= maxSize;
  }

  @override
  Future<bool> checkTypeSupport(PatchModel patch) async {
    return patch.type == PatchType.jsScript;
  }
}

/// 本地测试权限检查器
class LocalTestPermissionChecker implements PermissionChecker {
  @override
  String get name => 'LocalTestPermissionChecker';

  @override
  String get description => '本地测试权限检查器';

  @override
  Future<bool> checkPermission(String userId, String patchId) async {
    // 本地测试时的权限逻辑
    if (userId == 'admin') {
      return true; // 管理员有所有权限
    } else if (userId == 'developer') {
      return patchId.startsWith('dev_') || patchId.startsWith('normal_'); // 开发者权限
    } else if (userId == 'tester') {
      return patchId.startsWith('test_'); // 测试者权限
    } else {
      return false; // 其他用户无权限
    }
  }
} 