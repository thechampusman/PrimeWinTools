import 'package:win32/win32.dart' as win32;
import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'DataBase/ClipBoardDataBase.dart';

class ClipboardManager {
  List<String> copiedItems = [];
  Timer? _monitorTimer;
  Timer? _cleanupTimer;
  String? _lastClipboardContent;
  
  final ClipboardDatabase dbHelper = ClipboardDatabase();

  // Enhanced background monitoring with optimized polling
  void monitorClipboard(Function onClipboardUpdate) {
    // Stop any existing timers
    _monitorTimer?.cancel();
    _cleanupTimer?.cancel();
    
    // Start monitoring with more efficient approach
    _monitorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      final clipboardText = _getClipboardText();
      
      // Only process if clipboard content has actually changed
      if (clipboardText != null &&
          clipboardText.isNotEmpty &&
          clipboardText != _lastClipboardContent &&
          !copiedItems.contains(clipboardText)) {
        
        _lastClipboardContent = clipboardText;
        copiedItems.add(clipboardText);

        // Save to the database, avoiding duplicates
        await dbHelper.saveClipboardItem(clipboardText);

        onClipboardUpdate(); // Call the callback to update UI
        print('New clipboard content captured: ${clipboardText.substring(0, clipboardText.length > 50 ? 50 : clipboardText.length)}...');
      }
    });
    
    // Clean up old items every 5 minutes instead of every second (single timer)
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await dbHelper.deleteOldItems();
    });
  }
  // Stop monitoring when app is minimized/hidden
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _cleanupTimer?.cancel();
    print('Clipboard monitoring paused');
  }

  // Resume monitoring when app is shown
  void resumeMonitoring(Function onClipboardUpdate) {
    if (_monitorTimer == null || !_monitorTimer!.isActive) {
      monitorClipboard(onClipboardUpdate);
      print('Clipboard monitoring resumed');
    }
  }

  // Method to get text from clipboard
  String? _getClipboardText() {
    String? result;
    try {
      if (win32.OpenClipboard(0) != 0) {
        // Ensure OpenClipboard returns success
        final handle =
            win32.GetClipboardData(win32.CLIPBOARD_FORMAT.CF_UNICODETEXT);
        if (handle != 0) {
          // Lock the handle and retrieve the text
          final pointer = win32.GlobalLock(Pointer.fromAddress(handle));
          if (pointer != nullptr) {
            // Convert the pointer to a Dart string
            result = pointer.cast<Utf16>().toDartString();
            win32.GlobalUnlock(Pointer.fromAddress(handle));
          }
        } else {
          print('No text data in clipboard or unsupported data type.');
        }
      } else {
        print('Failed to open clipboard. Error: ${win32.GetLastError()}');
      }
    } catch (e) {
      print('Error accessing clipboard: $e');
    } finally {
      win32.CloseClipboard(); // Always close the clipboard in a finally block
    }
    return result;
  }

  void deleteCopiedItem(String item) {
    copiedItems.remove(item);
    print('Deleted: $item');
  }
  // Clean up resources when app is closed
  void dispose() {
    _monitorTimer?.cancel();
    _cleanupTimer?.cancel();
    print('ClipboardManager disposed');
  }

  // Get current clipboard content for immediate access
  String? getCurrentClipboardContent() {
    return _getClipboardText();
  }
}
