// 主SDK导出文件
library flutter_hotfix_manager;

// 核心管理器
export 'src/manager/flutter_hotfix_manager.dart';
export 'src/manager/flutter_hotfix_config.dart';
export 'src/manager/patch_cache_manager.dart';

// 状态管理
export 'src/status/patch_status.dart';
export 'src/status/patch_status_manager.dart';
export 'src/status/patch_status_reporter.dart';

// 网络相关
export 'src/network/patch_meta_fetcher.dart';
export 'src/network/patch_updater.dart';

// 执行器
export 'src/execute/patch_executor.dart';
export 'src/execute/batch_with_middleware.dart';
export 'src/execute/script_patch_loader.dart';
export 'src/execute/dart_patch_loader.dart';

// 策略
export 'src/strategy/patch_strategy.dart';
export 'src/strategy/version_channel_region.dart';

// 中间件系统
export 'src/middleware/simple_middleware.dart';
export 'src/middleware/middleware_manager.dart';
export 'src/middleware/core/middleware_interface.dart';
export 'src/middleware/base/base_middleware.dart';
export 'src/middleware/management/middleware_registry.dart';
export 'src/middleware/management/middleware_executor.dart';

// 安全中间件
export 'src/middleware/implementations/security_middleware.dart';

// 工具类
export 'src/utils/logger.dart';

