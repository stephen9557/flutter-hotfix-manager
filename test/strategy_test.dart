import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hotfix_manager/flutter_hotfix_manager.dart' as hotfix;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PatchStrategy', () {
    test('VersionStrategy matches exact version', () {
      final strategy = hotfix.VersionStrategy();
      final patch = hotfix.PatchModel(
        id: 'v1',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        entry: '',
        downloadUrl: '',
        signature: '',
      );
      expect(strategy.isHit(patch, userId: 'user1', appVersion: '1.0.0'), isTrue);
      expect(strategy.isHit(patch, userId: 'user1', appVersion: '1.0.1'), isFalse);
    });

    test('ChannelStrategy matches channel', () {
      final strategy = hotfix.ChannelStrategy();
      final patch = hotfix.PatchModel(
        id: 'c1',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        channel: 'beta',
        entry: '',
        downloadUrl: '',
        signature: '',
      );
      expect(strategy.isHit(patch, userId: 'user1', appVersion: '1.0.0', channels: ['beta', 'stable']), isTrue);
      expect(strategy.isHit(patch, userId: 'user1', appVersion: '1.0.0', channels: ['stable']), isFalse);
    });

    test('RegionStrategy matches region', () {
      final strategy = hotfix.RegionStrategy();
      final patch = hotfix.PatchModel(
        id: 'r1',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        region: 'CN',
        entry: '',
        downloadUrl: '',
        signature: '',
      );
      expect(strategy.isHit(patch, userId: 'user1', appVersion: '1.0.0', region: 'CN'), isTrue);
      expect(strategy.isHit(patch, userId: 'user1', appVersion: '1.0.0', region: 'US'), isFalse);
    });

    test('CompositePatchStrategy combines strategies', () {
      final strategy = hotfix.CompositePatchStrategy([
        hotfix.VersionStrategy(),
        hotfix.ChannelStrategy(),
      ]);
      final patch = hotfix.PatchModel(
        id: 'combo1',
        type: hotfix.PatchType.jsScript,
        version: '1.0.0',
        channel: 'beta',
        entry: '',
        downloadUrl: '',
        signature: '',
      );
      expect(strategy.isHit(patch, userId: 'user1', appVersion: '1.0.0', channels: ['beta']), isTrue);
      expect(strategy.isHit(patch, userId: 'user1', appVersion: '1.0.1', channels: ['beta']), isFalse);
    });
  });
} 