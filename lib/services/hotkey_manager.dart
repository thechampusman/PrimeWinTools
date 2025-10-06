import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'dart:async';
import 'native_clipboard_popup.dart';

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
    print('🚀 Showing clipboard popup (native) ...');

    try {
  // Always show native popup to avoid bringing app window to front
  final ok = await NativeClipboardPopup.showPopup();
  print(ok ? '✅ Native clipboard popup shown!' : '❌ Failed to show native popup');
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
