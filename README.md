# Flutter Hotfix Manager

一个功能强大的 Flutter 热修复管理 SDK，支持 JavaScript 脚本和 Dart AOT 补丁的动态加载和执行。

## ✨ 特性

- 🔥 **多类型补丁支持** - JavaScript 脚本和 Dart AOT 补丁
- 🛡️ **安全策略** - 签名验证、来源检查、大小限制、过期检查
- 🔐 **权限控制** - 基于角色的访问控制
- 🔧 **中间件系统** - 插件化架构，支持自定义中间件
- 📊 **状态管理** - 补丁状态持久化和上报
- 🎯 **策略过滤** - 版本、渠道、地区多维度策略
- 📝 **日志系统** - 完整的日志记录和输出
- 🧪 **测试覆盖** - 全面的单元测试和集成测试

## 🔧 详细功能说明

### 1. 多类型补丁支持

**JavaScript 脚本补丁**
- 支持动态加载和执行 JavaScript 代码
- 实时修复前端逻辑和界面问题
- 无需重新编译和发布应用
- 支持热更新和回滚

**Dart AOT 补丁**
- 支持 Dart 代码的动态加载
- 修复业务逻辑和数据处理问题
- 保持类型安全和性能
- 支持复杂的业务场景

### 2. 安全策略系统

**签名验证**
- 验证补丁文件的数字签名
- 确保补丁来源的可信性
- 防止恶意代码注入

**来源检查**
- 验证补丁下载地址的合法性
- 支持白名单域名配置
- 防止从不可信源下载补丁

**大小限制**
- 限制补丁文件的最大大小
- 防止恶意大文件攻击
- 保护设备存储空间

**类型检查**
- 验证补丁类型的合法性
- 只允许支持的补丁类型
- 防止执行不安全的补丁

**过期检查**
- 自动检查补丁的过期时间
- 自动清理过期补丁
- 确保补丁的时效性

### 3. 权限控制系统

**基于角色的访问控制**
- 管理员权限：可以应用所有补丁
- 开发者权限：只能应用开发补丁
- 测试者权限：只能应用测试补丁
- 普通用户权限：只能应用正式补丁

**用户权限检查**
- 基于用户ID的权限验证
- 支持自定义权限规则
- 精确到单个补丁的权限控制

### 4. 中间件系统

**插件化架构**
- 支持自定义中间件开发
- 中间件可以动态注册和卸载
- 支持中间件优先级配置

**内置中间件**
- **安全中间件**：执行安全检查
- **权限中间件**：验证用户权限
- **日志中间件**：记录操作日志
- **回调中间件**：执行自定义回调

**中间件执行流程**
- 补丁执行前：before 钩子
- 补丁执行后：after 钩子
- 支持中间件链式调用
- 支持中间件异常处理

### 5. 状态管理系统

**补丁状态持久化**
- 记录补丁的加载状态
- 记录补丁的执行状态
- 记录补丁的错误信息
- 支持状态查询和统计

**状态上报机制**
- 自动上报补丁执行结果
- 支持自定义上报策略
- 支持批量状态上报
- 支持失败重试机制

### 6. 策略过滤系统

**版本策略**
- 根据应用版本过滤补丁
- 支持版本范围配置
- 支持版本比较规则

**渠道策略**
- 根据发布渠道过滤补丁
- 支持多渠道配置
- 支持渠道优先级

**地区策略**
- 根据用户地区过滤补丁
- 支持地区白名单/黑名单
- 支持地区优先级

**复合策略**
- 支持多维度策略组合
- 支持策略优先级配置
- 支持策略冲突处理

### 7. 日志系统

**多级别日志**
- DEBUG：调试信息
- INFO：一般信息
- WARN：警告信息
- ERROR：错误信息

**多输出方式**
- 控制台输出
- 文件输出
- 网络输出
- 自定义输出

**日志功能**
- 自动记录操作日志
- 支持日志级别过滤
- 支持日志格式化
- 支持日志轮转

### 8. 网络模块

**补丁元数据获取**
- 从服务器获取补丁列表
- 支持增量更新
- 支持缓存机制

**补丁下载**
- 支持断点续传
- 支持下载进度回调
- 支持下载失败重试

### 9. 缓存管理

**智能缓存策略**
- 自动缓存已下载的补丁
- 支持缓存大小限制
- 支持缓存过期清理
- 支持缓存命中率统计

### 10. 错误处理

**异常捕获**
- 捕获补丁执行异常
- 捕获网络请求异常
- 捕获权限验证异常
- 支持异常上报

**错误恢复**
- 支持补丁执行回滚
- 支持网络重连机制
- 支持降级处理策略

## 📦 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  flutter_hotfix_manager: ^0.0.1
```

然后运行：

```bash
flutter pub get
```

## 🚀 快速开始

### 1. 初始化 SDK

```dart
import 'package:flutter_hotfix_manager/flutter_hotfix_manager.dart';

void main() async {
  // 配置 SDK
  final config = FlutterHotfixConfig(
    serverUrl: 'https://your-api.com/patches',
    appVersion: '1.0.0',
    userId: 'user123',
    channels: ['beta'],
    region: 'CN',
    cacheDir: 'cache',
  );
  
  // 初始化 SDK
  await FlutterHotfixManager.init(config);
}
```

### 2. 注册中间件

```dart
// 创建安全中间件
final securityMiddleware = ConfigurableSecurityMiddleware(
  policy: CustomSecurityPolicy(),
  enabled: true,
  priority: 20,
);

// 注册中间件
SimpleMiddlewareManager.register(securityMiddleware);
```

### 3. 应用补丁

```dart
// 检查并应用补丁
await FlutterHotfixManager.checkAndApply();

// 查询已应用的补丁
final patches = await FlutterHotfixManager.getAppliedPatches();

// 清理指定补丁
await FlutterHotfixManager.clearPatch('patch_id');
```

## 🔧 自定义实现

### 安全策略

```dart
class CustomSecurityPolicy implements SecurityPolicy {
  @override
  Future<bool> verifySignature(PatchModel patch) async {
    return patch.signature.isNotEmpty && patch.signature.length >= 32;
  }
  
  @override
  Future<bool> checkSourceTrust(PatchModel patch) async {
    final trustedDomains = ['your-domain.com'];
    final uri = Uri.parse(patch.downloadUrl);
    return trustedDomains.any((domain) => uri.host.contains(domain));
  }
}
```

### 权限检查器

```dart
class CustomPermissionChecker implements PermissionChecker {
  @override
  Future<bool> checkPermission(String userId, String patchId) async {
    if (userId == 'admin') return true;
    if (userId == 'developer') return patchId.startsWith('dev_');
    return false;
  }
}
```

## 🧪 测试

```bash
# 运行所有测试
flutter test

# 运行本地测试脚本
dart test/test_simple_hotfix.dart
```

## 📁 项目结构

```
flutter_hotfix_manager/
├── lib/
│   ├── flutter_hotfix_manager.dart          # 主SDK导出
│   └── src/
│       ├── manager/                         # 核心管理器
│       ├── middleware/                      # 中间件系统
│       ├── execute/                         # 补丁执行器
│       ├── network/                         # 网络模块
│       ├── status/                          # 状态管理
│       ├── strategy/                        # 策略系统
│       └── utils/                           # 工具类
├── test/                                    # 测试文件
├── test_assets/                             # 测试资产
└── example/                                 # 使用示例
```

## 🔒 安全特性

- **签名验证** - 确保补丁来源可信
- **来源检查** - 验证下载地址的合法性
- **大小限制** - 防止恶意大文件攻击
- **类型检查** - 只允许支持的补丁类型
- **过期检查** - 自动清理过期补丁
- **权限控制** - 基于角色的访问控制

## 📊 性能优化

- **缓存机制** - 智能的补丁缓存策略
- **批量执行** - 支持多个补丁的批量处理
- **异步操作** - 非阻塞的补丁加载和执行
- **内存管理** - 高效的内存使用和垃圾回收

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 开发环境设置

1. 克隆仓库
```bash
git clone https://github.com/stephen9557/flutter-hotfix-manager.git
cd flutter_hotfix_manager
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行测试
```bash
flutter test
```

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

⭐ 如果这个项目对您有帮助，请给我们一个星标！
