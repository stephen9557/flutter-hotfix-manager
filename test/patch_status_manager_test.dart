import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hotfix_manager/flutter_hotfix_manager.dart' as hotfix;
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PatchStatusManager', () {
    late hotfix.PatchStatusManager manager;
    late String statusFile;

    setUp(() {
      statusFile = 'test_assets/applied_patches.json';
      manager = hotfix.PatchStatusManager(statusFile);
    });

    tearDown(() {
      final file = File(statusFile);
      if (file.existsSync()) file.deleteSync();
    });

    test('persist and restore applied patches', () async {
      final patchStatus = hotfix.PatchStatus(
        patchId: 'p1',
        type: hotfix.PatchType.jsScript,
        applied: true,
        appliedAt: DateTime.now(),
        error: null,
        extra: null,
      );
      manager.updateAppliedPatches([patchStatus]);
      await manager.persistAppliedPatches();
      manager.updateAppliedPatches([]);
      await manager.restoreAppliedPatches();
      expect(manager.appliedPatches.length, 1);
      expect(manager.appliedPatches.first.patchId, 'p1');
    });

    test('remove and find applied patch', () async {
      final patchStatus = hotfix.PatchStatus(
        patchId: 'p2',
        type: hotfix.PatchType.jsScript,
        applied: true,
        appliedAt: DateTime.now(),
        error: null,
        extra: null,
      );
      manager.updateAppliedPatches([patchStatus]);
      expect(manager.findAppliedPatch('p2', hotfix.PatchType.jsScript), isNotNull);
      manager.removeAppliedPatch('p2', hotfix.PatchType.jsScript);
      expect(manager.findAppliedPatch('p2', hotfix.PatchType.jsScript), isNull);
    });
  });
} 