import '../core/middleware_interface.dart';

/// 中间件注册表，负责管理中间件的注册、分类和排序
class MiddlewareRegistry {
  /// 按类型分组的中间件
  final Map<MiddlewareType, List<PatchMiddleware>> _middlewares = {};
  
  /// 错误处理回调
  final void Function(String, Object, StackTrace)? _onError;
  
  /// 是否在错误时继续执行其他中间件
  final bool _continueOnError;

  MiddlewareRegistry({
    void Function(String, Object, StackTrace)? onError,
    bool continueOnError = true,
  }) : _onError = onError, _continueOnError = continueOnError {
    // 初始化所有类型的列表
    for (final type in MiddlewareType.values) {
      _middlewares[type] = [];
    }
  }

  /// 注册中间件
  void register(PatchMiddleware middleware) {
    if (!middleware.enabled) return;
    
    _middlewares[middleware.type]!.add(middleware);
    
    // 按优先级排序
    _middlewares[middleware.type]!.sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// 批量注册中间件
  void registerAll(List<PatchMiddleware> middlewares) {
    for (final middleware in middlewares) {
      register(middleware);
    }
  }

  /// 取消注册中间件
  void unregister(PatchMiddleware middleware) {
    _middlewares[middleware.type]?.remove(middleware);
  }

  /// 清空指定类型的中间件
  void clear([MiddlewareType? type]) {
    if (type != null) {
      _middlewares[type]?.clear();
    } else {
      for (final type in MiddlewareType.values) {
        _middlewares[type]?.clear();
      }
    }
  }

  /// 获取指定类型的中间件
  List<PatchMiddleware> getMiddlewares(MiddlewareType type) {
    return List.unmodifiable(_middlewares[type] ?? []);
  }

  /// 获取所有中间件
  Map<MiddlewareType, List<PatchMiddleware>> get allMiddlewares {
    final result = <MiddlewareType, List<PatchMiddleware>>{};
    for (final entry in _middlewares.entries) {
      result[entry.key] = List.unmodifiable(entry.value);
    }
    return result;
  }

  /// 获取中间件总数
  int get totalCount {
    return _middlewares.values.fold(0, (sum, list) => sum + list.length);
  }

  /// 检查是否为空
  bool get isEmpty => totalCount == 0;

  /// 检查是否不为空
  bool get isNotEmpty => totalCount > 0;

  /// 获取指定类型的中间件数量
  int getCount(MiddlewareType type) {
    return _middlewares[type]?.length ?? 0;
  }

  /// 检查是否包含指定中间件
  bool contains(PatchMiddleware middleware) {
    return _middlewares[middleware.type]?.contains(middleware) ?? false;
  }

  /// 获取中间件信息
  Map<String, dynamic> getMiddlewareInfo() {
    final info = <String, dynamic>{};
    for (final entry in _middlewares.entries) {
      info[entry.key.name] = {
        'count': entry.value.length,
        'middlewares': entry.value.map((m) => {
          'name': m.name,
          'description': m.description,
          'priority': m.priority,
          'enabled': m.enabled,
        }).toList(),
      };
    }
    return info;
  }
} 