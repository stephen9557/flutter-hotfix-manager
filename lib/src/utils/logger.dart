import 'package:flutter/foundation.dart';
import 'dart:io';

/// 日志级别枚举
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
}

/// 日志输出器接口
abstract class LogOutput {
  void log(LogLevel level, String message, [Object? error, StackTrace? stackTrace]);
}

/// 控制台日志输出器
class ConsoleLogOutput implements LogOutput {
  @override
  void log(LogLevel level, String message, [Object? error, StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = _getLevelString(level);
    final prefix = '[$timestamp] [$levelStr]';
    
    if (error != null) {
      debugPrint('$prefix $message: $error');
      if (stackTrace != null) {
        debugPrint('$prefix Stack trace: $stackTrace');
      }
    } else {
      debugPrint('$prefix $message');
    }
  }
  
  String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return 'VERBOSE';
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }
}

/// 文件日志输出器
class FileLogOutput implements LogOutput {
  final String filePath;
  final bool appendMode;
  final int maxFileSize; // 最大文件大小（字节）
  final int maxBackupFiles; // 最大备份文件数量
  
  FileLogOutput(
    this.filePath, {
    this.appendMode = true,
    this.maxFileSize = 10 * 1024 * 1024, // 默认10MB
    this.maxBackupFiles = 5,
  });

  @override
  void log(LogLevel level, String message, [Object? error, StackTrace? stackTrace]) {
    // 使用 Future.microtask 来异步执行文件操作，避免阻塞
    Future.microtask(() async {
      try {
        final file = File(filePath);
        final timestamp = DateTime.now().toIso8601String();
        final levelStr = _getLevelString(level);
        
        // 构建日志内容
        final logContent = _buildLogContent(timestamp, levelStr, message, error, stackTrace);
        
        // 检查文件大小，如果超过限制则轮转
        await _rotateLogFileIfNeeded(file);
        
        // 写入日志
        if (appendMode) {
          await file.writeAsString(logContent, mode: FileMode.append);
        } else {
          await file.writeAsString(logContent);
        }
      } catch (e) {
        // 如果文件写入失败，回退到控制台输出
        debugPrint('[FileLogOutput] Failed to write to file $filePath: $e');
        debugPrint('[FileLogOutput] Original message: $message');
      }
    });
  }

  /// 构建日志内容
  String _buildLogContent(String timestamp, String levelStr, String message, [Object? error, StackTrace? stackTrace]) {
    final buffer = StringBuffer();
    buffer.writeln('[$timestamp] [$levelStr] $message');
    
    if (error != null) {
      buffer.writeln('[$timestamp] [$levelStr] Error: $error');
    }
    
    if (stackTrace != null) {
      buffer.writeln('[$timestamp] [$levelStr] Stack trace: $stackTrace');
    }
    
    return buffer.toString();
  }

  /// 获取级别字符串
  String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return 'VERBOSE';
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }

  /// 检查并轮转日志文件
  Future<void> _rotateLogFileIfNeeded(File file) async {
    if (!await file.exists()) {
      return;
    }

    final fileSize = await file.length();
    if (fileSize < maxFileSize) {
      return;
    }

    // 轮转日志文件
    await _rotateLogFile(file);
  }

  /// 轮转日志文件
  Future<void> _rotateLogFile(File file) async {
    try {
      // 删除最旧的备份文件
      for (int i = maxBackupFiles - 1; i >= 0; i--) {
        final backupFile = File('$filePath.$i');
        if (await backupFile.exists()) {
          if (i == maxBackupFiles - 1) {
            // 删除最旧的备份
            await backupFile.delete();
          } else {
            // 重命名备份文件
            final nextBackupFile = File('$filePath.${i + 1}');
            await backupFile.rename(nextBackupFile.path);
          }
        }
      }

      // 重命名当前日志文件为 .0
      final backupFile = File('$filePath.0');
      await file.rename(backupFile.path);

      // 创建新的日志文件
      await file.create();
    } catch (e) {
      debugPrint('[FileLogOutput] Failed to rotate log file: $e');
    }
  }

  /// 清理旧的日志文件
  Future<void> cleanOldLogs() async {
    try {
      for (int i = 0; i < maxBackupFiles; i++) {
        final backupFile = File('$filePath.$i');
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
      }
    } catch (e) {
      debugPrint('[FileLogOutput] Failed to clean old logs: $e');
    }
  }

  /// 获取日志文件大小
  Future<int> getFileSize() async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      debugPrint('[FileLogOutput] Failed to get file size: $e');
      return 0;
    }
  }

  /// 获取日志文件信息
  Future<Map<String, dynamic>> getFileInfo() async {
    try {
      final file = File(filePath);
      final exists = await file.exists();
      
      if (!exists) {
        return {
          'exists': false,
          'size': 0,
          'lastModified': null,
        };
      }

      final stat = await file.stat();
      return {
        'exists': true,
        'size': stat.size,
        'lastModified': stat.modified,
        'path': filePath,
      };
    } catch (e) {
      debugPrint('[FileLogOutput] Failed to get file info: $e');
      return {
        'exists': false,
        'error': e.toString(),
      };
    }
  }
}

/// 热修复管理器日志类
class HotfixLogger {
  static final HotfixLogger _instance = HotfixLogger._internal();
  factory HotfixLogger() => _instance;
  HotfixLogger._internal();

  /// 日志级别，低于此级别的日志不会输出
  LogLevel _minLevel = LogLevel.info;
  
  /// 日志输出器列表
  final List<LogOutput> _outputs = <LogOutput>[];
  
  /// 是否启用日志
  bool _enabled = true;
  
  /// 模块名称
  String _moduleName = 'FlutterHotfixManager';

  /// 设置日志级别
  void setLogLevel(LogLevel level) {
    _minLevel = level;
  }

  /// 启用/禁用日志
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// 设置模块名称
  void setModuleName(String name) {
    _moduleName = name;
  }

  /// 添加日志输出器
  void addOutput(LogOutput output) {
    _outputs.add(output);
  }

  /// 移除日志输出器
  void removeOutput(LogOutput output) {
    _outputs.remove(output);
  }

  /// 清空所有输出器
  void clearOutputs() {
    _outputs.clear();
  }

  /// 初始化默认配置
  void initialize() {
    if (_outputs.isEmpty) {
      _outputs.add(ConsoleLogOutput());
    }
  }

  /// 输出详细日志
  void verbose(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.verbose, message, error, stackTrace);
  }

  /// 输出调试日志
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  /// 输出信息日志
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  /// 输出警告日志
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  /// 输出错误日志
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  /// 内部日志输出方法
  void _log(LogLevel level, String message, [Object? error, StackTrace? stackTrace]) {
    if (!_enabled || level.index < _minLevel.index) {
      return;
    }

    final formattedMessage = '[$_moduleName] $message';
    
    for (final output in _outputs) {
      try {
        output.log(level, formattedMessage, error, stackTrace);
      } catch (e) {
        // 防止日志输出器本身出错导致循环
        debugPrint('Logger output error: $e');
      }
    }
  }

  /// 输出补丁相关日志
  void patchInfo(String patchId, String action, [String? details]) {
    final message = details != null 
        ? '补丁 $action: $patchId - $details'
        : '补丁 $action: $patchId';
    info(message);
  }

  /// 输出中间件相关日志
  void middlewareInfo(String middlewareName, String action, [String? details]) {
    final message = details != null 
        ? '中间件 $action: $middlewareName - $details'
        : '中间件 $action: $middlewareName';
    info(message);
  }

  /// 输出网络相关日志
  void networkInfo(String url, String action, [String? details]) {
    final message = details != null 
        ? '网络 $action: $url - $details'
        : '网络 $action: $url';
    info(message);
  }

  /// 输出缓存相关日志
  void cacheInfo(String action, [String? details]) {
    final message = details != null 
        ? '缓存 $action - $details'
        : '缓存 $action';
    info(message);
  }
}

final hotfixLogger = HotfixLogger(); 