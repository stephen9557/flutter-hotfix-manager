import '../status/patch_status.dart';

/// 补丁命中策略接口，支持多维度扩展
abstract class PatchStrategy {
  /// 判断补丁是否命中当前环境
  bool isHit(PatchModel patch, {
    required String userId,
    required String appVersion,
    List<String>? channels,
    String? region,
    Map<String, dynamic>? customContext,
  });
} 