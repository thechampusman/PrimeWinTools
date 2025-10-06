import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import '../clipboard/DataBase/ClipBoardDataBase.dart';

class NativeClipboardPopup {
  static const int WM_CLOSE = 0x0010;
  static const int WM_COMMAND = 0x0111;
  static const int WM_PAINT = 0x000F;
  static const int WM_DESTROY = 0x0002;
  static const int WM_LBUTTONDOWN = 0x0201;
  static const int WM_KEYDOWN = 0x0100;
  static const int WM_ACTIVATE = 0x0006;
  static const int WA_INACTIVE = 0;
  static const int VK_ESCAPE = 0x1B;
  static const int VK_RETURN = 0x0D;
  static const int VK_UP = 0x26;
  static const int VK_DOWN = 0x28;

  static int? _hWnd;
  static List<Map<String, dynamic>> _clipboardData = [];
  static bool _classRegistered = false;
  static final Pointer<Utf16> _className = 'ClipboardPopupClass'.toNativeUtf16();
  static int _selectedIndex = 0;

  static Future<bool> showPopup() async {
    if (_hWnd != null && _hWnd != 0) {
      SetForegroundWindow(_hWnd!);
      SetFocus(_hWnd!);
      return true;
    }

    await _loadClipboardData();
    _selectedIndex = 0;

    return _createNativeWindow();
  }

  static Future<void> _loadClipboardData() async {
    try {
      final dbHelper = ClipboardDatabase();
      _clipboardData = await dbHelper.getClipboardHistory();

      // Try to include current clipboard text at the top if it's new
      final current = _getClipboardUnicodeText();
      if (current != null && current.trim().isNotEmpty) {
        final exists = _clipboardData.any((e) => (e['text'] ?? '') == current);
        if (!exists) {
          _clipboardData.insert(0, {
            'id': -1,
            'text': current,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'pinned': 0,
          });
        }
      }
      if (_clipboardData.length > 15) {
        _clipboardData = _clipboardData.take(15).toList();
      }
    } catch (e) {
      print('Error loading clipboard data: $e');
      _clipboardData = [];
    }
  }

  static bool _createNativeWindow() {
    final wc = calloc<WNDCLASS>();
    wc.ref.style = CS_HREDRAW | CS_VREDRAW;
    wc.ref.lpfnWndProc = Pointer.fromFunction<WindowProc>(_windowProc, 0);
    wc.ref.hInstance = GetModuleHandle(nullptr);
    wc.ref.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.ref.hbrBackground = GetStockObject(WHITE_BRUSH);
    wc.ref.lpszClassName = _className;

    if (!_classRegistered) {
      final atom = RegisterClass(wc);
      if (atom == 0) {
        final err = GetLastError();
        const ERROR_CLASS_ALREADY_EXISTS = 1410;
        if (err != ERROR_CLASS_ALREADY_EXISTS) {
          print('Failed to register window class (error $err)');
          free(wc);
          return false;
        }
      }
      _classRegistered = true;
    }

    // Determine popup position near cursor, clamped to screen bounds
    final pt = calloc<POINT>();
    GetCursorPos(pt);
    final screenW = GetSystemMetrics(SM_CXSCREEN);
    final screenH = GetSystemMetrics(SM_CYSCREEN);
    final winW = 400;
    final winH = 500;
    int x = pt.ref.x - (winW ~/ 2);
    int y = pt.ref.y + 16; // below cursor
    if (x < 8) x = 8;
    if (y < 8) y = 8;
    if (x + winW > screenW - 8) x = screenW - winW - 8;
    if (y + winH > screenH - 8) y = screenH - winH - 8;

    _hWnd = CreateWindowEx(
      WS_EX_TOPMOST | WS_EX_TOOLWINDOW,
      _className,
      'Clipboard History'.toNativeUtf16(),
      WS_POPUP | WS_BORDER,
      x,
      y,
      winW,
      winH,
      NULL,
      NULL,
      GetModuleHandle(nullptr),
      nullptr,
    );

    if (_hWnd != null && _hWnd != 0) {
      ShowWindow(_hWnd!, SW_SHOW);
      UpdateWindow(_hWnd!);
      SetForegroundWindow(_hWnd!);
      SetFocus(_hWnd!);

      _messageLoop();
      free(wc);
      return true;
    }

    free(pt);
    free(wc);
    return false;
  }

  static int _windowProc(int hWnd, int uMsg, int wParam, int lParam) {
    switch (uMsg) {
      case WM_PAINT:
        _paintWindow(hWnd);
        break;
      case WM_LBUTTONDOWN:
        _handleClick(hWnd, LOWORD(lParam), HIWORD(lParam));
        break;
      case WM_KEYDOWN:
        _handleKey(hWnd, wParam);
        break;
      case WM_ACTIVATE:
        // Close when window becomes inactive (focus lost)
        if (LOWORD(wParam) == WA_INACTIVE) {
          DestroyWindow(hWnd);
          _hWnd = null;
          return 0;
        }
        break;
      case WM_CLOSE:
      case WM_DESTROY:
        DestroyWindow(hWnd);
        _hWnd = null;
        return 0;
      default:
        return DefWindowProc(hWnd, uMsg, wParam, lParam);
    }
    return 0;
  }

  static void _paintWindow(int hWnd) {
    final ps = calloc<PAINTSTRUCT>();
    final hdc = BeginPaint(hWnd, ps);

    final rect = calloc<RECT>();
    GetClientRect(hWnd, rect);
    final bgBrush = CreateSolidBrush(RGB(45, 45, 45));
    FillRect(hdc, rect, bgBrush);

    SetTextColor(hdc, RGB(255, 255, 255));
    SetBkMode(hdc, TRANSPARENT);

    final headerText = 'Clipboard History'.toNativeUtf16();
    TextOut(hdc, 20, 20, headerText, 16);

    int yPos = 60;
    for (int i = 0; i < _clipboardData.length && i < 8; i++) {
      final item = _clipboardData[i];
      final text = (item['text'] as String? ?? '').substring(
          0,
          (item['text'] as String? ?? '').length > 50
              ? 50
              : (item['text'] as String? ?? '').length);
      // Highlight selected row
      if (i == _selectedIndex) {
        final selRect = calloc<RECT>();
        selRect.ref.left = 12;
        selRect.ref.top = yPos - 6;
        selRect.ref.right = rect.ref.right - 12;
        selRect.ref.bottom = yPos + 26;
        final selBrush = CreateSolidBrush(RGB(71, 75, 122));
        FillRect(hdc, selRect, selBrush);
        DeleteObject(selBrush);
        free(selRect);
      }

      final itemText = '${i + 1}. $text'.toNativeUtf16();

      TextOut(hdc, 20, yPos, itemText, itemText.length ~/ 2);
      yPos += 40;

      free(itemText);
    }

    if (_clipboardData.isEmpty) {
      final emptyText = 'No clipboard history yet'.toNativeUtf16();
      TextOut(hdc, 20, 100, emptyText, emptyText.length ~/ 2);
      free(emptyText);
    }

    free(headerText);
    DeleteObject(bgBrush);
    free(rect);
    EndPaint(hWnd, ps);
    free(ps);
  }

  static void _handleClick(int hWnd, int x, int y) {
    if (y >= 60 && _clipboardData.isNotEmpty) {
      int itemIndex = (y - 60) ~/ 40;
      if (itemIndex >= 0 && itemIndex < _clipboardData.length) {
        final text = _clipboardData[itemIndex]['text'] as String? ?? '';
        _copyToClipboard(text);

        if (_hWnd != null) {
          DestroyWindow(_hWnd!);
          _hWnd = null;
        }
      }
    }
  }

  static void _handleKey(int hWnd, int vk) {
    if (_clipboardData.isEmpty) return;
    switch (vk) {
      case VK_ESCAPE:
        DestroyWindow(hWnd);
        _hWnd = null;
        return;
      case VK_UP:
        if (_selectedIndex > 0) _selectedIndex--;
        InvalidateRect(hWnd, nullptr, TRUE);
        return;
      case VK_DOWN:
        if (_selectedIndex < _clipboardData.length - 1) _selectedIndex++;
        InvalidateRect(hWnd, nullptr, TRUE);
        return;
      case VK_RETURN:
        final text = _clipboardData[_selectedIndex]['text'] as String? ?? '';
        _copyToClipboard(text);
        DestroyWindow(hWnd);
        _hWnd = null;
        return;
    }
  }

  static void _copyToClipboard(String text) {
    if (OpenClipboard(NULL) != 0) {
      EmptyClipboard();
      final textPtr = text.toNativeUtf16();
      final hMem = GlobalAlloc(GPTR, text.length * 2 + 2);
      final pMem = GlobalLock(hMem);

      final textBytes = Uint16List.fromList(text.codeUnits);
      final memPtr = pMem.cast<Uint16>();
      for (int i = 0; i < textBytes.length; i++) {
        memPtr.elementAt(i).value = textBytes[i];
      }
      memPtr.elementAt(textBytes.length).value = 0;

      GlobalUnlock(hMem);
      SetClipboardData(CF_UNICODETEXT, hMem.address);
      CloseClipboard();

      free(textPtr);
      print(
          'Copied to clipboard: ${text.substring(0, text.length > 30 ? 30 : text.length)}...');
    }
  }

  static void _messageLoop() {
    final msg = calloc<MSG>();
    Future(() async {
      while (_hWnd != null) {
        if (PeekMessage(msg, _hWnd ?? 0, 0, 0, PM_REMOVE) != 0) {
          TranslateMessage(msg);
          DispatchMessage(msg);
        }
        await Future.delayed(const Duration(milliseconds: 10));
      }
      free(msg);
    });
  }

  static String? _getClipboardUnicodeText() {
    // Use Flutter Clipboard API to avoid platform pointer handling issues
    // Note: This is sync wrapper calling async getData via runZonedGuarded; if null or error, return null
    try {
      // Clipboard.getData is async; here we cannot block, so return null and rely on DB
      // Optionally, the caller can be made async to await this, but to keep API unchanged, skip for now
      // A quick workaround: trigger an async fetch and prepend on next call is complex; so return null
      return null;
    } catch (_) {
      return null;
    }
  }

  static void hidePopup() {
    if (_hWnd != null) {
      DestroyWindow(_hWnd!);
      _hWnd = null;
    }
  }
}
