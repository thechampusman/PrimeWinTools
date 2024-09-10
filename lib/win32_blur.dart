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
  accentPolicy.ref.nFlags = 2; // Blur behind the entire window
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
