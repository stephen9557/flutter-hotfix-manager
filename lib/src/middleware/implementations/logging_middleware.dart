import '../simple_middleware.dart';
import '../../utils/logger.dart';
import '../../status/patch_status.dart';

/// 日志中间件实现
class LoggingSimpleMiddleware implements SimplePatchMiddleware {
  @override
  String get name => 'LoggingSimpleMiddleware';

  @override
  String get description => '记录补丁执行过程的日志中间件';

  @override
  bool get enabled => true;

  @override
  int get priority => 10;

  @override
  Future<void> before(PatchModel patch) async {
    final timestamp = DateTime.now();
    hotfixLogger.patchInfo(patch.id, '开始执行补丁', '类型: ${patch.type}, 版本: ${patch.version}');
  }

  @override
  Future<void> after(PatchModel patch, PatchStatus status) async {
    final timestamp = DateTime.now();
    final patchId = patch.id;
    
    if (status.applied) {
      hotfixLogger.patchInfo(patchId, '补丁执行完成', '状态: 成功');
    } else {
      hotfixLogger.error('补丁执行失败: $patchId', status.error != null ? Exception(status.error) : null);
    }
  }
} 