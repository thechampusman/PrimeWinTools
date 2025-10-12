import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import '../clipboard/DataBase/ClipBoardDataBase.dart';

// FFI typedefs and structs (top-level)
typedef _SetWCA_FFI = Int32 Function(
  IntPtr, // HWND
  Pointer<WINDOWCOMPOSITIONATTRIBDATA>,
);
typedef _SetWCA = int Function(
  int, // HWND
  Pointer<WINDOWCOMPOSITIONATTRIBDATA>,
);

final class ACCENT_POLICY extends Struct {
  @Int32()
  external int AccentState;

  @Int32()
  external int AccentFlags;

  @Uint32()
  external int GradientColor; // ARGB

  @Int32()
  external int AnimationId;
}

final class WINDOWCOMPOSITIONATTRIBDATA extends Struct {
  @Int32()
  external int Attrib;

  external Pointer<Void> pvData;

  @IntPtr()
  external int cbData;
}

final DynamicLibrary _user32 = DynamicLibrary.open('user32.dll');
final _SetWCA _setWindowCompositionAttribute =
    _user32.lookupFunction<_SetWCA_FFI, _SetWCA>('SetWindowCompositionAttribute');

class NativeClipboardPopup {
  // Win32 constants we use
  static const int WM_CLOSE = 0x0010;
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

  // Acrylic/Composition constants
  static const int WCA_ACCENT_POLICY = 19;
  static const int ACCENT_ENABLE_ACRYLICBLURBEHIND = 4;
  static const int ACCENT_ENABLE_BLURBEHIND = 3;
  static const int DWMWA_USE_IMMERSIVE_DARK_MODE = 20; // may be 19 on old builds
  static const int DWMWA_WINDOW_CORNER_PREFERENCE = 33;
  static const int DWMWCP_ROUND = 2;

  static int? _hWnd;
  static bool _classRegistered = false;
  static final Pointer<Utf16> _className = 'ClipboardPopupClass'.toNativeUtf16();

  static List<Map<String, dynamic>> _clipboardData = [];
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
      final db = ClipboardDatabase();
      _clipboardData = await db.getClipboardHistory();
      if (_clipboardData.length > 15) {
        _clipboardData = _clipboardData.take(15).toList();
      }
    } catch (e) {
      // Fallback to empty list on error
      _clipboardData = [];
      // ignore: avoid_print
      print('Error loading clipboard data: $e');
    }
  }

  static bool _createNativeWindow() {
    final wc = calloc<WNDCLASS>();
    wc.ref.style = CS_HREDRAW | CS_VREDRAW;
    wc.ref.lpfnWndProc = Pointer.fromFunction<WindowProc>(_windowProc, 0);
    wc.ref.hInstance = GetModuleHandle(nullptr);
    wc.ref.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.ref.hbrBackground = GetStockObject(NULL_BRUSH); // let acrylic show
    wc.ref.lpszClassName = _className;

    if (!_classRegistered) {
      final atom = RegisterClass(wc);
      if (atom == 0) {
        final err = GetLastError();
        const ERROR_CLASS_ALREADY_EXISTS = 1410;
        if (err != ERROR_CLASS_ALREADY_EXISTS) {
          // ignore: avoid_print
          print('Failed to register window class: $err');
          free(wc);
          return false;
        }
      }
      _classRegistered = true;
    }

    // Position near cursor
    final pt = calloc<POINT>();
    GetCursorPos(pt);
    final screenW = GetSystemMetrics(SM_CXSCREEN);
    final screenH = GetSystemMetrics(SM_CYSCREEN);
    final winW = 400;
    final winH = 500;

    int x = pt.ref.x - (winW ~/ 2);
    int y = pt.ref.y + 16;
    if (x < 8) x = 8;
    if (y < 8) y = 8;
    if (x + winW > screenW - 8) x = screenW - winW - 8;
    if (y + winH > screenH - 8) y = screenH - winH - 8;
    free(pt);

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

    if (_hWnd == null || _hWnd == 0) {
      free(wc);
      return false;
    }

    // Rounded corners and dark mode (best-effort)
    _trySetDwmAttributeInt(_hWnd!, DWMWA_WINDOW_CORNER_PREFERENCE, DWMWCP_ROUND);
    _trySetDwmAttributeBool(_hWnd!, DWMWA_USE_IMMERSIVE_DARK_MODE, true);

    // Apply acrylic blur
    _enableAcrylic(_hWnd!);

  // On Windows 11, corners are rounded via DWM attribute; skip manual region on older systems

    ShowWindow(_hWnd!, SW_SHOW);
    UpdateWindow(_hWnd!);
    SetForegroundWindow(_hWnd!);
    SetFocus(_hWnd!);

    _messageLoop();

    free(wc);
    return true;
  }

  static int _windowProc(int hWnd, int uMsg, int wParam, int lParam) {
    switch (uMsg) {
      case WM_PAINT:
        _paintWindow(hWnd);
        return 0;
      case WM_LBUTTONDOWN:
        _handleClick(hWnd, LOWORD(lParam), HIWORD(lParam));
        return 0;
      case WM_KEYDOWN:
        _handleKey(hWnd, wParam);
        return 0;
      case WM_ACTIVATE:
        if (LOWORD(wParam) == WA_INACTIVE) {
          DestroyWindow(hWnd);
          _hWnd = null;
          return 0;
        }
        return 0;
      case WM_CLOSE:
      case WM_DESTROY:
        DestroyWindow(hWnd);
        _hWnd = null;
        return 0;
    }
    return DefWindowProc(hWnd, uMsg, wParam, lParam);
  }

  static void _paintWindow(int hWnd) {
    final ps = calloc<PAINTSTRUCT>();
    final hdc = BeginPaint(hWnd, ps);

    final rect = calloc<RECT>();
    GetClientRect(hWnd, rect);

    // Header background
    final headerRect = calloc<RECT>();
    headerRect.ref.left = rect.ref.left;
    headerRect.ref.top = rect.ref.top;
    headerRect.ref.right = rect.ref.right;
    headerRect.ref.bottom = rect.ref.top + 48;
    final headerBrush = CreateSolidBrush(RGB(60, 62, 110));
    FillRect(hdc, headerRect, headerBrush);

    SetTextColor(hdc, RGB(255, 255, 255));
    SetBkMode(hdc, TRANSPARENT);

    final headerText = 'Clipboard History'.toNativeUtf16();
    TextOut(hdc, 20, 16, headerText, 16);
    free(headerText);

    int yPos = 60;
    for (var i = 0; i < _clipboardData.length && i < 8; i++) {
      final item = _clipboardData[i];
      final full = (item['text'] as String? ?? '');
      final preview = full.length > 50 ? full.substring(0, 50) : full;

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

      final itemText = '${i + 1}. $preview'.toNativeUtf16();
      TextOut(hdc, 20, yPos, itemText, itemText.length ~/ 2);
      free(itemText);

      yPos += 40;
    }

    if (_clipboardData.isEmpty) {
      final emptyText = 'No clipboard history yet'.toNativeUtf16();
      TextOut(hdc, 20, 100, emptyText, emptyText.length ~/ 2);
      free(emptyText);
    }

    DeleteObject(headerBrush);
    free(headerRect);
    free(rect);
    EndPaint(hWnd, ps);
    free(ps);
  }

  static void _handleClick(int hWnd, int x, int y) {
    if (y >= 60 && _clipboardData.isNotEmpty) {
      final idx = (y - 60) ~/ 40;
      if (idx >= 0 && idx < _clipboardData.length) {
        final text = _clipboardData[idx]['text'] as String? ?? '';
        _copyToClipboard(text);
        DestroyWindow(hWnd);
        _hWnd = null;
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
    if (OpenClipboard(NULL) == 0) return;
    EmptyClipboard();

    const GMEM_MOVEABLE = 0x0002;
    final units = Uint16List.fromList(text.codeUnits);
    final hMem = GlobalAlloc(GMEM_MOVEABLE, (units.length + 1) * 2);
    final pMem = GlobalLock(hMem).cast<Uint16>();
    for (var i = 0; i < units.length; i++) {
      pMem.elementAt(i).value = units[i];
    }
    pMem.elementAt(units.length).value = 0;
    GlobalUnlock(hMem);

  SetClipboardData(CF_UNICODETEXT, hMem.address);
    CloseClipboard();
  }

  static void _messageLoop() {
    final msg = calloc<MSG>();
    Future(() async {
      while (_hWnd != null) {
        if (PeekMessage(msg, 0, 0, 0, PM_REMOVE) != 0) {
          TranslateMessage(msg);
          DispatchMessage(msg);
        }
        await Future.delayed(const Duration(milliseconds: 10));
      }
      free(msg);
    });
  }

  static void _enableAcrylic(int hWnd) {
    final accent = calloc<ACCENT_POLICY>();
    accent.ref.AccentState = ACCENT_ENABLE_ACRYLICBLURBEHIND;
    accent.ref.AccentFlags = 2; // optional noise/host backdrop
    accent.ref.GradientColor = 0xCC2D2D2D; // ARGB
    accent.ref.AnimationId = 0;

    final data = calloc<WINDOWCOMPOSITIONATTRIBDATA>();
    data.ref.Attrib = WCA_ACCENT_POLICY;
    data.ref.pvData = accent.cast<Void>();
    data.ref.cbData = sizeOf<ACCENT_POLICY>();

    try {
      _setWindowCompositionAttribute(hWnd, data);
    } catch (_) {
      try {
        accent.ref.AccentState = ACCENT_ENABLE_BLURBEHIND;
        _setWindowCompositionAttribute(hWnd, data);
      } catch (_) {}
    }

    free(data);
    free(accent);
  }

  static void _trySetDwmAttributeBool(int hWnd, int attr, bool value) {
    final pv = calloc<Int32>();
    pv.value = value ? 1 : 0;
    try {
      DwmSetWindowAttribute(hWnd, attr, pv.cast<Void>(), sizeOf<Int32>());
    } catch (_) {
      try {
        DwmSetWindowAttribute(hWnd, attr - 1, pv.cast<Void>(), sizeOf<Int32>());
      } catch (_) {}
    }
    free(pv);
  }

  static void _trySetDwmAttributeInt(int hWnd, int attr, int value) {
    final pv = calloc<Int32>();
    pv.value = value;
    try {
      DwmSetWindowAttribute(hWnd, attr, pv.cast<Void>(), sizeOf<Int32>());
    } catch (_) {}
    free(pv);
  }

  static void hidePopup() {
    if (_hWnd != null) {
      DestroyWindow(_hWnd!);
      _hWnd = null;
    }
  }
}
 
