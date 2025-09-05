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

  static int? _hWnd;
  static List<Map<String, dynamic>> _clipboardData = [];

  static Future<void> showPopup() async {
    await _loadClipboardData();

    _createNativeWindow();
  }

  static Future<void> _loadClipboardData() async {
    try {
      final dbHelper = ClipboardDatabase();
      _clipboardData = await dbHelper.getClipboardHistory();
      _clipboardData = _clipboardData.take(10).toList();
    } catch (e) {
      print('Error loading clipboard data: $e');
      _clipboardData = [];
    }
  }

  static void _createNativeWindow() {
    final className = 'ClipboardPopupClass'.toNativeUtf16();

    final wc = calloc<WNDCLASS>();
    wc.ref.style = CS_HREDRAW | CS_VREDRAW;
    wc.ref.lpfnWndProc = Pointer.fromFunction<WindowProc>(_windowProc, 0);
    wc.ref.hInstance = GetModuleHandle(nullptr);
    wc.ref.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.ref.hbrBackground = GetStockObject(WHITE_BRUSH);
    wc.ref.lpszClassName = className;

    if (RegisterClass(wc) == 0) {
      print('Failed to register window class');
      return;
    }

    _hWnd = CreateWindowEx(
      WS_EX_TOPMOST | WS_EX_TOOLWINDOW,
      className,
      'Clipboard History'.toNativeUtf16(),
      WS_POPUP | WS_BORDER,
      100,
      100,
      400,
      500,
      NULL,
      NULL,
      GetModuleHandle(nullptr),
      nullptr,
    );

    if (_hWnd != null && _hWnd != 0) {
      ShowWindow(_hWnd!, SW_SHOW);
      UpdateWindow(_hWnd!);
      SetForegroundWindow(_hWnd!);

      _messageLoop();
    }

    free(className);
    free(wc);
  }

  static int _windowProc(int hWnd, int uMsg, int wParam, int lParam) {
    switch (uMsg) {
      case WM_PAINT:
        _paintWindow(hWnd);
        break;
      case WM_LBUTTONDOWN:
        _handleClick(hWnd, LOWORD(lParam), HIWORD(lParam));
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
    final hBrush = CreateSolidBrush(RGB(45, 45, 45));
    FillRect(hdc, rect, hBrush);

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
    DeleteObject(hBrush);
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

    Future.delayed(Duration.zero, () async {
      for (int i = 0; i < 1000 && _hWnd != null; i++) {
        if (PeekMessage(msg, _hWnd ?? 0, 0, 0, PM_REMOVE) != 0) {
          TranslateMessage(msg);
          DispatchMessage(msg);
        }
        await Future.delayed(const Duration(milliseconds: 10));
      }
    });

    free(msg);
  }

  static void hidePopup() {
    if (_hWnd != null) {
      DestroyWindow(_hWnd!);
      _hWnd = null;
    }
  }
}
