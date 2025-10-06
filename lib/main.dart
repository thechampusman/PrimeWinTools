import 'dart:io';

import 'package:PrimeWinTool/ui/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'clipboard/DataBase/ClipBoardDataBase.dart';
import 'app/navigation_service.dart';
import 'services/hotkey_manager.dart';
import 'services/app_service_manager.dart';
import 'ui/clipboard_overlay.dart';

// navigatorKey moved to app/navigation_service.dart to be shared across services

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  if (Platform.isWindows) {
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      minimumSize: Size(1000, 700),
      maximumSize: Size(2560, 1440),
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  removeWindowTitle();
  final clipboardDb = ClipboardDatabase();
  await clipboardDb.database;

  await GlobalHotKeyManager.initialize();

  runApp(const MyApp());
  trayManager.setIcon('assets/app_icon.ico');
  trayManager.setToolTip('PrimeWinTools - Clipboard Manager');
  trayManager.setContextMenu(Menu(items: [
    MenuItem(
      key: 'show',
      label: 'Show PrimeWinTools',
    ),
    MenuItem.separator(),
    MenuItem(
      key: 'clipboard',
      label: 'Open Clipboard History',
    ),
    MenuItem.separator(),
    MenuItem(
      key: 'exit',
      label: 'Exit',
    ),
  ]));

  trayManager.addListener(MyTrayListener());
}

void removeWindowTitle() async {
  await windowManager.setTitle('PrimeWinTool');
}

class MyTrayListener with TrayListener {
  @override
  void onTrayIconMouseDown() {
    _showAndFocusWindow();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show') {
      _showAndFocusWindow();
    } else if (menuItem.key == 'clipboard') {
      _showAndFocusWindow();
      // Attempt to show clipboard overlay after focusing the app
      Future.delayed(const Duration(milliseconds: 120), () {
        final ctx = navigatorKey.currentContext;
        ClipboardOverlay.show(ctx);
      });
    } else if (menuItem.key == 'exit') {
      await AppServiceManager().disposeAll();
      windowManager.destroy();
    }
  }

  void _showAndFocusWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Future<bool> onWindowClose() async {
    await windowManager.hide();
    return false;
  }

  @override
  Future<bool> onWindowMinimize() async {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'PrimeWinTool',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        backgroundColor: Colors.transparent,
        body: Dashboard(),
      ),
    );
  }
}
