import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hotfix_manager/flutter_hotfix_manager.dart' as hotfix;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Security Middleware Tests', () {
    test('DefaultSecurityPolicy functionality', () async {
      final policy = hotfix.DefaultSecurityPolicy();
      
      final validPatch = hotfix.PatchModel(
        id: 'test_patch',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        entry: 'test.js',
        downloadUrl: 'https://patch.example.com/test.js',
        signature: 'valid_signature_32_chars_long_enough_for_test',
      );

      // 测试过期检查
      final expirationCheck = await policy.checkExpiration(validPatch);
      expect(expirationCheck, isTrue);

      // 测试签名验证
      final signatureCheck = await policy.verifySignature(validPatch);
      expect(signatureCheck, isTrue);

      // 测试来源检查
      final sourceCheck = await policy.checkSourceTrust(validPatch);
      expect(sourceCheck, isTrue);

      // 测试大小检查
      final sizeCheck = await policy.checkSizeLimit(validPatch);
      expect(sizeCheck, isTrue);

      // 测试类型检查
      final typeCheck = await policy.checkTypeSupport(validPatch);
      expect(typeCheck, isTrue);

      // 验证策略属性
      expect(policy.name, equals('DefaultSecurityPolicy'));
      expect(policy.description, equals('默认安全策略实现'));
    });

    test('DefaultSecurityPolicy with expired patch', () async {
      final policy = hotfix.DefaultSecurityPolicy();
      
      final expiredPatch = hotfix.PatchModel(
        id: 'expired_patch',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        entry: 'test.js',
        downloadUrl: 'https://patch.example.com/test.js',
        signature: 'valid_signature_32_chars_long_enough_for_test',
        expireAt: DateTime.now().subtract(Duration(hours: 1)), // 已过期
      );

      final expirationCheck = await policy.checkExpiration(expiredPatch);
      expect(expirationCheck, isFalse);
    });

    test('DefaultSecurityPolicy with invalid signature', () async {
      final policy = hotfix.DefaultSecurityPolicy();
      
      final invalidSignaturePatch = hotfix.PatchModel(
        id: 'invalid_signature_patch',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        entry: 'test.js',
        downloadUrl: 'https://patch.example.com/test.js',
        signature: '', // 空签名
      );

      final signatureCheck = await policy.verifySignature(invalidSignaturePatch);
      expect(signatureCheck, isFalse);
    });

    test('DefaultSecurityPolicy with untrusted source', () async {
      final policy = hotfix.DefaultSecurityPolicy();
      
      final untrustedPatch = hotfix.PatchModel(
        id: 'untrusted_patch',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        entry: 'test.js',
        downloadUrl: 'https://malicious.com/test.js', // 不可信来源
        signature: 'valid_signature_32_chars_long_enough_for_test',
      );

      final sourceCheck = await policy.checkSourceTrust(untrustedPatch);
      expect(sourceCheck, isFalse);
    });

    test('ConfigurableSecurityMiddleware functionality', () async {
      final policy = hotfix.DefaultSecurityPolicy();
      final middleware = hotfix.ConfigurableSecurityMiddleware(policy: policy);

      final validPatch = hotfix.PatchModel(
        id: 'test_patch',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        entry: 'test.js',
        downloadUrl: 'https://patch.example.com/test.js',
        signature: 'valid_signature_32_chars_long_enough_for_test',
      );

      final status = hotfix.PatchStatus(
        patchId: 'test_patch',
        type: hotfix.PatchType.jsScript,
        applied: true,
      );

      // 测试安全检查通过
      await middleware.before(validPatch);
      await middleware.after(validPatch, status);

      // 验证中间件属性
      expect(middleware.name, equals('ConfigurableSecurityMiddleware'));
      expect(middleware.enabled, isTrue);
      expect(middleware.priority, equals(20));
    });

    test('ConfigurableSecurityMiddleware with failed security check', () async {
      final policy = hotfix.DefaultSecurityPolicy();
      final middleware = hotfix.ConfigurableSecurityMiddleware(policy: policy);

      final invalidPatch = hotfix.PatchModel(
        id: 'invalid_patch',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        entry: 'test.js',
        downloadUrl: 'https://malicious.com/test.js', // 不可信来源
        signature: '', // 空签名
      );

      // 测试安全检查失败
      expect(() async {
        await middleware.before(invalidPatch);
      }, throwsException);
    });

    test('SecurityMiddlewareFactory functionality', () {
      // 测试创建默认安全中间件
      final defaultMiddleware = hotfix.SecurityMiddlewareFactory.createDefault();
      expect(defaultMiddleware, isA<hotfix.ConfigurableSecurityMiddleware>());
      expect(defaultMiddleware.name, equals('ConfigurableSecurityMiddleware'));

      // 测试创建自定义安全中间件
      final customPolicy = hotfix.DefaultSecurityPolicy(
        trustedDomains: ['mycompany.com'],
        maxFileSize: 512 * 1024, // 512KB
      );
      
      final customMiddleware = hotfix.SecurityMiddlewareFactory.createCustom(
        policy: customPolicy,
        enabled: true,
        priority: 15,
      );
      
      expect(customMiddleware, isA<hotfix.ConfigurableSecurityMiddleware>());
      expect(customMiddleware.enabled, isTrue);
      expect(customMiddleware.priority, equals(15));
    });

    test('PermissionChecker interface', () {
      // 测试权限检查接口
      final checker = _TestPermissionChecker();
      
      expect(checker.name, equals('TestPermissionChecker'));
      expect(checker.description, equals('测试权限检查器'));
    });

    test('PermissionCheckMiddleware functionality', () async {
      final checker = _TestPermissionChecker();
      final middleware = hotfix.PermissionCheckMiddleware(checker: checker);

      // 设置当前用户
      middleware.setCurrentUser('admin');

      final patch = hotfix.PatchModel(
        id: 'test_patch',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        entry: 'test.js',
        downloadUrl: 'https://example.com/test.js',
        signature: 'valid_signature_32_chars_long_enough_for_test',
        extra: {'userId': 'admin'},
      );

      final status = hotfix.PatchStatus(
        patchId: 'test_patch',
        type: hotfix.PatchType.jsScript,
        applied: true,
      );

      // 测试权限检查通过
      await middleware.before(patch);
      await middleware.after(patch, status);

      // 验证中间件属性
      expect(middleware.name, equals('PermissionCheckMiddleware'));
      expect(middleware.enabled, isTrue);
      expect(middleware.priority, equals(15));
    });

    test('PermissionCheckMiddleware with permission denied', () async {
      final checker = _TestPermissionChecker();
      final middleware = hotfix.PermissionCheckMiddleware(checker: checker);

      // 设置当前用户
      middleware.setCurrentUser('user');

      final patch = hotfix.PatchModel(
        id: 'test_patch',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        entry: 'test.js',
        downloadUrl: 'https://example.com/test.js',
        signature: 'valid_signature_32_chars_long_enough_for_test',
        extra: {'userId': 'user'},
      );

      // 测试权限检查失败
      expect(() async {
        await middleware.before(patch);
      }, throwsException);
    });

    test('DataValidationSimpleMiddleware functionality', () async {
      final middleware = hotfix.DataValidationSimpleMiddleware();

      final validPatch = hotfix.PatchModel(
        id: 'test_patch',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        entry: 'test.js',
        downloadUrl: 'https://example.com/test.js',
        signature: 'valid_signature_32_chars_long_enough_for_test',
      );

      final status = hotfix.PatchStatus(
        patchId: 'test_patch',
        type: hotfix.PatchType.jsScript,
        applied: true,
      );

      // 测试数据校验通过
      await middleware.before(validPatch);
      await middleware.after(validPatch, status);

      // 验证中间件属性
      expect(middleware.name, equals('DataValidationMiddleware'));
      expect(middleware.enabled, isTrue);
      expect(middleware.priority, equals(25));
    });
  });
}

/// 测试权限检查器实现
class _TestPermissionChecker implements hotfix.PermissionChecker {
  @override
  String get name => 'TestPermissionChecker';

  @override
  String get description => '测试权限检查器';

  @override
  Future<bool> checkPermission(String userId, String patchId) async {
    // 模拟权限检查逻辑
    if (userId == 'admin') {
      return true; // 管理员有所有权限
    } else if (userId == 'developer') {
      return patchId.startsWith('dev_'); // 开发者只能执行开发补丁
    } else {
      return false; // 其他用户无权限
    }
  }
} 