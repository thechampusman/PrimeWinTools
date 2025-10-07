import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import '../app/navigation_service.dart';
import '../ui/clipboard_overlay.dart';

class GlobalHotKeyManager {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      HotKey winAltV = HotKey(
        key: LogicalKeyboardKey.keyV,
        modifiers: [HotKeyModifier.alt, HotKeyModifier.meta],
        scope: HotKeyScope.system,
      );

      await hotKeyManager.register(
        winAltV,
        keyDownHandler: (hotKey) async {
          print('Win+Alt+V pressed! Opening clipboard popup...');
          await _showClipboardPopup();
        },
      );

      _isInitialized = true;
      print('✅ Global hotkey Win+Alt+V registered successfully!');
    } catch (e) {
      print('❌ Failed to register hotkey: $e');
    }
  }

  static Future<void> _showClipboardPopup() async {
    print('🚀 Toggling Flutter clipboard overlay...');

    try {
      final ok = ClipboardOverlay.show(navigatorKey.currentContext);
      if (ok) {
        print('✅ Clipboard overlay shown!');
      } else {
        print('❌ Failed to show clipboard overlay (no Overlay)');
      }
    } catch (e) {
      print('❌ Error showing clipboard overlay: $e');
    }
  }

  static Future<void> dispose() async {
    try {
      await hotKeyManager.unregisterAll();
      _isInitialized = false;

      print('✅ All hotkeys unregistered');
    } catch (e) {
      print('❌ Failed to unregister hotkeys: $e');
    }
  }
}
