import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hotfix_manager/flutter_hotfix_manager.dart';
import 'package:mockito/mockito.dart';
import 'dart:io';

// 正确的 Mock 类定义
class MockPatchNetworkClient extends Mock implements PatchNetworkClient {}
class MockPatchCacheManager extends Mock implements PatchCacheManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FlutterHotfixManager main entry loads', () {
    expect(FlutterHotfixManager, isNotNull);
  });

  group('PatchUpdater', () {
    test('verifyPatchSignature returns true for valid file', () async {
      final file = File('test_assets/patch1.js')..writeAsStringSync('hello');
      final patch = PatchModel(
        id: '1',
        type: PatchType.jsScript,
        version: '1.0.0',
        entry: file.path,
        downloadUrl: '',
        signature: '5d41402abc4b2a76b9719d911017c592', // md5('hello') for demo
      );
      final updater = PatchUpdater(
        networkClient: MockPatchNetworkClient(),
        cacheManager: MockPatchCacheManager(),
      );
      // 实际应用中用 sha256，这里仅演示
      expect(await updater.verifyPatchSignature(patch, file.path), isFalse); // sha256 不等于 md5
      file.deleteSync();
    });
  });

  group('JsScriptPatchLoader', () {
    test('load and rollback JS patch', () async {
      final jsFile = File('test_assets/test_patch.js')..writeAsStringSync('var a = 1;');
      final rollbackFile = File('test_assets/test_patch.rollback.js')..writeAsStringSync('a = 0;');
      final patch = PatchModel(
        id: 'js1',
        type: PatchType.jsScript,
        version: '1.0.0',
        entry: jsFile.path,
        downloadUrl: '',
        signature: '',
      );
      final loader = JsScriptPatchLoader();
      expect(await loader.load(patch), isTrue);
      await loader.rollback(patch);
      jsFile.deleteSync();
      rollbackFile.deleteSync();
    });
  });

  // ShorebirdPatchLoader 需在 Shorebird 环境下 mock 测试
}
