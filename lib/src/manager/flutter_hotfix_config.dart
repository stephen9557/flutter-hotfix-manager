/// 热修复SDK配置项，集中管理所有初始化参数
class FlutterHotfixConfig {
  /// 服务端补丁元数据接口地址
  final String serverUrl;
  /// 当前App版本号
  final String appVersion;
  /// 当前用户唯一标识
  final String userId;
  /// 可选：渠道列表
  final List<String>? channels;
  /// 可选：地域信息
  final String? region;
  /// 可选：自定义策略
  final dynamic strategy;
  /// 可选：自定义补丁执行器
  final dynamic executor;
  /// 可选：自定义网络客户端
  final dynamic networkClient;
  /// 可选：自定义状态上报器
  final dynamic statusReporter;
  /// 补丁缓存目录
  final String cacheDir;
  /// 可选：补丁状态文件路径
  final String? patchStatusFile;

  /// 构造函数，传入所有配置参数
  FlutterHotfixConfig({
    required this.serverUrl,
    required this.appVersion,
    required this.userId,
    this.channels,
    this.region,
    this.strategy,
    this.executor,
    this.networkClient,
    this.statusReporter,
    this.cacheDir = '/tmp/flutter_hotfix_cache',
    this.patchStatusFile,
  });
} 