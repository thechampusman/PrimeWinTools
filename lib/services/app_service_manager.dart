import '../clipboard/ClipBoardManager.dart';
import '../udrive/udrive_server.dart';

/// Singleton service manager to maintain app services across navigation
class AppServiceManager {
  static final AppServiceManager _instance = AppServiceManager._internal();
  factory AppServiceManager() => _instance;
  AppServiceManager._internal();

  // Singleton services
  ClipboardManager? _clipboardManager;
  UDriveServer? _udriveServer;

  // Service state
  bool _clipboardActive = false;
  bool _udriveActive = false;

  /// Get or create clipboard manager instance
  ClipboardManager get clipboardManager {
    _clipboardManager ??= ClipboardManager();
    return _clipboardManager!;
  }

  /// Get or create UDrive server instance
  UDriveServer get udriveServer {
    _udriveServer ??= UDriveServer();
    return _udriveServer!;
  }

  /// Start clipboard monitoring
  void startClipboardMonitoring(Function onClipboardUpdate) {
    if (!_clipboardActive) {
      clipboardManager.monitorClipboard(onClipboardUpdate);
      _clipboardActive = true;
      print('📋 Clipboard monitoring started');
    } else {
      // Resume monitoring with new callback
      clipboardManager.resumeMonitoring(onClipboardUpdate);
      print('📋 Clipboard monitoring resumed');
    }
  }

  /// Stop clipboard monitoring (only if explicitly requested)
  void stopClipboardMonitoring({bool force = false}) {
    if (force && _clipboardActive) {
      clipboardManager.stopMonitoring();
      _clipboardActive = false;
      print('📋 Clipboard monitoring stopped');
    }
  }

  /// Start UDrive server
  Future<bool> startUDriveServer(
      {String? customStoragePath,
      int port = 8080,
      bool enableNetworkAccess = false}) async {
    if (!_udriveActive) {
      final success = await udriveServer.startServer(
          customStoragePath: customStoragePath,
          enableNetworkAccess: enableNetworkAccess);
      if (success) {
        _udriveActive = true;
        print('🌐 UDrive server started on port $port');
      }
      return success;
    }
    return true; // Already running
  }

  /// Stop UDrive server (only if explicitly requested)
  Future<void> stopUDriveServer({bool force = false}) async {
    if (force && _udriveActive) {
      await udriveServer.stopServer();
      _udriveActive = false;
      print('🌐 UDrive server stopped');
    }
  }

  /// Check if clipboard is active
  bool get isClipboardActive => _clipboardActive;

  /// Check if UDrive server is active
  bool get isUDriveActive => _udriveActive;

  /// Get clipboard items
  List<String> get clipboardItems => clipboardManager.copiedItems;

  /// Get UDrive server URL
  String? get udriveServerUrl => udriveServer.serverUrl;

  /// Get UDrive network URL (for local network access)
  String? get udriveNetworkUrl => udriveServer.networkUrl;

  /// Get UDrive server status
  bool get isUDriveRunning => udriveServer.isRunning;

  /// Dispose all services (call only on app exit)
  Future<void> disposeAll() async {
    await stopUDriveServer(force: true);
    stopClipboardMonitoring(force: true);
    print('🔴 All services disposed');
  }

  /// Resume services (useful after app minimize/restore)
  Future<void> resumeServices(Function? clipboardCallback) async {
    if (_clipboardActive && clipboardCallback != null) {
      startClipboardMonitoring(clipboardCallback);
    }
  }
}
