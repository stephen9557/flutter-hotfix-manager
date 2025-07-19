import 'package:flutter_hotfix_manager/src/manager/patch_cache_manager.dart';
import 'package:flutter_hotfix_manager/src/middleware/middleware_manager.dart';
import 'package:flutter_hotfix_manager/src/middleware/core/middleware_interface.dart';
import 'package:flutter_hotfix_manager/src/middleware/simple_middleware.dart';
import 'package:flutter_hotfix_manager/src/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'flutter_hotfix_config.dart';
import '../status/patch_status_manager.dart';
import '../status/patch_status.dart';
import '../status/patch_status_reporter.dart';
import '../network/patch_meta_fetcher.dart';
import '../execute/patch_executor.dart';
import '../execute/batch_with_middleware.dart';
import '../strategy/patch_strategy.dart';
import '../strategy/version_channel_region.dart';

/// FlutterHotfixManager SDK 单例，对外统一接口
class FlutterHotfixManager {
  /// 获取单例实例
  static final FlutterHotfixManager _instance = FlutterHotfixManager._internal();
  
  /// 构造函数
  factory FlutterHotfixManager() => _instance;
  FlutterHotfixManager._internal();

  late FlutterHotfixConfig _config;
  late PatchMetaFetcher _metaFetcher;
  late PatchCacheManager _cacheManager;
  PatchStrategy? _strategy;
  PatchExecutor? _executor;
  PatchNetworkClient? _networkClient;
  PatchStatusReporter? _statusReporter;
  late PatchStatusManager _statusManager;

  /// 初始化SDK，建议在main()前调用
  /// [config] 配置对象，包含服务端地址、版本、用户等信息
  static Future<void> init(FlutterHotfixConfig config) async {
    final FlutterHotfixManager mgr = FlutterHotfixManager._instance;
    
    // 初始化日志系统
    hotfixLogger.initialize();
    hotfixLogger.setModuleName('FlutterHotfixManager');
    
    mgr._config = config;
    mgr._networkClient = config.networkClient ?? DefaultPatchNetworkClient();
    mgr._metaFetcher = PatchMetaFetcher(config.serverUrl, mgr._networkClient!);
    mgr._cacheManager = PatchCacheManager(config.cacheDir);
    mgr._strategy = config.strategy ?? CompositePatchStrategy([
      VersionStrategy(),
      ChannelStrategy(),
      RegionStrategy(),
    ]);
    mgr._executor = config.executor ?? DefaultPatchExecutor();
    mgr._statusReporter = config.statusReporter;
    mgr._statusManager = PatchStatusManager(config.patchStatusFile ?? '${config.cacheDir}/applied_patches.json');
    
    await mgr._statusManager.restoreAppliedPatches();
    hotfixLogger.info('SDK 初始化完成');
  }

  /// 注册中间件（全局）
  /// [middleware] 需实现 PatchMiddleware 接口
  static void useMiddleware(PatchMiddleware middleware) {
    GlobalMiddlewareManager.register(middleware);
    hotfixLogger.middlewareInfo(middleware.name, '注册');
  }

  /// 注册补丁状态上报器（全局）
  /// [reporter] 需实现 PatchStatusReporter 接口
  static void setStatusReporter(PatchStatusReporter reporter) {
    FlutterHotfixManager._instance._statusReporter = reporter;
    hotfixLogger.info('状态上报器已设置');
  }

  /// 拉取并应用所有符合策略的补丁
  /// 包含补丁元数据拉取、策略过滤、批量执行、状态持久化与上报
  static Future<void> checkAndApply() async {
    final FlutterHotfixManager mgr = FlutterHotfixManager._instance;
    try {
      hotfixLogger.info('开始检查并应用补丁');
      
      // 1. 拉取补丁元数据
      final List<PatchModel> metaList = await mgr._fetchPatchMetaList();
      if (metaList.isEmpty) {
        hotfixLogger.info('没有可用的补丁');
        return;
      }
      hotfixLogger.info('拉取到 ${metaList.length} 个补丁元数据');

      // 2. 策略过滤
      final List<PatchModel> filtered = mgr._filterPatches(metaList);
      if (filtered.isEmpty) {
        hotfixLogger.info('没有命中策略的补丁');
        return;
      }
      hotfixLogger.info('策略过滤后剩余 ${filtered.length} 个补丁');

      // 3. 批量执行
      final List<PatchStatus> results = await mgr._executeBatch(filtered);

      // 4. 状态持久化
      mgr._statusManager.updateAppliedPatches(results);
      await mgr._statusManager.persistAppliedPatches();
      hotfixLogger.info('补丁状态已持久化');

      // 5. 状态上报
      await mgr._reportPatchStatus(results);

      hotfixLogger.info('补丁应用完成，共处理 ${results.length} 个补丁');
    } catch (e, stack) {
      hotfixLogger.error('checkAndApply 执行失败', e, stack);
      rethrow;
    }
  }

  /// 手动清理指定补丁缓存（用于回滚）
  static Future<void> clearPatch(String patchId) async {
    final FlutterHotfixManager mgr = FlutterHotfixManager._instance;
    try {
      hotfixLogger.patchInfo(patchId, '开始清理');
      
      // 1. 查找补丁状态
      final PatchStatus? patchStatus = mgr._findAppliedPatch(patchId);
      if (patchStatus == null) {
        hotfixLogger.warning('补丁不存在: $patchId');
        return;
      }

      // 2. 构造补丁模型用于回滚
      final PatchModel patch = mgr._constructPatchModelForRollback(patchStatus);

      // 3. 执行回滚
      await mgr._rollbackPatch(patch);

      // 4. 清理缓存
      await mgr._cacheManager.clearPatch(patchId, patchStatus.type);
      hotfixLogger.cacheInfo('清理补丁缓存', 'patchId: $patchId');

      // 5. 更新状态
      mgr._statusManager.removeAppliedPatch(patchId, patchStatus.type);
        await mgr._statusManager.persistAppliedPatches();

      hotfixLogger.patchInfo(patchId, '回滚完成');
    } catch (e, stack) {
      hotfixLogger.error('clearPatch 执行失败', e, stack);
      rethrow;
    }
  }

  /// 查询当前已应用的补丁列表及状态
  static Future<List<PatchStatus>> getAppliedPatches() async {
    final FlutterHotfixManager mgr = FlutterHotfixManager._instance;
    final patches = mgr._statusManager.appliedPatches;
    hotfixLogger.info('查询已应用补丁，共 ${patches.length} 个');
    return patches;
  }

  // ===================== 私有方法分组 =====================

  /// 拉取补丁元数据列表
  Future<List<PatchModel>> _fetchPatchMetaList() async {
    hotfixLogger.networkInfo(_config.serverUrl, '拉取补丁元数据');
    return await _metaFetcher.fetchMeta();
  }

  /// 根据策略过滤补丁列表
  List<PatchModel> _filterPatches(List<PatchModel> metaList) {
    return metaList.where((PatchModel patch) =>
      _strategy!.isHit(
        patch,
        userId: _config.userId,
        appVersion: _config.appVersion,
        channels: _config.channels,
        region: _config.region,
      )).toList();
  }

  /// 批量执行补丁，支持优先级排序和中间件
  Future<List<PatchStatus>> _executeBatch(List<PatchModel> filtered) async {
    final BatchPatchExecutorWithMiddleware batchExecutor = BatchPatchExecutorWithMiddleware(
      executor: _executor,
      middlewares: <SimplePatchMiddleware>[], // 暂时使用空列表，避免类型冲突
    );
    return await batchExecutor.executeBatch(filtered);
  }

  /// 上报补丁应用状态
  Future<void> _reportPatchStatus(List<PatchStatus> results) async {
    if (_statusReporter != null) {
      hotfixLogger.info('开始上报补丁状态，共 ${results.length} 个');
      for (final PatchStatus status in results) {
        try {
          await _statusReporter!.report(status);
          hotfixLogger.patchInfo(status.patchId, '状态上报成功');
        } catch (e, stack) {
          hotfixLogger.error('补丁状态上报失败: ${status.patchId}', e, stack);
        }
      }
    } else {
      hotfixLogger.debug('未设置状态上报器，跳过上报');
    }
  }

  /// 查找已应用的补丁状态
  PatchStatus? _findAppliedPatch(String patchId) {
    // 遍历所有已应用的补丁，查找匹配的ID
    for (final PatchStatus status in _statusManager.appliedPatches) {
      if (status.patchId == patchId) {
        return status;
      }
    }
    return null;
  }

  /// 构造回滚用的 PatchModel（如无完整信息则占位）
  PatchModel _constructPatchModelForRollback(PatchStatus patchStatus) {
    return PatchModel(
      id: patchStatus.patchId,
      type: patchStatus.type,
      version: '',
      entry: '',
      downloadUrl: '',
      signature: '',
    );
  }

  /// 执行补丁回滚
  Future<void> _rollbackPatch(PatchModel patch) async {
    try {
      hotfixLogger.patchInfo(patch.id, '开始回滚');
      await _executor?.rollback(patch);
      hotfixLogger.patchInfo(patch.id, '回滚执行完成');
    } catch (e, stack) {
      hotfixLogger.error('补丁回滚失败: ${patch.id}', e, stack);
      rethrow;
    }
  }
}