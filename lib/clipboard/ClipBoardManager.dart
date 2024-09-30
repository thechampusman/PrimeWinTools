import 'package:win32/win32.dart' as win32;
import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'DataBase/ClipBoardDataBase.dart';

class ClipboardManager {
  List<String> copiedItems = [];

  final ClipboardDatabase dbHelper = ClipboardDatabase();

  // Accept a callback function to update UI in the Dashboard
  void monitorClipboard(Function onClipboardUpdate) {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      final clipboardText = _getClipboardText();
      if (clipboardText != null &&
          clipboardText.isNotEmpty &&
          !copiedItems.contains(clipboardText)) {
        copiedItems.add(clipboardText);

        // Save to the database, avoiding duplicates
        await dbHelper.saveClipboardItem(clipboardText);

        onClipboardUpdate(); // Call the callback to update UI
        print('Copied: $clipboardText');
      }

      // Delete items older than 20 days
      await dbHelper.deleteOldItems();
    });
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
}
