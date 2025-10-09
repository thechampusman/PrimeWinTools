import '../clipboard/ClipBoardManager.dart';


class AppServiceManager {
  static final AppServiceManager _instance = AppServiceManager._internal();
  factory AppServiceManager() => _instance;
  AppServiceManager._internal();

  
  ClipboardManager? _clipboardManager;

  
  bool _clipboardActive = false;

  
  ClipboardManager get clipboardManager {
    _clipboardManager ??= ClipboardManager();
    return _clipboardManager!;
  }

  
  void startClipboardMonitoring(Function onClipboardUpdate) {
    if (!_clipboardActive) {
      clipboardManager.monitorClipboard(onClipboardUpdate);
      _clipboardActive = true;
      print('📋 Clipboard monitoring started');
    } else {
      
      clipboardManager.resumeMonitoring(onClipboardUpdate);
      print('📋 Clipboard monitoring resumed');
    }
  }

  
  void stopClipboardMonitoring({bool force = false}) {
    if (force && _clipboardActive) {
      clipboardManager.stopMonitoring();
      _clipboardActive = false;
      print('📋 Clipboard monitoring stopped');
    }
  }

  
  bool get isClipboardActive => _clipboardActive;

  
  List<String> get clipboardItems => clipboardManager.copiedItems;

  
  Future<void> disposeAll() async {
    stopClipboardMonitoring(force: true);
    print('🔴 All services disposed');
  }

  
  Future<void> resumeServices(Function? clipboardCallback) async {
    if (_clipboardActive && clipboardCallback != null) {
      startClipboardMonitoring(clipboardCallback);
    }
  }
}
