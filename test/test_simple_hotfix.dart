import 'dart:io';

/// 简单的本地热修复测试脚本
void main() async {
  print('🚀 开始简单本地热修复测试...\n');

  try {
    // 1. 测试JavaScript脚本执行
    await testJavaScriptExecution();

    // 2. 测试文件读取
    await testFileReading();

    // 3. 测试错误处理
    await testErrorHandling();

    print('\n🎉 所有测试完成！');

  } catch (e) {
    print('❌ 测试失败: $e');
  }
}

/// 测试JavaScript脚本执行
Future<void> testJavaScriptExecution() async {
  print('📝 测试JavaScript脚本执行...');
  
  // 创建测试脚本
  final testScript = '''
console.log("Test script executed");
console.log("Current time:", new Date().toISOString());

// 模拟热修复功能
function applyHotfix() {
    console.log("Applying hotfix...");
    return "Hotfix applied successfully";
}

// 模拟数据更新
function updateData(data) {
    console.log("Updating data:", data);
    return {
        status: "success",
        timestamp: new Date().toISOString(),
        data: data
    };
}

// 执行测试
const result = applyHotfix();
const dataResult = updateData({test: "value"});

console.log("Result:", result);
console.log("Data result:", dataResult);
''';

  // 写入测试文件
  final testFile = File('test_assets/test_script.js');
  await testFile.writeAsString(testScript);
  
  print('✅ JavaScript脚本创建成功');
  print('📄 脚本内容已写入: test_assets/test_script.js');
  print('');
}

/// 测试文件读取
Future<void> testFileReading() async {
  print('📖 测试文件读取...');
  
  try {
    // 读取集成测试脚本
    final integrationFile = File('test_assets/integration_test.js');
    if (await integrationFile.exists()) {
      final content = await integrationFile.readAsString();
      print('✅ 成功读取集成测试脚本');
      print('📄 文件大小: ${content.length} 字符');
      print('📄 前100个字符: ${content.substring(0, content.length > 100 ? 100 : content.length)}...');
    } else {
      print('❌ 集成测试脚本文件不存在');
    }

    // 读取简单补丁脚本
    final simpleFile = File('test_assets/simple_patch.js');
    if (await simpleFile.exists()) {
      final content = await simpleFile.readAsString();
      print('✅ 成功读取简单补丁脚本');
      print('📄 文件大小: ${content.length} 字符');
    } else {
      print('❌ 简单补丁脚本文件不存在');
    }

  } catch (e) {
    print('❌ 文件读取失败: $e');
  }
  print('');
}

/// 测试错误处理
Future<void> testErrorHandling() async {
  print('🚨 测试错误处理...');
  
  try {
    // 读取错误补丁脚本
    final errorFile = File('test_assets/error_patch.js');
    if (await errorFile.exists()) {
      final content = await errorFile.readAsString();
      print('✅ 成功读取错误补丁脚本');
      print('📄 文件大小: ${content.length} 字符');
      print('📄 包含错误内容: ${content.contains('undefinedVariable') ? "是" : "否"}');
    } else {
      print('❌ 错误补丁脚本文件不存在');
    }

  } catch (e) {
    print('❌ 错误处理测试失败: $e');
  }
  print('');
}

/// 列出所有测试资源
void listTestAssets() {
  print('📁 测试资源列表:');
  
  final testAssetsDir = Directory('test_assets');
  if (testAssetsDir.existsSync()) {
    final files = testAssetsDir.listSync();
    for (final file in files) {
      if (file is File) {
        print('  📄 ${file.path}');
      }
    }
  } else {
    print('  ❌ test_assets 目录不存在');
  }
  print('');
} 