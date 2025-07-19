import 'patch_executor.dart';
import '../middleware/simple_middleware.dart';
import '../status/patch_status.dart';

/// 批量补丁执行器抽象基类
abstract class BatchPatchExecutor {
  /// 构造函数，传入补丁执行器
  BatchPatchExecutor({PatchExecutor? executor}) : executor = executor ?? DefaultPatchExecutor();
  /// 实际补丁执行器
  final PatchExecutor executor;
  /// 批量执行补丁，需子类实现
  Future<List<PatchStatus>> executeBatch(List<PatchModel> patches);
}

/// 带中间件的批量补丁执行器，支持优先级排序和钩子
class BatchPatchExecutorWithMiddleware extends BatchPatchExecutor {
  /// 构造函数，传入补丁执行器和中间件列表
  BatchPatchExecutorWithMiddleware({super.executor, required this.middlewares});
  /// 中间件列表
  final List<SimplePatchMiddleware> middlewares;

  @override
  Future<List<PatchStatus>> executeBatch(List<PatchModel> patches) async {
    // 按优先级排序
    patches.sort((PatchModel a, PatchModel b) {
      final int pa = (a.extra?['priority'] ?? 100) as int;
      final int pb = (b.extra?['priority'] ?? 100) as int;
      return pa.compareTo(pb);
    });
    
    // 并发执行，带中间件钩子
    return Future.wait(patches.map((PatchModel p) async {
      // 执行 before 钩子
      await SimpleMiddlewareManager.executeBefore(p);
      
      // 执行补丁
      final status = await executor.execute(p);
      
      // 执行 after 钩子
      await SimpleMiddlewareManager.executeAfter(p, status);
      
      return status;
    }));
  }
}

