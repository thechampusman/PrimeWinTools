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

  void monitorClipboard(Function onClipboardUpdate) {
    _monitorTimer?.cancel();
    _cleanupTimer?.cancel();

    _monitorTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      final clipboardText = _getClipboardText();

      if (clipboardText != null &&
          clipboardText.isNotEmpty &&
          clipboardText != _lastClipboardContent &&
          !copiedItems.contains(clipboardText)) {
        _lastClipboardContent = clipboardText;
        copiedItems.add(clipboardText);

        await dbHelper.saveClipboardItem(clipboardText);

        onClipboardUpdate();
      }
    });

    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await dbHelper.deleteOldItems();
    });
  }

  void stopMonitoring() {
    _monitorTimer?.cancel();
    _cleanupTimer?.cancel();
  }

  void resumeMonitoring(Function onClipboardUpdate) {
    if (_monitorTimer == null || !_monitorTimer!.isActive) {
      monitorClipboard(onClipboardUpdate);
    }
  }

  String? _getClipboardText() {
    String? result;
    try {
      if (win32.OpenClipboard(0) != 0) {
        final handle =
            win32.GetClipboardData(win32.CLIPBOARD_FORMAT.CF_UNICODETEXT);
        if (handle != 0) {
          final pointer = win32.GlobalLock(Pointer.fromAddress(handle));
          if (pointer != nullptr) {
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
      win32.CloseClipboard();
    }
    return result;
  }

  void deleteCopiedItem(String item) {
    copiedItems.remove(item);
  }

  void dispose() {
    _monitorTimer?.cancel();
    _cleanupTimer?.cancel();
  }

  String? getCurrentClipboardContent() {
    return _getClipboardText();
  }
}
