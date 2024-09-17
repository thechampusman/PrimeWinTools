import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

// Constants for the blur effect
const ACCENT_DISABLED = 0;
const ACCENT_ENABLE_GRADIENT = 1;
const ACCENT_ENABLE_BLURBEHIND = 3;
const ACCENT_INVALID_STATE = -1;
const WCA_ACCENT_POLICY = 19;

base class ACCENT_POLICY extends Struct {
  @Int32()
  external int nAccentState;

  @Int32()
  external int nFlags;

  @Int32()
  external int nColor;

  @Int32()
  external int nAnimationId;
}

base class WINDOW_COMPOSITION_ATTRIBUTE_DATA extends Struct {
  @Int32()
  external int Attribute;

  external Pointer<ACCENT_POLICY> pData;

  @Uint32()
  external int SizeOfData;
}

void applyBlurEffect() {
  final hwnd = GetForegroundWindow();
  if (hwnd == 0) {
    print('Window handle not found.');
    return;
  }

  final accentPolicy = calloc<ACCENT_POLICY>();
  accentPolicy.ref.nAccentState = ACCENT_ENABLE_BLURBEHIND;
  accentPolicy.ref.nFlags = 0; // Blur behind the entire window
  accentPolicy.ref.nColor = 0;
  accentPolicy.ref.nAnimationId = 0;

  final wcaData = calloc<WINDOW_COMPOSITION_ATTRIBUTE_DATA>();
  wcaData.ref.Attribute = WCA_ACCENT_POLICY;
  wcaData.ref.pData = accentPolicy;
  wcaData.ref.SizeOfData = sizeOf<ACCENT_POLICY>();

  final user32 = DynamicLibrary.open('user32.dll');
  final setWindowCompositionAttribute = user32.lookupFunction<
          Int32 Function(IntPtr, Pointer<WINDOW_COMPOSITION_ATTRIBUTE_DATA>),
          int Function(int, Pointer<WINDOW_COMPOSITION_ATTRIBUTE_DATA>)>(
      'SetWindowCompositionAttribute');

  final result = setWindowCompositionAttribute(hwnd, wcaData);
  if (result != 1) {
    print('Failed to apply blur effect.');
  }

  calloc.free(accentPolicy);
  calloc.free(wcaData);
}

// Constants
const int GWL_STYLE = -16;
const int WS_CAPTION = 0x00C00000;
const int SWP_NOSIZE = 0x0001;
const int SWP_NOMOVE = 0x0002;
const int SWP_FRAMECHANGED = 0x0020;
const int HWND_TOPMOST = -1;

// Function pointers
typedef GetWindowLongC = IntPtr Function(IntPtr hwnd, Int32 nIndex);
typedef GetWindowLongDart = int Function(int hwnd, int nIndex);

typedef SetWindowLongC = IntPtr Function(
    IntPtr hwnd, Int32 nIndex, Int32 dwNewLong);
typedef SetWindowLongDart = int Function(int hwnd, int nIndex, int dwNewLong);

typedef SetWindowPosC = Int32 Function(IntPtr hwnd, IntPtr hWndInsertAfter,
    Int32 X, Int32 Y, Int32 cx, Int32 cy, Uint32 uFlags);
typedef SetWindowPosDart = int Function(
    int hwnd, int hWndInsertAfter, int X, int Y, int cx, int cy, int uFlags);

void removeDefaultTitleBar() {
  final hwnd = GetForegroundWindow();
  if (hwnd == 0) {
    print('Window handle not found.');
    return;
  }

  final user32 = DynamicLibrary.open('user32.dll');
  final getWindowLong = user32
      .lookupFunction<GetWindowLongC, GetWindowLongDart>('GetWindowLongW');
  final setWindowLong = user32
      .lookupFunction<SetWindowLongC, SetWindowLongDart>('SetWindowLongW');
  final setWindowPos =
      user32.lookupFunction<SetWindowPosC, SetWindowPosDart>('SetWindowPos');

  final style = getWindowLong(hwnd, GWL_STYLE);
  setWindowLong(hwnd, GWL_STYLE, style & ~WS_CAPTION);
  setWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0,
      SWP_NOSIZE | SWP_NOMOVE | SWP_FRAMECHANGED);
}

// Function pointers
typedef ShowWindowC = Int32 Function(IntPtr hwnd, Int32 nCmdShow);
typedef ShowWindowDart = int Function(int hwnd, int nCmdShow);

// const int SW_HIDE = 0;
// const int SW_SHOWNORMAL = 1;
// const int SW_SHOWMINIMIZED = 2;
// const int SW_MAXIMIZE = 3;
// const int SW_RESTORE = 9;

// void minimizeWindow() {
//   final hwnd = GetForegroundWindow();
//   if (hwnd == 0) return;

//   final user32 = DynamicLibrary.open('user32.dll');
//   final showWindow =
//       user32.lookupFunction<ShowWindowC, ShowWindowDart>('ShowWindow');

//   showWindow(hwnd, SW_SHOWMINIMIZED);
// }

// void restoreWindow() {
//   final hwnd = GetForegroundWindow();
//   if (hwnd == 0) return;

//   final user32 = DynamicLibrary.open('user32.dll');
//   final showWindow =
//       user32.lookupFunction<ShowWindowC, ShowWindowDart>('ShowWindow');

//   showWindow(hwnd, SW_RESTORE);
// }

// void maximizeWindow() {
//   final hwnd = GetForegroundWindow();
//   if (hwnd == 0) return;

//   final user32 = DynamicLibrary.open('user32.dll');
//   final showWindow =
//       user32.lookupFunction<ShowWindowC, ShowWindowDart>('ShowWindow');

//   showWindow(hwnd, SW_MAXIMIZE);
// }

// To track the window state
// int _currentWindowState = SW_SHOWNORMAL;

// void toggleMaximizeRestoreWindow() {
//   final hwnd = GetForegroundWindow();
//   if (hwnd == 0) return;

//   final user32 = DynamicLibrary.open('user32.dll');
//   final showWindow =
//       user32.lookupFunction<ShowWindowC, ShowWindowDart>('ShowWindow');

//   if (_currentWindowState == SW_MAXIMIZE) {
//     showWindow(hwnd, SW_RESTORE);
//     _currentWindowState = SW_SHOWNORMAL;
//   } else {
//     showWindow(hwnd, SW_MAXIMIZE);
//     _currentWindowState = SW_MAXIMIZE;
//   }
// }

// typedef SendMessageC = Int32 Function(
//     IntPtr hwnd, Uint32 Msg, IntPtr wParam, IntPtr lParam);
// typedef SendMessageDart = int Function(
//     int hwnd, int Msg, int wParam, int lParam);
// typedef ReleaseCaptureC = Int32 Function();
// typedef ReleaseCaptureDart = int Function();

// // Constants
// const int GWL_EXSTYLE = -20;
// const int WS_EX_TOPMOST = 0x00000008;

// // Function pointers
// typedef GetWindowLongPtrC = IntPtr Function(IntPtr hwnd, Int32 nIndex);
// typedef GetWindowLongPtrDart = int Function(int hwnd, int nIndex);

// typedef SetWindowLongPtrC = IntPtr Function(
//     IntPtr hwnd, Int32 nIndex, IntPtr dwNewLong);
// typedef SetWindowLongPtrDart = int Function(
//     int hwnd, int nIndex, int dwNewLong);

// void setWindowAlwaysOnTop(bool alwaysOnTop) {
//   final hwnd = GetForegroundWindow();
//   if (hwnd == 0) {
//     print('Failed to get window handle.');
//     return;
//   }

//   final user32 = DynamicLibrary.open('user32.dll');
//   final getWindowLongPtr =
//       user32.lookupFunction<GetWindowLongPtrC, GetWindowLongPtrDart>(
//           'GetWindowLongPtrW');
//   final setWindowLongPtr =
//       user32.lookupFunction<SetWindowLongPtrC, SetWindowLongPtrDart>(
//           'SetWindowLongPtrW');

//   final currentStyle = getWindowLongPtr(hwnd, GWL_EXSTYLE);
//   int newStyle;

//   if (alwaysOnTop) {
//     newStyle = currentStyle | WS_EX_TOPMOST;
//   } else {
//     newStyle = currentStyle & ~WS_EX_TOPMOST;
//   }

//   final result = setWindowLongPtr(hwnd, GWL_EXSTYLE, newStyle);
//   if (result == 0) {
//     print('Failed to set window style.');
//   }
// }

void removeFlutterIcon() {
  final hwnd = GetForegroundWindow();
  if (hwnd == 0) {
    print('Window handle not found.');
    return;
  }

  final user32 = DynamicLibrary.open('user32.dll');
  final setWindowLong = user32
      .lookupFunction<SetWindowLongC, SetWindowLongDart>('SetWindowLongW');
  final getWindowLong = user32
      .lookupFunction<GetWindowLongC, GetWindowLongDart>('GetWindowLongW');

  // Get the current window style
  final style = getWindowLong(hwnd, GWL_STYLE);

  // Remove WS_SYSMENU to hide the icon and system buttons
  setWindowLong(hwnd, GWL_STYLE, style & ~WINDOW_STYLE.WS_SYSMENU);

  print('Flutter icon removed.');
}

// void removeWindowButtons() {
//   final hwnd = GetForegroundWindow();
//   if (hwnd == 0) {
//     print('Window handle not found.');
//     return;
//   }

//   final user32 = DynamicLibrary.open('user32.dll');
//   final setWindowLong = user32
//       .lookupFunction<SetWindowLongC, SetWindowLongDart>('SetWindowLongW');
//   final getWindowLong = user32
//       .lookupFunction<GetWindowLongC, GetWindowLongDart>('GetWindowLongW');

//   // Get the current window style
//   final style = getWindowLong(hwnd, GWL_STYLE);

//   // Remove minimize, maximize, and close buttons by removing WS_MINIMIZEBOX and WS_MAXIMIZEBOX flags
//   setWindowLong(hwnd, GWL_STYLE,
//       style & ~WINDOW_STYLE.WS_MINIMIZEBOX & ~WINDOW_STYLE.WS_MAXIMIZEBOX);

//   print('Minimize, Maximize, and Close buttons removed.');
// }
