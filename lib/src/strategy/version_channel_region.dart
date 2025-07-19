import 'patch_strategy.dart';
import '../status/patch_status.dart';

/// 版本号命中策略，完全匹配版本
class VersionStrategy implements PatchStrategy {
  @override
  bool isHit(PatchModel patch, {
    required String userId,
    required String appVersion,
    List<String>? channels,
    String? region,
    Map<String, dynamic>? customContext,
  }) {
    return patch.version == appVersion;
  }
}

/// 渠道命中策略，channels 包含 patch.channel 即命中
class ChannelStrategy implements PatchStrategy {
  @override
  bool isHit(PatchModel patch, {
    required String userId,
    required String appVersion,
    List<String>? channels,
    String? region,
    Map<String, dynamic>? customContext,
  }) {
    if (patch.channel == null || channels == null) return true;
    return channels.contains(patch.channel);
  }
}

/// 地域命中策略，region 完全匹配
class RegionStrategy implements PatchStrategy {
  @override
  bool isHit(PatchModel patch, {
    required String userId,
    required String appVersion,
    List<String>? channels,
    String? region,
    Map<String, dynamic>? customContext,
  }) {
    if (patch.region == null || region == null) {
      return true;
    }
    return patch.region == region;
  }
}

/// 组合策略，所有子策略均命中才算命中
class CompositePatchStrategy implements PatchStrategy {

  /// 构造函数，传入所有子策略
  CompositePatchStrategy(this.strategies);
  /// 策略列表
  final List<PatchStrategy> strategies;

  @override
  bool isHit(PatchModel patch, {
    required String userId,
    required String appVersion,
    List<String>? channels,
    String? region,
    Map<String, dynamic>? customContext,
  }) {
    for (final PatchStrategy strategy in strategies) {
      if (!strategy.isHit(
        patch,
        userId: userId,
        appVersion: appVersion,
        channels: channels,
        region: region,
        customContext: customContext,
      )) {
        return false;
      }
    }
    return true;
  }
} 