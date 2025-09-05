import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

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
  accentPolicy.ref.nFlags = 0;
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

const int GWL_STYLE = -16;
const int WS_CAPTION = 0x00C00000;
const int SWP_NOSIZE = 0x0001;
const int SWP_NOMOVE = 0x0002;
const int SWP_FRAMECHANGED = 0x0020;
const int HWND_TOPMOST = -1;

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

typedef ShowWindowC = Int32 Function(IntPtr hwnd, Int32 nCmdShow);
typedef ShowWindowDart = int Function(int hwnd, int nCmdShow);

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

  final style = getWindowLong(hwnd, GWL_STYLE);

  setWindowLong(hwnd, GWL_STYLE, style & ~WINDOW_STYLE.WS_SYSMENU);
}
