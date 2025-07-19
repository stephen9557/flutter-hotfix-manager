import '../core/middleware_interface.dart';
import '../management/middleware_registry.dart';
import '../../status/patch_status.dart';

/// 中间件执行器，负责按顺序执行中间件
class MiddlewareExecutor {
  final MiddlewareRegistry _registry;
  final void Function(String, Object, StackTrace)? _onError;

  MiddlewareExecutor(this._registry, {void Function(String, Object, StackTrace)? onError})
      : _onError = onError;

  /// 执行所有 before 钩子
  Future<List<MiddlewareResult>> executeBefore(PatchModel patch) async {
    return await _executeMiddlewares(patch, null, isBefore: true);
  }

  /// 执行所有 after 钩子
  Future<List<MiddlewareResult>> executeAfter(PatchModel patch, PatchStatus status) async {
    return await _executeMiddlewares(patch, status, isBefore: false);
  }

  /// 执行中间件核心逻辑
  Future<List<MiddlewareResult>> _executeMiddlewares(
    PatchModel patch,
    PatchStatus? status, {
    required bool isBefore,
  }) async {
    final results = <MiddlewareResult>[];
    
    // 按类型顺序执行：system -> security -> business -> custom
    final executionOrder = [
      MiddlewareType.system,
      MiddlewareType.security,
      MiddlewareType.business,
      MiddlewareType.custom,
    ];

    for (final type in executionOrder) {
      final middlewares = _registry.getMiddlewares(type);
      if (middlewares.isEmpty) continue;

      final typeResults = await _executeMiddlewareGroup(
        middlewares,
        patch,
        status,
        isBefore: isBefore,
      );
      
      results.addAll(typeResults);
      
      // 检查是否需要中断执行
      if (_shouldStopExecution(typeResults)) {
        break;
      }
    }
    
    return results;
  }

  /// 执行一组中间件
  Future<List<MiddlewareResult>> _executeMiddlewareGroup(
    List<PatchMiddleware> middlewares,
    PatchModel patch,
    PatchStatus? status, {
    required bool isBefore,
  }) async {
    final results = <MiddlewareResult>[];

    for (final middleware in middlewares) {
      try {
        final context = MiddlewareContext(patch: patch, status: status);
        
        final result = isBefore 
            ? await middleware.before(context)
            : await middleware.after(context);
            
        results.add(result);
        
        // 如果中间件要求停止执行，则中断
        if (!result.shouldContinue) {
          break;
        }
      } catch (e, stack) {
        final result = MiddlewareResult.error('Middleware execution failed: $e');
        results.add(result);
        _onError?.call(isBefore ? 'before' : 'after', e, stack);
        
        // 错误时停止执行
        break;
      }
    }

    return results;
  }

  /// 判断是否应该停止执行
  bool _shouldStopExecution(List<MiddlewareResult> results) {
    return results.any((r) => !r.shouldContinue);
  }

  /// 获取执行统计信息
  Map<String, dynamic> getExecutionStats(List<MiddlewareResult> results) {
    final total = results.length;
    final successful = results.where((r) => r.success).length;
    final failed = total - successful;
    final stopped = results.where((r) => !r.shouldContinue).length;

    return {
      'total': total,
      'successful': successful,
      'failed': failed,
      'stopped': stopped,
      'successRate': total > 0 ? (successful / total * 100).toStringAsFixed(2) + '%' : '0%',
    };
  }
} 