import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hotfix_manager/flutter_hotfix_manager.dart' as hotfix;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HotfixLogger', () {
    test('logger initialization', () {
      hotfix.hotfixLogger.initialize();
      hotfix.hotfixLogger.setLogLevel(hotfix.LogLevel.info);
      hotfix.hotfixLogger.setModuleName('TestModule');
      
      expect(hotfix.hotfixLogger, isNotNull);
    });

    test('logger level filtering', () {
      hotfix.hotfixLogger.setLogLevel(hotfix.LogLevel.warning);
      
      // 这些日志应该被过滤掉
      hotfix.hotfixLogger.verbose('This should not appear');
      hotfix.hotfixLogger.debug('This should not appear');
      hotfix.hotfixLogger.info('This should not appear');
      
      // 这些日志应该出现
      hotfix.hotfixLogger.warning('This should appear');
      hotfix.hotfixLogger.error('This should appear');
    });

    test('logger enable/disable', () {
      hotfix.hotfixLogger.setEnabled(false);
      hotfix.hotfixLogger.info('This should not appear');
      
      hotfix.hotfixLogger.setEnabled(true);
      hotfix.hotfixLogger.info('This should appear');
    });

    test('specialized logging methods', () {
      hotfix.hotfixLogger.patchInfo('test-patch-1', '开始执行', '类型: jsScript');
      hotfix.hotfixLogger.middlewareInfo('TestMiddleware', '注册', '优先级: 100');
      hotfix.hotfixLogger.networkInfo('https://example.com', '下载补丁', '大小: 1KB');
      hotfix.hotfixLogger.cacheInfo('清理缓存', 'patchId: test-1');
    });

    test('logger with error and stack trace', () {
      try {
        throw Exception('Test error');
      } catch (e, stack) {
        hotfix.hotfixLogger.error('Test error logging', e, stack);
      }
    });
  });

  group('ConsoleLogOutput', () {
    test('console output creation', () {
      final output = hotfix.ConsoleLogOutput();
      expect(output, isNotNull);
    });

    test('console output logging', () {
      final output = hotfix.ConsoleLogOutput();
      output.log(hotfix.LogLevel.info, 'Test message');
      output.log(hotfix.LogLevel.error, 'Test error', Exception('Test exception'));
    });
  });

  group('FileLogOutput', () {
    test('file output creation', () {
      final output = hotfix.FileLogOutput('test.log');
      expect(output, isNotNull);
    });
  });
} 