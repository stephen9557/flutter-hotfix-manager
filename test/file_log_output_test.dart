import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hotfix_manager/flutter_hotfix_manager.dart' as hotfix;
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileLogOutput', () {
    const testLogFile = 'test_logs.txt';
    
    setUp(() {
      // 清理测试文件
      final file = File(testLogFile);
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    tearDown(() {
      // 清理测试文件和备份文件
      for (int i = 0; i < 5; i++) {
        final backupFile = File('$testLogFile.$i');
        if (backupFile.existsSync()) {
          backupFile.deleteSync();
        }
      }
      final file = File(testLogFile);
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    test('FileLogOutput basic logging', () async {
      final fileOutput = hotfix.FileLogOutput(testLogFile);
      
      // 写入日志
      fileOutput.log(hotfix.LogLevel.info, 'Test message');
      await Future.delayed(Duration(milliseconds: 100));
      fileOutput.log(hotfix.LogLevel.error, 'Test error', Exception('Test exception'));
      await Future.delayed(Duration(milliseconds: 100));
      
      // 验证文件存在
      final file = File(testLogFile);
      expect(await file.exists(), isTrue);
      
      // 验证文件内容
      final content = await file.readAsString();
      expect(content, contains('Test message'));
      expect(content, contains('Test error'));
      expect(content, contains('Exception: Test exception'));
    });

    test('FileLogOutput append mode', () async {
      final fileOutput = hotfix.FileLogOutput(testLogFile, appendMode: true);
      
      // 写入多条日志
      fileOutput.log(hotfix.LogLevel.info, 'First message');
      await Future.delayed(Duration(milliseconds: 100));
      fileOutput.log(hotfix.LogLevel.info, 'Second message');
      await Future.delayed(Duration(milliseconds: 100));
      
      // 验证文件内容包含所有消息
      final file = File(testLogFile);
      final content = await file.readAsString();
      expect(content, contains('First message'));
      expect(content, contains('Second message'));
      
      // 验证消息数量（每行一个日志条目）
      final lines = content.split('\n').where((line) => line.contains('[') && line.contains(']')).length;
      expect(lines, equals(2));
    });

    test('FileLogOutput overwrite mode', () async {
      final fileOutput = hotfix.FileLogOutput(testLogFile, appendMode: false);
      
      // 写入第一条日志
      fileOutput.log(hotfix.LogLevel.info, 'First message');
      await Future.delayed(Duration(milliseconds: 100));
      
      // 写入第二条日志（应该覆盖第一条）
      fileOutput.log(hotfix.LogLevel.info, 'Second message');
      await Future.delayed(Duration(milliseconds: 100));
      
      // 验证文件内容只包含第二条消息
      final file = File(testLogFile);
      final content = await file.readAsString();
      expect(content, contains('Second message'));
      expect(content, isNot(contains('First message')));
    });

    test('FileLogOutput error handling', () async {
      // 使用一个无效的路径来测试错误处理
      final fileOutput = hotfix.FileLogOutput('/invalid/path/test.log');
      
      // 这应该不会抛出异常，而是回退到控制台输出
      expect(() {
        fileOutput.log(hotfix.LogLevel.info, 'Test message');
      }, returnsNormally);
    });

    test('FileLogOutput file info', () async {
      final fileOutput = hotfix.FileLogOutput(testLogFile);
      
      // 写入一些日志
      fileOutput.log(hotfix.LogLevel.info, 'Test message');
      
      // 等待异步操作完成
      await Future.delayed(Duration(milliseconds: 200));
      
      // 获取文件信息
      final fileInfo = await fileOutput.getFileInfo();
      
      expect(fileInfo['exists'], isTrue);
      expect(fileInfo['size'], greaterThan(0));
      expect(fileInfo['path'], equals(testLogFile));
      expect(fileInfo['lastModified'], isNotNull);
    });

    test('FileLogOutput file size', () async {
      final fileOutput = hotfix.FileLogOutput(testLogFile);
      
      // 初始文件大小应该为0
      expect(await fileOutput.getFileSize(), equals(0));
      
      // 写入日志后文件大小应该大于0
      fileOutput.log(hotfix.LogLevel.info, 'Test message');
      await Future.delayed(Duration(milliseconds: 200));
      expect(await fileOutput.getFileSize(), greaterThan(0));
    });

    test('FileLogOutput with hotfixLogger integration', () async {
      // 创建文件输出器
      final fileOutput = hotfix.FileLogOutput(testLogFile);
      
      // 添加到日志系统
      hotfix.hotfixLogger.addOutput(fileOutput);
      
      // 输出一些日志
      hotfix.hotfixLogger.info('Integration test message');
      await Future.delayed(Duration(milliseconds: 100));
      hotfix.hotfixLogger.error('Integration test error', Exception('Test exception'));
      await Future.delayed(Duration(milliseconds: 100));
      
      // 验证文件内容
      final file = File(testLogFile);
      expect(await file.exists(), isTrue);
      
      final content = await file.readAsString();
      expect(content, contains('Integration test message'));
      expect(content, contains('Integration test error'));
      expect(content, contains('Exception: Test exception'));
      
      // 清理
      hotfix.hotfixLogger.removeOutput(fileOutput);
    });
  });
} 