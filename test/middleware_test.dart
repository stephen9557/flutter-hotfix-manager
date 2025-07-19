import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hotfix_manager/flutter_hotfix_manager.dart' as hotfix;

class TestSimpleMiddleware implements hotfix.SimplePatchMiddleware {
  bool beforeCalled = false;
  bool afterCalled = false;
  
  @override
  String get name => 'TestSimpleMiddleware';
  
  @override
  String get description => 'Test simple middleware for unit testing';
  
  @override
  bool get enabled => true;
  
  @override
  int get priority => 100;
  
  @override
  Future<void> before(hotfix.PatchModel patch) async {
    beforeCalled = true;
  }
  
  @override
  Future<void> after(hotfix.PatchModel patch, hotfix.PatchStatus status) async {
    afterCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TestSimpleMiddleware before/after hooks', () async {
    final middleware = TestSimpleMiddleware();
    final patch = hotfix.PatchModel(
      id: 'm1',
      type: hotfix.PatchType.jsScript,
      version: '1.0.0',
      entry: '',
      downloadUrl: '',
      signature: '',
    );
    final status = hotfix.PatchStatus(
      patchId: 'm1',
      type: hotfix.PatchType.jsScript,
      applied: true,
    );
    
    await middleware.before(patch);
    await middleware.after(patch, status);
    
    expect(middleware.beforeCalled, isTrue);
    expect(middleware.afterCalled, isTrue);
  });

  test('SimpleMiddlewareManager register and clear', () async {
    final middleware = TestSimpleMiddleware();
    hotfix.SimpleMiddlewareManager.register(middleware);
    expect(hotfix.SimpleMiddlewareManager.middlewares.contains(middleware), isTrue);
    hotfix.SimpleMiddlewareManager.clear();
    expect(hotfix.SimpleMiddlewareManager.isEmpty, isTrue);
  });

  test('SimpleMiddlewareManager executeBefore/executeAfter', () async {
    final middleware = TestSimpleMiddleware();
    hotfix.SimpleMiddlewareManager.register(middleware);
    
    final patch = hotfix.PatchModel(
      id: 'm2',
      type: hotfix.PatchType.jsScript,
      version: '1.0.0',
      entry: '',
      downloadUrl: '',
      signature: '',
    );
    final status = hotfix.PatchStatus(
      patchId: 'm2',
      type: hotfix.PatchType.jsScript,
      applied: true,
    );
    
    await hotfix.SimpleMiddlewareManager.executeBefore(patch);
    await hotfix.SimpleMiddlewareManager.executeAfter(patch, status);
    
    expect(middleware.beforeCalled, isTrue);
    expect(middleware.afterCalled, isTrue);
    
    hotfix.SimpleMiddlewareManager.clear();
  });

  test('SimpleMiddlewareManager registerCallback', () async {
    bool beforeCalled = false;
    bool afterCalled = false;
    
    final callbackMiddleware = hotfix.CallbackSimpleMiddleware(
      name: 'CallbackTest',
      description: 'Test callback middleware',
      onBefore: (patch) async { 
        beforeCalled = true; 
      },
      onAfter: (patch, status) async { 
        afterCalled = true; 
      },
    );
    
    hotfix.SimpleMiddlewareManager.register(callbackMiddleware);
    
    final patch = hotfix.PatchModel(
      id: 'm3',
      type: hotfix.PatchType.jsScript,
      version: '1.0.0',
      entry: '',
      downloadUrl: '',
      signature: '',
    );
    final status = hotfix.PatchStatus(
      patchId: 'm3',
      type: hotfix.PatchType.jsScript,
      applied: true,
    );
    
    await hotfix.SimpleMiddlewareManager.executeBefore(patch);
    await hotfix.SimpleMiddlewareManager.executeAfter(patch, status);
    
    expect(beforeCalled, isTrue);
    expect(afterCalled, isTrue);
    
    hotfix.SimpleMiddlewareManager.clear();
  });
} 