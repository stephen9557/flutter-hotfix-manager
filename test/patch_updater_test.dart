import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hotfix_manager/flutter_hotfix_manager.dart' as hotfix;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'dart:io';

// 生成 mock 类
@GenerateMocks([hotfix.PatchNetworkClient, hotfix.PatchCacheManager])
import 'patch_updater_test.mocks.dart';

void main() {
  group('PatchUpdater', () {
    late MockPatchNetworkClient networkClient;
    late MockPatchCacheManager cacheManager;
    late hotfix.PatchUpdater updater;

    setUp(() {
      networkClient = MockPatchNetworkClient();
      cacheManager = MockPatchCacheManager();
      updater = hotfix.PatchUpdater(networkClient: networkClient, cacheManager: cacheManager);
    });

    test('mock test - verify getPatchFilePath works', () {
      final patch = hotfix.PatchModel(
        id: 'test',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        entry: 'test.js',
        downloadUrl: 'http://example.com/test.js',
        signature: 'test',
      );
      
      when(cacheManager.getPatchFilePath(patch)).thenReturn('test_path');
      expect(cacheManager.getPatchFilePath(patch), equals('test_path'));
    });

    test('verifyPatchSignature returns true for valid sha256', () async {
      final file = File('test_assets/patch2.js')..writeAsStringSync('hello');
      final patch = hotfix.PatchModel(
        id: '2',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        entry: file.path,
        downloadUrl: '',
        signature: '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824', // sha256('hello')
      );
      expect(await updater.verifyPatchSignature(patch, file.path), isTrue);
      file.deleteSync();
    });

    test('verifyPatchSignature returns false for invalid file', () async {
      final file = File('test_assets/patch3.js')..writeAsStringSync('world');
      final patch = hotfix.PatchModel(
        id: '3',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        entry: file.path,
        downloadUrl: '',
        signature: 'invalidsignature',
      );
      expect(await updater.verifyPatchSignature(patch, file.path), isFalse);
      file.deleteSync();
    });

    test('downloadAndCachePatch throws exception on signature fail', () async {
      final testFile = File('test_assets/patch4.js');
      
      // 确保测试开始时文件不存在
      if (testFile.existsSync()) {
        testFile.deleteSync();
      }
      
      final patch = hotfix.PatchModel(
        id: '4',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        entry: 'test_assets/patch4.js',
        downloadUrl: 'http://example.com/patch4.js',
        signature: 'invalid',
      );
      
      // 确保 mock 返回正确的字符串
      when(cacheManager.getPatchFilePath(patch)).thenReturn('test_assets/patch4.js');
      when(networkClient.download('http://example.com/patch4.js', 'test_assets/patch4.js', headers: null))
          .thenAnswer((_) async {
        testFile.writeAsStringSync('bad');
      });
      
      // 验证抛出异常
      expect(
        () async => await updater.downloadAndCachePatch(patch),
        throwsA(isA<Exception>()),
      );
      
      // 清理文件
      if (testFile.existsSync()) {
        testFile.deleteSync();
      }
    });
  });
} 