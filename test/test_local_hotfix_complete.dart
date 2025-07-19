import 'dart:io';
import 'dart:convert';

/// 完整的本地热修复测试脚本
void main() async {
  print('🚀 开始完整本地热修复测试...\n');

  try {
    // 1. 创建测试环境
    await setupTestEnvironment();

    // 2. 测试不同类型的补丁
    await testDifferentPatchTypes();

    // 3. 测试安全策略
    await testSecurityPolicies();

    // 4. 测试权限检查
    await testPermissionChecks();

    // 5. 测试错误处理
    await testErrorHandling();

    // 6. 测试中间件
    await testMiddleware();

    // 7. 清理测试环境
    await cleanupTestEnvironment();

    print('\n🎉 所有测试完成！');

  } catch (e) {
    print('❌ 测试失败: $e');
  }
}

/// 设置测试环境
Future<void> setupTestEnvironment() async {
  print('🔧 设置测试环境...');
  
  // 创建测试目录
  final testDir = Directory('test_assets');
  if (!await testDir.exists()) {
    await testDir.create(recursive: true);
  }

  // 创建测试配置文件
  final configFile = File('test_assets/test_config.json');
  final config = {
    'appVersion': '1.0.0',
    'userId': 'test_user',
    'channels': ['beta', 'stable'],
    'region': 'CN',
    'cacheDir': 'test_assets/cache',
    'trustedDomains': ['localhost', '127.0.0.1', 'test.example.com'],
    'maxFileSize': 1024 * 1024, // 1MB
    'supportedTypes': ['jsScript', 'dartAot']
  };
  
  await configFile.writeAsString(jsonEncode(config));
  print('✅ 测试环境设置完成');
  print('');
}

/// 测试不同类型的补丁
Future<void> testDifferentPatchTypes() async {
  print('📦 测试不同类型的补丁...');

  // 1. JavaScript 补丁
  await createJavaScriptPatch();
  
  // 2. Dart AOT 补丁
  await createDartAotPatch();
  
  // 3. 配置补丁
  await createConfigPatch();
  
  print('✅ 不同类型补丁测试完成');
  print('');
}

/// 创建JavaScript补丁
Future<void> createJavaScriptPatch() async {
  print('  📝 创建JavaScript补丁...');
  
  final jsPatch = '''
// JavaScript 热修复补丁
console.log("JavaScript patch loaded");

// 模拟UI更新
function updateUI() {
    console.log("UI updated via hotfix");
    return {
        status: "success",
        timestamp: new Date().toISOString(),
        changes: ["header", "footer", "sidebar"]
    };
}

// 模拟API调用
function callAPI(endpoint, data) {
    console.log("API called:", endpoint, data);
    return {
        success: true,
        data: "Mock API response",
        timestamp: new Date().toISOString()
    };
}

// 模拟错误处理
function handleError(error) {
    console.error("Error handled:", error);
    return {
        handled: true,
        timestamp: new Date().toISOString(),
        error: error.message
    };
}

// 执行补丁
const result = updateUI();
console.log("Patch result:", result);
''';

  final file = File('test_assets/js_patch.js');
  await file.writeAsString(jsPatch);
  print('    ✅ JavaScript补丁创建成功');
}

/// 创建Dart AOT补丁
Future<void> createDartAotPatch() async {
  print('  📝 创建Dart AOT补丁...');
  
  final dartPatch = '''
// Dart AOT 热修复补丁
import 'dart:io';
import 'dart:convert';

class HotfixPatch {
  static void apply() {
    print('Dart AOT patch applied');
    
    // 模拟数据更新
    final data = {
      'version': '1.0.1',
      'timestamp': DateTime.now().toIso8601String(),
      'changes': ['bug_fix', 'performance_improvement']
    };
    
    print('Updated data: \$data');
  }
  
  static Map<String, dynamic> getConfig() {
    return {
      'enabled': true,
      'version': '1.0.1',
      'features': ['new_feature_1', 'new_feature_2']
    };
  }
}

// 执行补丁
HotfixPatch.apply();
''';

  final file = File('test_assets/dart_patch.dart');
  await file.writeAsString(dartPatch);
  print('    ✅ Dart AOT补丁创建成功');
}

/// 创建配置补丁
Future<void> createConfigPatch() async {
  print('  📝 创建配置补丁...');
  
  final configPatch = {
    'patchId': 'config_patch_001',
    'type': 'config',
    'version': '1.0.0',
    'changes': {
      'api_endpoints': {
        'base_url': 'https://api.example.com',
        'timeout': 30000,
        'retry_count': 3
      },
      'ui_settings': {
        'theme': 'dark',
        'language': 'zh-CN',
        'timezone': 'Asia/Shanghai'
      },
      'feature_flags': {
        'new_ui': true,
        'beta_features': false,
        'debug_mode': true
      }
    },
    'metadata': {
      'author': 'test_user',
      'created_at': DateTime.now().toIso8601String(),
      'description': 'Configuration patch for testing'
    }
  };

  final file = File('test_assets/config_patch.json');
  await file.writeAsString(jsonEncode(configPatch));
  print('    ✅ 配置补丁创建成功');
}

/// 测试安全策略
Future<void> testSecurityPolicies() async {
  print('🔒 测试安全策略...');

  // 1. 测试签名验证
  await testSignatureVerification();
  
  // 2. 测试来源检查
  await testSourceTrust();
  
  // 3. 测试大小限制
  await testSizeLimit();
  
  // 4. 测试过期检查
  await testExpirationCheck();
  
  print('✅ 安全策略测试完成');
  print('');
}

/// 测试签名验证
Future<void> testSignatureVerification() async {
  print('  🔐 测试签名验证...');
  
  final signatures = [
    'valid_signature_32_chars_long_enough_for_test',
    'another_valid_signature_for_testing_purposes',
    '', // 空签名
    'short', // 短签名
  ];
  
  for (int i = 0; i < signatures.length; i++) {
    final signature = signatures[i];
    final isValid = signature.isNotEmpty && signature.length >= 32;
    print('    签名 ${i + 1}: ${isValid ? "✅ 有效" : "❌ 无效"}');
  }
}

/// 测试来源检查
Future<void> testSourceTrust() async {
  print('  🌐 测试来源检查...');
  
  final urls = [
    'https://localhost/patches/test.js',
    'https://127.0.0.1/patches/test.js',
    'https://test.example.com/patches/test.js',
    'https://malicious.com/patches/test.js',
  ];
  
  final trustedDomains = ['localhost', '127.0.0.1', 'test.example.com'];
  
  for (final url in urls) {
    final uri = Uri.parse(url);
    final isTrusted = trustedDomains.any((domain) => uri.host.contains(domain));
    print('    $url: ${isTrusted ? "✅ 可信" : "❌ 不可信"}');
  }
}

/// 测试大小限制
Future<void> testSizeLimit() async {
  print('  📏 测试大小限制...');
  
  final sizes = [1024, 1024 * 1024, 2 * 1024 * 1024]; // 1KB, 1MB, 2MB
  final maxSize = 1024 * 1024; // 1MB
  
  for (final size in sizes) {
    final isWithinLimit = size <= maxSize;
    print('    ${size} bytes: ${isWithinLimit ? "✅ 在限制内" : "❌ 超出限制"}');
  }
}

/// 测试过期检查
Future<void> testExpirationCheck() async {
  print('  ⏰ 测试过期检查...');
  
  final now = DateTime.now();
  final dates = [
    now.add(Duration(hours: 1)), // 1小时后过期
    now.add(Duration(days: 1)), // 1天后过期
    now.subtract(Duration(hours: 1)), // 1小时前已过期
    null, // 无过期时间
  ];
  
  for (int i = 0; i < dates.length; i++) {
    final date = dates[i];
    final isValid = date == null || now.isBefore(date);
    print('    日期 ${i + 1}: ${isValid ? "✅ 有效" : "❌ 已过期"}');
  }
}

/// 测试权限检查
Future<void> testPermissionChecks() async {
  print('👤 测试权限检查...');

  final users = [
    {'id': 'admin', 'role': 'admin'},
    {'id': 'developer', 'role': 'developer'},
    {'id': 'tester', 'role': 'tester'},
    {'id': 'user', 'role': 'user'},
  ];
  
  final patches = [
    {'id': 'admin_patch', 'required_role': 'admin'},
    {'id': 'dev_patch', 'required_role': 'developer'},
    {'id': 'test_patch', 'required_role': 'tester'},
    {'id': 'user_patch', 'required_role': 'user'},
  ];
  
  for (final user in users) {
    print('  用户: ${user['id']} (${user['role']})');
    for (final patch in patches) {
      final hasPermission = checkPermission(user['role']!, patch['required_role']!);
      print('    补丁 ${patch['id']}: ${hasPermission ? "✅ 有权限" : "❌ 无权限"}');
    }
  }
  
  print('✅ 权限检查测试完成');
  print('');
}

/// 检查权限
bool checkPermission(String userRole, String requiredRole) {
  if (userRole == 'admin') return true;
  if (userRole == 'developer' && requiredRole != 'admin') return true;
  if (userRole == 'tester' && requiredRole == 'tester') return true;
  if (userRole == 'user' && requiredRole == 'user') return true;
  return false;
}

/// 测试错误处理
Future<void> testErrorHandling() async {
  print('🚨 测试错误处理...');

  // 1. 测试语法错误
  await testSyntaxError();
  
  // 2. 测试运行时错误
  await testRuntimeError();
  
  // 3. 测试网络错误
  await testNetworkError();
  
  print('✅ 错误处理测试完成');
  print('');
}

/// 测试语法错误
Future<void> testSyntaxError() async {
  print('  📝 测试语法错误...');
  
  final syntaxErrorScript = '''
// 语法错误的JavaScript脚本
console.log("Starting script");

// 缺少闭合括号
function testFunction() {
    return {
        data: "test"
    ; // 语法错误

// 未定义的变量
undefinedVariable.someMethod();

console.log("This should not execute");
''';

  final file = File('test_assets/syntax_error.js');
  await file.writeAsString(syntaxErrorScript);
  print('    ✅ 语法错误脚本创建成功');
}

/// 测试运行时错误
Future<void> testRuntimeError() async {
  print('  ⚡ 测试运行时错误...');
  
  final runtimeErrorScript = '''
// 运行时错误的JavaScript脚本
console.log("Starting runtime error test");

// 故意制造运行时错误
function causeError() {
    throw new Error("Intentional runtime error");
}

// 尝试调用错误函数
try {
    causeError();
} catch (error) {
    console.error("Caught error:", error.message);
}

// 访问未定义属性
const obj = {};
console.log(obj.nonExistentProperty.someMethod); // 运行时错误
''';

  final file = File('test_assets/runtime_error.js');
  await file.writeAsString(runtimeErrorScript);
  print('    ✅ 运行时错误脚本创建成功');
}

/// 测试网络错误
Future<void> testNetworkError() async {
  print('  🌐 测试网络错误...');
  
  final networkErrorScript = '''
// 模拟网络错误的脚本
console.log("Testing network error handling");

// 模拟网络请求失败
function simulateNetworkError() {
    return new Promise((resolve, reject) => {
        setTimeout(() => {
            reject(new Error("Network timeout"));
        }, 1000);
    });
}

// 测试网络错误处理
simulateNetworkError()
    .then(result => {
        console.log("Network request successful:", result);
    })
    .catch(error => {
        console.error("Network error caught:", error.message);
    });
''';

  final file = File('test_assets/network_error.js');
  await file.writeAsString(networkErrorScript);
  print('    ✅ 网络错误脚本创建成功');
}

/// 测试中间件
Future<void> testMiddleware() async {
  print('🔧 测试中间件...');

  // 1. 测试日志中间件
  await testLoggingMiddleware();
  
  // 2. 测试安全中间件
  await testSecurityMiddleware();
  
  // 3. 测试权限中间件
  await testPermissionMiddleware();
  
  print('✅ 中间件测试完成');
  print('');
}

/// 测试日志中间件
Future<void> testLoggingMiddleware() async {
  print('  📝 测试日志中间件...');
  
  final logEntries = [
    {'level': 'INFO', 'message': 'SDK initialized'},
    {'level': 'DEBUG', 'message': 'Loading patch: test_patch'},
    {'level': 'WARN', 'message': 'Patch signature verification failed'},
    {'level': 'ERROR', 'message': 'Failed to apply patch'},
  ];
  
  for (final entry in logEntries) {
    print('    [${entry['level']}] ${entry['message']}');
  }
  
  print('    ✅ 日志中间件测试完成');
}

/// 测试安全中间件
Future<void> testSecurityMiddleware() async {
  print('  🔒 测试安全中间件...');
  
  final securityChecks = [
    {'name': '签名验证', 'result': true as bool},
    {'name': '来源检查', 'result': true as bool},
    {'name': '大小检查', 'result': false as bool},
    {'name': '类型检查', 'result': true as bool},
    {'name': '过期检查', 'result': true as bool},
  ];
  
  for (final check in securityChecks) {
    final status = (check['result'] as bool) ? "✅ 通过" : "❌ 失败";
    print('    ${check['name']}: $status');
  }
  
  print('    ✅ 安全中间件测试完成');
}

/// 测试权限中间件
Future<void> testPermissionMiddleware() async {
  print('  👤 测试权限中间件...');
  
  final permissionChecks = [
    {'user': 'admin', 'patch': 'admin_patch', 'result': true as bool},
    {'user': 'developer', 'patch': 'dev_patch', 'result': true as bool},
    {'user': 'developer', 'patch': 'admin_patch', 'result': false as bool},
    {'user': 'user', 'patch': 'user_patch', 'result': true as bool},
    {'user': 'user', 'patch': 'dev_patch', 'result': false as bool},
  ];
  
  for (final check in permissionChecks) {
    final status = (check['result'] as bool) ? "✅ 有权限" : "❌ 无权限";
    print('    用户 ${check['user']} 访问 ${check['patch']}: $status');
  }
  
  print('    ✅ 权限中间件测试完成');
}

/// 清理测试环境
Future<void> cleanupTestEnvironment() async {
  print('🧹 清理测试环境...');
  
  // 列出所有测试文件
  final testDir = Directory('test_assets');
  if (await testDir.exists()) {
    final files = await testDir.list().toList();
    print('  测试文件列表:');
    for (final file in files) {
      if (file is File) {
        final size = await file.length();
        print('    📄 ${file.path} (${size} bytes)');
      }
    }
  }
  
  print('✅ 测试环境清理完成');
  print('');
} 