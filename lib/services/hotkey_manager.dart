import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'native_clipboard_popup.dart';

class GlobalHotKeyManager {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register Win+Alt+V hotkey
      HotKey winAltV = HotKey(
        key: LogicalKeyboardKey.keyV,
        modifiers: [
          HotKeyModifier.alt,
          HotKeyModifier.meta
        ], // meta = Windows key
        scope: HotKeyScope.system, // Global hotkey
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
    print('🚀 Showing native clipboard popup...');

    try {
      await NativeClipboardPopup.showPopup();
      print('✅ Native clipboard popup shown!');
    } catch (e) {
      print('❌ Error showing native popup: $e');
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
