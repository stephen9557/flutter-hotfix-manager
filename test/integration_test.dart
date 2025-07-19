import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hotfix_manager/flutter_hotfix_manager.dart' as hotfix;
import 'package:mockito/mockito.dart';
import 'dart:io';

class MockPatchNetworkClient extends Mock implements hotfix.PatchNetworkClient {}
class MockPatchCacheManager extends Mock implements hotfix.PatchCacheManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Integration Tests', () {
    test('complete patch workflow', () async {
      // 创建测试配置
      final config = hotfix.FlutterHotfixConfig(
        serverUrl: 'http://example.com/api/patches',
        appVersion: '1.0.0',
        userId: 'test_user',
        channels: ['beta'],
        region: 'CN',
        cacheDir: 'test_assets/cache',
      );

      // 初始化 SDK
      await hotfix.FlutterHotfixManager.init(config);

      // 创建测试补丁
      final jsFile = File('test_assets/integration_test.js')..writeAsStringSync('console.log("test");');
      final rollbackFile = File('test_assets/integration_test.rollback.js')..writeAsStringSync('console.log("rollback");');
      
      final patch = hotfix.PatchModel(
        id: 'integration_test',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        channel: 'beta',
        region: 'CN',
        entry: jsFile.path,
        downloadUrl: 'http://example.com/patch.js',
        signature: 'test_signature',
      );

      // 测试补丁执行
      final executor = hotfix.DefaultPatchExecutor();
      final status = await executor.execute(patch);
      
      expect(status.patchId, 'integration_test');
      expect(status.type, hotfix.PatchType.jsScript);
      expect(status.applied, isTrue);

      // 清理测试文件
      jsFile.deleteSync();
      rollbackFile.deleteSync();
    });

    test('patch status persistence', () async {
      final statusManager = hotfix.PatchStatusManager('test_assets/test_status.json');
      
      final patchStatus = hotfix.PatchStatus(
        patchId: 'persistence_test',
        type: hotfix.PatchType.jsScript,
        applied: true,
        appliedAt: DateTime.now(),
      );

      // 测试状态持久化
      statusManager.updateAppliedPatches([patchStatus]);
      await statusManager.persistAppliedPatches();

      // 测试状态恢复
      statusManager.updateAppliedPatches([]);
      await statusManager.restoreAppliedPatches();

      expect(statusManager.appliedPatches.length, 1);
      expect(statusManager.appliedPatches.first.patchId, 'persistence_test');

      // 清理测试文件
      final file = File('test_assets/test_status.json');
      if (file.existsSync()) file.deleteSync();
    });
  });
} 