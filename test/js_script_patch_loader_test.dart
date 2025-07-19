import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hotfix_manager/flutter_hotfix_manager.dart' as hotfix;
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JsScriptPatchLoader', () {
    test('load returns false if file does not exist', () async {
      final patch = hotfix.PatchModel(
        id: 'notfound',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        entry: 'test_assets/not_exist.js',
        downloadUrl: '',
        signature: '',
      );
      final loader = hotfix.JsScriptPatchLoader();
      expect(await loader.load(patch), isFalse);
    });

    test('rollback prints warning if no rollback script', () async {
      final patch = hotfix.PatchModel(
        id: 'no_rollback',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        entry: 'test_assets/no_rollback.js',
        downloadUrl: '',
        signature: '',
      );
      final loader = hotfix.JsScriptPatchLoader();
      await loader.rollback(patch); // 应有日志输出
    });

    test('load/rollback handles JS error gracefully', () async {
      final jsFile = File('test_assets/error_patch.js')..writeAsStringSync('throw new Error("fail");');
      final rollbackFile = File('test_assets/error_patch.rollback.js')..writeAsStringSync('throw new Error("rollback fail");');
      final patch = hotfix.PatchModel(
        id: 'error',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        entry: jsFile.path,
        downloadUrl: '',
        signature: '',
      );
      final loader = hotfix.JsScriptPatchLoader();
      await loader.load(patch);
      await loader.rollback(patch);
      jsFile.deleteSync();
      rollbackFile.deleteSync();
    });
  });
} 