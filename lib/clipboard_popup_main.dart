import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'clipboard/clipboard_popup.dart';
import 'clipboard/DataBase/ClipBoardDataBase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Configure window for popup
  if (Platform.isWindows) {
    WindowOptions windowOptions = const WindowOptions(
      size: Size(400, 500),
      center: false,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      alwaysOnTop: true,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      // Position the popup near the center-right of screen
      await windowManager.setPosition(const Offset(200, 200));
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialize clipboard database
  final clipboardDb = ClipboardDatabase();
  await clipboardDb.database;

  runApp(const ClipboardPopupApp());
}

class ClipboardPopupApp extends StatelessWidget {
  const ClipboardPopupApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const ClipboardPopup(),
    );
  }
}
