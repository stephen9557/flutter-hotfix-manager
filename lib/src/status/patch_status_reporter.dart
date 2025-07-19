import 'patch_status.dart';

/// 补丁状态上报接口，业务可自定义实现
abstract class PatchStatusReporter {
  /// 上报单个补丁应用状态
  Future<void> report(PatchStatus status);
} 